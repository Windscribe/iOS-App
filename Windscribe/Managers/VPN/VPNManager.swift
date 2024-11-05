//
//  VPNManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-28.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
#if canImport(WidgetKit)
    import WidgetKit
#endif
import Combine
import RxSwift
import Swinject

enum ConfigurationState {
    case configuring
    case disabling
    case initial
}

protocol VPNManagerProtocol {}

class VPNManager: VPNManagerProtocol {
    weak var delegate: VPNManagerDelegate?
    let disposeBag = DisposeBag()
    
    var selectedNode: SelectedNode? {
        didSet {
            delegate?.selectedNodeChanged()
        }
    }

    lazy var credentialsRepository: CredentialsRepository = Assembler.resolve(CredentialsRepository.self)

    var vpnInfo = BehaviorSubject<VPNConnectionInfo?>(value: nil)
    var selectedFirewallMode: Bool = true
    var selectedConnectionMode: String?

    var uniqueConnectionId = ""
    var lastConnectionStatus: NEVPNStatus = .disconnected

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
    var awaitingConnectionCheck = false

    // siri shortcut and today extension intents
    var connectWhenReady = false
    var disconnectWhenReady = false

    var displayingAskToRetryPopup: UIAlertController?

    var untrustedOneTimeOnlySSID: String = ""

    var killSwitch: Bool = DefaultValues.killSwitch
    var allowLane: Bool = DefaultValues.allowLaneMode

    var connectionTaskPublisher: AnyCancellable?
    var connectionTask: Task<Void, Never>?
    var selectedProtocol = ProtocolPort(TextsAsset.wireGuard, "443")
    let connectionAlert = VPNConnectionAlert()
    let disconnectAlert = VPNConnectionAlert()

    /// Represents the configuration state of the VPN.
    private var _configurationState = ConfigurationState.initial

    /// A lock used to synchronize access to the configuration state.
    private let configureStateLock = NSLock()
    
    let wgCrendentials: WgCredentials
    let wgRepository: WireguardConfigRepository
    let api: APIManager
    let logger: FileLogger
    let localDB: LocalDatabase
    let serverRepository: ServerRepository
    let staticIpRepository: StaticIpRepository
    let preferences: Preferences
    let connectivity: Connectivity
    let sessionManager: SessionManagerV2
    let configManager: ConfigurationsManager
    let connectionManager: ConnectionManagerV2
    let changeProtocol: ProtocolSwitchViewController
    let alertManager: AlertManagerV2

    init(wgCrendentials: WgCredentials, wgRepository: WireguardConfigRepository, api: APIManager, logger: FileLogger, localDB: LocalDatabase, serverRepository: ServerRepository, staticIpRepository: StaticIpRepository, preferences: Preferences, connectivity: Connectivity, sessionManager: SessionManagerV2, configManager: ConfigurationsManager, connectionManager: ConnectionManagerV2, changeProtocol: ProtocolSwitchViewController, alertManager: AlertManagerV2) {
        self.wgCrendentials = wgCrendentials
        self.wgRepository = wgRepository
        self.api = api
        self.logger = logger
        self.localDB = localDB
        self.serverRepository = serverRepository
        self.staticIpRepository = staticIpRepository
        self.preferences = preferences
        self.connectivity = connectivity
        self.sessionManager = sessionManager
        self.configManager = configManager
        self.connectionManager = connectionManager
        self.changeProtocol = changeProtocol
        self.alertManager = alertManager
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(connectionStatusChanged(_:)),
                                               name: NSNotification.Name.NEVPNStatusDidChange,
                                               object: nil)
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
    
    /// The current configuration state of the VPN, with thread-safe access.
    var configurationState: ConfigurationState {
        get {
            configureStateLock.lock()
            defer { configureStateLock.unlock() }
            return _configurationState
        }
        set {
            configureStateLock.lock()
            _configurationState = newValue
            configureStateLock.unlock()
        }
    }
    
