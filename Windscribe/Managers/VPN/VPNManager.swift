//
//  VPNManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-28.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import NetworkExtension
#if canImport(WidgetKit)
import WidgetKit
#endif
import Swinject
import RxSwift

class VPNManager {

    static let shared = VPNManager(withStatusObserver: true)
    weak var delegate: VPNManagerDelegate?
    let disposeBag = DisposeBag()
    lazy var wgCrendentials: WgCredentials = {
        return Assembler.resolve(WgCredentials.self)
    }()
    lazy var wgRepository: WireguardConfigRepository = {
        return Assembler.resolve(WireguardConfigRepository.self)
    }()
    lazy var api: APIManager = {
        return Assembler.resolve(APIManager.self)
    }()
    lazy var logger: FileLogger = {
        return Assembler.resolve(FileLogger.self)
    }()
    lazy var localDB: LocalDatabase = {
        return Assembler.resolve(LocalDatabase.self)
    }()
    lazy var serverRepository: ServerRepository = {
        return Assembler.resolve(ServerRepository.self)
    }()
    lazy var staticIpRepository: StaticIpRepository = {
        return Assembler.resolve(StaticIpRepository.self)
    }()
    lazy var preferences: Preferences = {
        return Assembler.resolve(Preferences.self)
    }()
    lazy var connectivity: Connectivity = {
        return Assembler.resolve(Connectivity.self)
    }()
    lazy var sessionManager: SessionManagerV2 = {
        return Assembler.resolve(SessionManagerV2.self)
    }()
    var selectedNode: SelectedNode? {
        didSet {
            delegate?.selectedNodeChanged()
        }
    }
    lazy var credentialsRepository: CredentialsRepository = {
        return Assembler.resolve(CredentialsRepository.self)
    }()
    var vpnInfo = BehaviorSubject<VPNConnectionInfo?>(value: nil)
    var selectedFirewallMode: Bool = true
    var selectedConnectionMode: String?

    var uniqueConnectionId = ""
    var lastConnectionStatus: NEVPNStatus = .disconnected

    var isActive: Bool {
        return OpenVPNManager.shared.isConfigured() || WireGuardVPNManager.shared.isConfigured() || IKEv2VPNManager.shared.isConfigured()
    }

    var restartOnDisconnect: Bool = false
    var retryWithNewCredentials: Bool = false
    var retryInProgress: Bool = false
    var keepConnectingState: Bool = false
    var triedToConnect: Bool = false
    var disableOrFailOnDisconnect: Bool = false
    var retryTimer: Timer?
    var connectingTimer: Timer?
    var disconnectingTimer: Timer?
    var contentIntentTimer: Timer?
    var connectivityTestTimer: Timer?
    var failCountTimer: Timer?
    var disconnectCounter: Int = 0
    var switchingLocation = false

    var ipAddressBeforeConnection: String = ""
    var userTappedToDisconnect: Bool = false
    var isFromProtocolFailover: Bool = false
    var isFromProtocolChange: Bool = false
    var successfullProtocolChange: Bool = false
    var connectIntent: Bool = false
    var isOnDemandRetry: Bool = false

    // siri shortcut and today extension intents
    var connectWhenReady = false
    var disconnectWhenReady = false

    var displayingAskToRetryPopup: UIAlertController?

    var untrustedOneTimeOnlySSID: String = ""