    func resetProperties() {
        retryWithNewCredentials = false
        restartOnDisconnect = false
        keepConnectingState = false
        disableOrFailOnDisconnect = false
        retryTimer?.invalidate()
        connectingTimer?.invalidate()
        disconnectingTimer?.invalidate()
        contentIntentTimer?.invalidate()
        connectivityTestTimer?.invalidate()
        failCountTimer?.invalidate()
    }

    func isActive() async -> Bool {
        guard (try? await configManager.getConfiguredManager()) != nil else { return false }
        return true
    }

    /// Returns an observable that emits the VPN status with a debounce and custom mapping logic.
    /// This function observes changes in the `vpnInfo` and applies a debounce to avoid rapid updates.
    ///
    /// - Returns: An `Observable` that emits the VPN status as an `NEVPNStatus` value.
    func getStatus() -> Observable<NEVPNStatus> {
        return vpnInfo
            .debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .compactMap { $0 }
            .map { [weak self] info in
                guard let self = self else { return NEVPNStatus.invalid }
                switch self.configurationState {
                case .configuring:
                    return NEVPNStatus.connecting
                case .disabling:
                    return NEVPNStatus.disconnecting
                case .initial:
                    return info.status
                }
            }
            .distinctUntilChanged()
    }

    func setup() async {
        configManager.delegate = self
        preferences.getKillSwitch().subscribe { data in
            self.killSwitch = data ?? DefaultValues.killSwitch
        }.disposed(by: disposeBag)
        preferences.getAllowLane().subscribe { data in
            self.allowLane = data ?? DefaultValues.allowLaneMode
        }.disposed(by: disposeBag)
    }

    func removeAllVPNProfiles() {
        NEVPNManager.shared().removeFromPreferences { _ in }
        NETunnelProviderManager.loadAllFromPreferences { managers, error in
            guard error != nil else { return }
            managers?.forEach { $0.removeFromPreferences { _ in }
            }
        }
    }

    func getOnDemandRules() -> [NEOnDemandRule] {
        var onDemandRules: [NEOnDemandRule] = []
        if let networks = localDB.getNetworksSync() {
            networks.filter { $0.status == true }.forEach { network in
                if network.SSID == TextsAsset.cellular && network.SSID != untrustedOneTimeOnlySSID {
                    let ruleDisconnect = NEOnDemandRuleDisconnect()
                    #if os(iOS)
                        ruleDisconnect.interfaceTypeMatch = .cellular
                    #endif
                    onDemandRules.append(ruleDisconnect)
                    logger.logD(VPNManager.self, "Added On demand disconnect rule for cellular network.")
                }
            }
            let unsecureWifiNetworks = networks.filter { $0.status == true && $0.SSID != TextsAsset.cellular && $0.SSID != untrustedOneTimeOnlySSID }.map { $0.SSID }.sorted()
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

    func updateOnDemandRules() {
        isOnDemandRetry = false
        let onDemandRules = getOnDemandRules()
        for manager in configManager.managers {
            Task {
                await configManager.updateOnDemandRules(manager: manager, onDemandRules: onDemandRules)
            }
        }
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
            logger.logE(VPNManager.self, "Failed to load vpn credentials.")
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
            logger.logD(self, "[\(uniqueConnectionId)] Running connectivity Test")
            api.getIp().observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { myIp in
                self.executeForConnectivityTestSuccessful(ipAddress: myIp.userIp, checkForIPAddressChange: checkForIPAddressChange)
            }, onFailure: { _ in
                if retry {
                    self.logger.logD(self, "[\(self.uniqueConnectionId)] Retrying connectivity test.")
                    self.connectivityTestTimer = Timer.scheduledTimer(timeInterval: 3.0,
                                                                      target: self,
                                                                      selector: #selector(self.runConnectivityTestWithNoRetry),
                                                                      userInfo: nil,
                                                                      repeats: false)
                } else if connectToAnotherNode {
                    self.logger.logD(self, "[\(self.uniqueConnectionId)] Retrying connectivity test with different node.")
                    self.connectToAnotherNode()
                } else {
                    self.logger.logD(self, "Connectivity failed.")
                    self.isOnDemandRetry = false
                    self.disconnectOrFail()
                }
            }).disposed(by: disposeBag)
        }
    }

    func executeForConnectivityTestSuccessful(ipAddress: String,
                                              checkForIPAddressChange _: Bool = true) {
        logger.logE(VPNManager.self, "[\(uniqueConnectionId)] Connectivity Test successful.")

        AutomaticMode.shared.resetFailCounts()
        ConnectionManager.shared.goodProtocol = ConnectionManager.shared.getNextProtocol()
        delegate?.displaySetPrefferedProtocol()
        ConnectionManager.shared.onConnectStateChange(state: NEVPNStatus.connected)
        DispatchQueue.main.async {
            if self.isConnected() {
                self.isOnDemandRetry = false
                self.preferences.saveConnectionCount(count: (self.preferences.getConnectionCount() ?? 0) + 1)
                self.delegate?.setConnected(ipAddress: ipAddress)
                self.resetProperties()
                self.connectIntent = true
                if self.selectedFirewallMode == true {
                    self.isOnDemandRetry = true
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
                logger.logE(VPNManager.self, "Active VPN Manager changed to \(value)")
                preferences.saveActiveManagerKey(key: value.rawValue)
                UserDefaults.standard.setValue(value.rawValue, forKey: activeManagerKey)
            }
        }
    }

    /**
     Parses updated VPN connection info from configured VPN managers.
     */
    func getVPNConnectionInfo(completion: @escaping (VPNConnectionInfo?) -> Void) {
        // Refresh and load all VPN Managers from system preferrances.
        let priorityStates = [NEVPNStatus.connecting, NEVPNStatus.connected, NEVPNStatus.disconnecting]
        var priorityManagers: [NEVPNManager] = []
        configManager.managers.forEach {
            if priorityStates.contains($0.connection.status) {
                priorityManagers.append($0)
            }
        }
        if priorityManagers.count == 1 {
            if configManager.isIKEV2(manager: priorityManagers[0]) {
                completion(configManager.getIKEV2ConnectionInfo(manager: priorityManagers[0]))
            } else {
                completion(configManager.getVPNConnectionInfo(manager: priorityManagers[0]))
            }
            return
        }

        if let enabledManager = priorityManagers.filter({ $0.isEnabled }).first {
            if configManager.isIKEV2(manager: enabledManager) {
                completion(configManager.getIKEV2ConnectionInfo(manager: enabledManager))
            } else {
                completion(configManager.getVPNConnectionInfo(manager: enabledManager))
            }
            return
        }

        // No VPN Manager is configured
        if (configManager.managers.filter { $0.connection.status != .invalid }).isEmpty {
            completion(nil)
            return
        }
        // Get VPN connection info from last active manager.
        if activeVPNManager == .iKEV2 {
            completion(configManager.getIKEV2ConnectionInfo(manager: configManager.iKEV2Manager()))
        } else {
            completion(configManager.getVPNConnectionInfo(manager: configManager.getManager(for: activeVPNManager)))
        }
    }

    func makeUserSettings() -> VPNUserSettings {
        return VPNUserSettings(killSwitch: killSwitch,
                               allowLan: allowLane,
                               isRFC: checkLocalIPIsRFC(),
                               isCircumventCensorshipEnabled: preferences.isCircumventCensorshipEnabled(),
                               onDemandRules: getOnDemandRules())
    }
}

enum VPNManagerType: String {
    case iKEV2
    case wg = "Wg"
    // OpenVPN supports UDP, TCP, Stealth and WSTunnel.
    case openVPN = "OpenVPN"

    var username: String {
        switch self {
        case .wg: return TextsAsset.wireGuard
        case .openVPN: return TextsAsset.openVPN
        default: return ""
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

extension VPNManager: ConfigurationsManagerDelegate {
    func setRestartOnDisconnect(with value: Bool) {
        restartOnDisconnect = value
    }
}