    init(withStatusObserver: Bool = false) {
        if withStatusObserver {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(self.connectionStatusChanged(_:)),
                                                   name: NSNotification.Name.NEVPNStatusDidChange,
                                                   object: nil)
        }
        preferences.getFirewallMode().subscribe { data in
            self.selectedFirewallMode = data ?? DefaultValues.firewallMode
        }.disposed(by: disposeBag)
        preferences.getConnectionMode().subscribe { data in
            if data == nil {
                self.selectedConnectionMode = DefaultValues.connectionMode
            } else {
                self.selectedConnectionMode = data
            }
        }.disposed(by: disposeBag)
    }

    func resetProperties() {
        self.retryWithNewCredentials = false
        self.restartOnDisconnect = false
        self.keepConnectingState = false
        self.disableOrFailOnDisconnect = false
        retryTimer?.invalidate()
        connectingTimer?.invalidate()
        disconnectingTimer?.invalidate()
        contentIntentTimer?.invalidate()
        connectivityTestTimer?.invalidate()
        failCountTimer?.invalidate()
    }

    func getStatus() -> Observable<NEVPNStatus> {
        return vpnInfo.debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .filter { $0 != nil }
            .map { $0!.status }
            .distinctUntilChanged()
    }

    func setup(completion: @escaping() -> Void) {
        OpenVPNManager.shared.setup {
            WireGuardVPNManager.shared.setup {
               completion()
            }
        }
    }

    func removeAllVPNProfiles() {
        IKEv2VPNManager.shared.neVPNManager.removeFromPreferences { _ in }
        OpenVPNManager.shared.providerManager?.removeFromPreferences { _ in }
        WireGuardVPNManager.shared.providerManager?.removeFromPreferences { _ in }
    }

    func getOnDemandRules() -> [NEOnDemandRule] {
        var onDemandRules: [NEOnDemandRule] = []
        if let networks = localDB.getNetworksSync() {
            networks.filter { $0.status == true }.forEach { network in
                if network.SSID == TextsAsset.cellular && network.SSID != VPNManager.shared.untrustedOneTimeOnlySSID {
                    let ruleDisconnect = NEOnDemandRuleDisconnect()
                    #if os(iOS)
                    ruleDisconnect.interfaceTypeMatch = .cellular
                    #endif
                    onDemandRules.append(ruleDisconnect)
                    logger.logD(VPNManager.self, "Added On demand disconnect rule for cellular network.")
                }
            }
            let unsecureWifiNetworks = networks.filter { $0.status == true && $0.SSID != TextsAsset.cellular && $0.SSID != VPNManager.shared.untrustedOneTimeOnlySSID }.map {$0.SSID}.sorted()
            if unsecureWifiNetworks.count > 0 {
                let ruleDisconnect = NEOnDemandRuleDisconnect()
                ruleDisconnect.ssidMatch = unsecureWifiNetworks
                onDemandRules.append(ruleDisconnect)
                logger.logD(VPNManager.self, "Added On demand disconnect rule for Wi-fi networks. \(unsecureWifiNetworks.joined(separator: "-").description)")
            }
        }
        let ruleConnect = NEOnDemandRuleConnect()
        onDemandRules.append(ruleConnect)
        return onDemandRules
    }

    func setOnDemandModes() {
        if IKEv2VPNManager.shared.isConfigured() {
            IKEv2VPNManager.shared.setOnDemandMode()
        } else if OpenVPNManager.shared.isConfigured() {
            OpenVPNManager.shared.setOnDemandMode()
        } else if WireGuardVPNManager.shared.isConfigured() {
            WireGuardVPNManager.shared.setOnDemandMode()
        }
    }

    func setKillSwitchMode() {
        if IKEv2VPNManager.shared.isConfigured() {
            IKEv2VPNManager.shared.setKillSwitchMode()
        } else if OpenVPNManager.shared.isConfigured() {
            OpenVPNManager.shared.setKillSwitchMode()
        } else if WireGuardVPNManager.shared.isConfigured() {
            WireGuardVPNManager.shared.setKillSwitchMode()
        }
    }

    func setAllowLanMode() {
        if IKEv2VPNManager.shared.isConfigured() {
            IKEv2VPNManager.shared.setAllowLanMode()
        } else if OpenVPNManager.shared.isConfigured() {
            OpenVPNManager.shared.setAllowLanMode()
        } else if WireGuardVPNManager.shared.isConfigured() {
            WireGuardVPNManager.shared.setAllowLanMode()
        }
    }

    func updateOnDemandRules() {
        VPNManager.shared.isOnDemandRetry = false
        IKEv2VPNManager.shared.updateOnDemandRules()
        OpenVPNManager.shared.updateOnDemandRules()
        WireGuardVPNManager.shared.updateOnDemandRules()
    }

    private func onCredentialsUpdated(isIKEv2: Bool) {
        delay(3) {
            if isIKEv2 {
                self.logger.logD(VPNManager.self, "Restarting ikev2 connection.")
                self.restartIKEv2Connection()
            } else {
                self.logger.logD(VPNManager.self, "Restarting OpenVPN connection.")

                self.restartOpenVPNConnection()
            }
        }
    }

    private func onFailToGetCredentials(error: String?) -> Bool {
        if error != nil {
            self.logger.logE(VPNManager.self, "Failed to load vpn credentials.")
            DispatchQueue.main.async {
                self.delegate?.setDisconnected()
            }
        }
        return error != nil
    }

    func setTimeoutForDisconnectingState() {
        disconnectingTimer?.invalidate()
        disconnectingTimer = Timer.scheduledTimer(timeInterval: 30, target: self, selector: #selector(removeVPNProfileIfStillDisconnecting), userInfo: nil, repeats: false)
    }

    func runConnectivityTest(retry: Bool = true,
                             connectToAnotherNode: Bool = false,
                             checkForIPAddressChange: Bool = true) {
        getVPNConnectionInfo { [self] info in
            if info?.status != .connected {
                return
            }
            logger.logD(self, "[\(VPNManager.shared.uniqueConnectionId)] Running connectivity Test")
            api.getIp().observe(on: MainScheduler.asyncInstance).subscribe( onSuccess: { myIp in
                self.executeForConnectivityTestSuccessful(ipAddress: myIp.userIp, checkForIPAddressChange: checkForIPAddressChange)
            },onFailure: { _ in
                if retry {
                    self.logger.logD(self, "[\(VPNManager.shared.uniqueConnectionId)] Retrying connectivity test.")
                    self.connectivityTestTimer = Timer.scheduledTimer(timeInterval: 3.0,
                                                                      target: self,
                                                                      selector: #selector(self.runConnectivityTestWithNoRetry),
                                                                      userInfo: nil,
                                                                      repeats: false)
                } else if connectToAnotherNode {
                    self.logger.logD(self, "[\(VPNManager.shared.uniqueConnectionId)] Retrying connectivity test with different node.")
                    self.connectToAnotherNode()
                } else {
                    self.logger.logD(self, "Connectivity failed.")
                    VPNManager.shared.isOnDemandRetry = false
                    self.disconnectOrFail()
                }
            }).disposed(by: disposeBag)
        }
    }

    func executeForConnectivityTestSuccessful(ipAddress: String,
                                              checkForIPAddressChange: Bool = true) {
        self.logger.logE(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Connectivity Test successful.")

        AutomaticMode.shared.resetFailCounts()
        ConnectionManager.shared.goodProtocol = ConnectionManager.shared.getNextProtocol()
        self.delegate?.displaySetPrefferedProtocol()
        ConnectionManager.shared.onConnectStateChange(state: NEVPNStatus.connected)
        DispatchQueue.main.async {
            if self.isConnected() {
                VPNManager.shared.isOnDemandRetry = false
                self.preferences.saveConnectionCount(count: ((self.preferences.getConnectionCount() ?? 0) + 1))
                self.delegate?.setConnected(ipAddress: ipAddress)
                self.resetProperties()
                VPNManager.shared.connectIntent = true
                if self.selectedFirewallMode == true {
                    VPNManager.shared.isOnDemandRetry = true
                }
            }
        }
    }

    private let activeManagerKey = "activeManager"
    var lastVPNState = NEVPNStatus.invalid

    // Replace below with SharedUserDefaults
    var activeVPNManager: VPNManagerType {
        get {
            VPNManagerType(rawValue: preferences.getActiveManagerKey() ?? "") ?? VPNManagerType.wg
        }
        set(value) {
            if value != activeVPNManager {
                self.logger.logE(VPNManager.self, "Active VPN Manager changed to \(value)")
                preferences.saveActiveManagerKey(key: value.rawValue)
                UserDefaults.standard.setValue(value.rawValue, forKey: activeManagerKey)
            }
        }
    }

    private func loadIKEV2Manager(completion: @escaping () -> Void) {
        IKEv2VPNManager.shared.neVPNManager.loadFromPreferences { _ in
            completion()
        }
    }

    private func loadOpenVPNManager(completion: @escaping () -> Void) {
        if OpenVPNManager.shared.isConfigured() {
            OpenVPNManager.shared.providerManager?.loadFromPreferences { _ in
                completion()
            }
        } else {
            completion()
        }
    }

    private func loadWgManager(completion: @escaping () -> Void) {
        if WireGuardVPNManager.shared.isConfigured() {
            WireGuardVPNManager.shared.providerManager?.loadFromPreferences { _ in
                completion()
            }
        } else {
            completion()
        }
    }

    private func loadManagers(completion: @escaping () -> Void) {
        loadIKEV2Manager {
            self.loadWgManager {
                self.loadOpenVPNManager {
                    completion()
                }
            }
        }
    }

    /**
     Parses updated VPN connection info from configured VPN managers.
     */
    func getVPNConnectionInfo(completion: @escaping (VPNConnectionInfo?) -> Void) {
        // Refresh and load all VPN Managers from system preferrances.
        loadManagers { [self] in
            let ikev2ManagerStatus = IKEv2VPNManager.shared.neVPNManager.connection.status
            let openVPNManagerStatus = OpenVPNManager.shared.providerManager?.connection.status ?? .invalid
            let wireguardManagerStatus = WireGuardVPNManager.shared.providerManager?.connection.status ?? .invalid
            // Get VPN connection info from manager with priority state if multiple exists.
            let priorityStates = [NEVPNStatus.connecting, NEVPNStatus.connected, NEVPNStatus.disconnecting]
            if priorityStates.contains(ikev2ManagerStatus) {
                completion(VPNManagerType.iKEV2.getVPNConnectionInfo())
                return
            }
            if priorityStates.contains(wireguardManagerStatus) {
                completion(VPNManagerType.wg.getVPNConnectionInfo())
                return
            }
            if priorityStates.contains(openVPNManagerStatus) {
                completion(VPNManagerType.openVPN.getVPNConnectionInfo())
                return
            }
            if priorityStates.contains(ikev2ManagerStatus) {
                completion(VPNManagerType.iKEV2.getVPNConnectionInfo())
                return
            }
            // No VPN Manager is configured
            if ikev2ManagerStatus == .invalid && wireguardManagerStatus == .invalid && openVPNManagerStatus == .invalid {
                completion(nil)
                return
            }
            // Get VPN connection info from last active manager.
            switch activeVPNManager {
            case .iKEV2:
                completion(VPNManagerType.iKEV2.getVPNConnectionInfo())
                return
            case .wg:
                completion(VPNManagerType.wg.getVPNConnectionInfo())
                return
            case .openVPN:
                completion(VPNManagerType.openVPN.getVPNConnectionInfo())
                return
            }
        }
    }
}

enum VPNManagerType: String {
    case iKEV2 = "iKEV2"
    case wg = "Wg"
    // OpenVPN supports UDP, TCP, Stealth and WSTunnel.
    case openVPN = "OpenVPN"

    func getVPNConnectionInfo() -> VPNConnectionInfo? {
        guard let manager = self.getManager() else {
            return nil
        }
        // Wireguard and OpenVPN uses NETunnelProviderManager.
        if let conf = manager as? NETunnelProviderManager {
            if let wgConfig = conf.tunnelConfiguration,
                let hostAndPort = wgConfig.peers.first?.endpoint?.stringRepresentation.splitToArray(separator: ":") {
                #if os(iOS)
                if #available(iOS 14.0, *) {
                    return VPNConnectionInfo(selectedProtocol: wireGuard, selectedPort: hostAndPort[1], status: manager.connection.status, server: hostAndPort[0], killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
                } else {
                    return VPNConnectionInfo(selectedProtocol: wireGuard, selectedPort: hostAndPort[1], status: manager.connection.status, server: hostAndPort[0], killSwitch: false, onDemand: manager.isOnDemandEnabled)
                }
                #else
                return VPNConnectionInfo(selectedProtocol: wireGuard, selectedPort: hostAndPort[1], status: manager.connection.status, server: hostAndPort[0], killSwitch: false, onDemand: manager.isOnDemandEnabled)
                #endif
            }
            if let neProtocol = conf.protocolConfiguration as? NETunnelProviderProtocol,let ovpn = neProtocol.providerConfiguration?["ovpn"] as? Data {
                return getVPNConnectionInfo(ovpn: ovpn, manager: manager)
            }
        }
        // iKEV2 use NEVPNManager
#if os(iOS)
        if #available(iOS 14.0, *) {
            return VPNConnectionInfo(selectedProtocol: iKEv2, selectedPort: "500", status: manager.connection.status, server: manager.protocolConfiguration?.serverAddress, killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
        } else {
            return VPNConnectionInfo(selectedProtocol: iKEv2, selectedPort: "500", status: manager.connection.status, server: manager.protocolConfiguration?.serverAddress,killSwitch: false, onDemand: manager.isOnDemandEnabled)
        }
        #else
        return VPNConnectionInfo(selectedProtocol: iKEv2, selectedPort: "500", status: manager.connection.status, server: manager.protocolConfiguration?.serverAddress,killSwitch: false, onDemand: manager.isOnDemandEnabled)
        #endif
    }

    private func getVPNConnectionInfo(ovpn: Data, manager: NEVPNManager) -> VPNConnectionInfo? {
        var proto: String?
        var port: String?
        var server: String?
        let rows = String(data: ovpn, encoding: .utf8)?.splitToArray(separator: "\n")
        // check if OpenVPN connection is using local proxy.
        let proxyRow = rows?.first { line in line.starts(with: "local-proxy")}
        if let proxyColumns = proxyRow?.splitToArray(separator: " "), proxyColumns.count > 4, let proxyType = Int(proxyColumns[4]) {
            if proxyType == 1 {
                proto = wsTunnel
            }
            if proxyType == 2 {
                proto = stealth
            }
            port = proxyColumns[3]
            server = proxyColumns[2]
        } else {
            // Direct UDP and TCP OpenVPN connection.
            let protoRow = rows?.first { line in line.starts(with: "proto") }
            if let protoColumns = protoRow?.splitToArray(separator: " "), protoColumns.count > 1 {
                proto = protoColumns[1].uppercased()
            }
            let remoteRow = rows?.first { line in line.starts(with: "remote") }
            if let remoteColumns = remoteRow?.splitToArray(separator: " ") , remoteColumns.count > 2 {
                port = remoteColumns[2].uppercased()
                server = remoteColumns[1]
            }
        }
        if let proto = proto, let port = port {
#if os(iOS)
            if #available(iOS 14.0, *) {
                return VPNConnectionInfo(selectedProtocol: proto, selectedPort: port, status: manager.connection.status, server: server, killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
            } else {
                return VPNConnectionInfo(selectedProtocol: proto, selectedPort: port, status: manager.connection.status, server: server, killSwitch: false, onDemand: manager.isOnDemandEnabled)
            }
#else
            return VPNConnectionInfo(selectedProtocol: proto, selectedPort: port, status: manager.connection.status, server: server, killSwitch: false, onDemand: manager.isOnDemandEnabled)
#endif
        } else {
            return nil
        }
    }

    private func getManager() -> NEVPNManager? {
        switch self {
        case .iKEV2:
            return IKEv2VPNManager.shared.neVPNManager
        case .wg:
            return WireGuardVPNManager.shared.providerManager
        case .openVPN:
            return OpenVPNManager.shared.providerManager
        }
    }
}

struct VPNConnectionInfo: CustomStringConvertible {
    var selectedProtocol: String
    var selectedPort: String
    var status: NEVPNStatus
    var server: String?
    var killSwitch: Bool
    var onDemand: Bool
    var description: String {
        "Protocol: \(selectedProtocol) Port: \(selectedPort) Status: \(status) Server: \(server ?? "") KillSwitch: \(killSwitch) OnDemand: \(onDemand)"
    }
}
