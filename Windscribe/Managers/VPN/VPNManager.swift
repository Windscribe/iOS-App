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
import Combine
import Swinject

protocol VPNManager {
    func configureForConnectionState()

    func isActive() async -> Bool

    // Set Methods
    func updateOnDemandRules()
    func resetProfiles() async

    // Connection Methods
    func disconnectFromViewModel() -> AnyPublisher<VPNConnectionState, Error>
    func connectFromViewModel(locationId: String, proto: ProtocolPort) -> AnyPublisher<VPNConnectionState, Error>
    func connectFromViewModel(locationId: String, proto: ProtocolPort, connectionType: ConnectionType) -> AnyPublisher<VPNConnectionState, Error>
    func simpleDisableConnection()
    func simpleEnableConnection()

    // Util Methods
    func makeUserSettings() -> VPNUserSettings
}

extension VPNManager {
    func connectFromViewModel(locationId: String, proto: ProtocolPort) -> AnyPublisher<VPNConnectionState, Error> {
        return connectFromViewModel(locationId: locationId, proto: proto, connectionType: .user)
    }
}

class VPNManagerImpl: VPNManager {
    var cancellables = Set<AnyCancellable>()

    private let activeManagerKey = "activeManager"

    let logger: FileLogger
    let localDB: LocalDatabase
    let serverRepository: ServerRepository
    let staticIpRepository: StaticIpRepository
    let preferences: Preferences
    let connectivity: ConnectivityManager
    let configManager: ConfigurationsManager
    let alertManager: AlertManagerV2
    let locationsManager: LocationsManager
    let vpnStateRepository: VPNStateRepository

    var connectionTaskPublisher: AnyCancellable?

    var awaitingConnectionCheck = false

    lazy var credentialsRepository: CredentialsRepository = Assembler.resolve(CredentialsRepository.self)
    lazy var ipRepository: IPRepository =  Assembler.resolve(IPRepository.self)
    lazy var sessionManager: SessionManager = Assembler.resolve(SessionManager.self)
    lazy var protocolManager: ProtocolManagerType =  Assembler.resolve(ProtocolManagerType.self)

    /// The current configuration state of the VPN, with thread-safe access.

    init(logger: FileLogger,
         localDB: LocalDatabase,
         serverRepository: ServerRepository,
         staticIpRepository: StaticIpRepository,
         preferences: Preferences,
         connectivity: ConnectivityManager,
         configManager: ConfigurationsManager,
         alertManager: AlertManagerV2,
         locationsManager: LocationsManager,
         vpnStateRepository: VPNStateRepository) {
        self.logger = logger
        self.localDB = localDB
        self.serverRepository = serverRepository
        self.staticIpRepository = staticIpRepository
        self.preferences = preferences
        self.connectivity = connectivity
        self.configManager = configManager
        self.alertManager = alertManager
        self.locationsManager = locationsManager
        self.vpnStateRepository = vpnStateRepository

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(connectionStatusChanged(_:)),
                                               name: NSNotification.Name.NEVPNStatusDidChange,
                                               object: nil)
        self.vpnStateRepository.connectionStateUpdatedTrigger
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.configureForConnectionState()
            }.store(in: &cancellables)

        self.vpnStateRepository.configurationStateUpdatedTrigger
            .debounce(for: .milliseconds(250), scheduler: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.configureForConnectionState()
            }.store(in: &cancellables)

        self.configManager.delegate = self
    }

    func isActive() async -> Bool {
        guard (try? await configManager.getConfiguredManager()) != nil else { return false }
        return true
    }

    func updateOnDemandRules() {
        let onDemandRules = getOnDemandRules()
        for manager in configManager.managers {
            Task {
                await configManager.updateOnDemandRules(manager: manager, onDemandRules: onDemandRules)
            }
        }
    }

    // Replace below with SharedUserDefaults
    var activeVPNManager: VPNManagerType {
        get {
            VPNManagerType(from: preferences.getActiveManagerKey() ?? "")
        }
        set(value) {
            if value != activeVPNManager {
                logger.logI("VPNManager", "Active VPN Manager changed to \(value)")
            }
            preferences.saveActiveManagerKey(key: value.username)
        }
    }

    func makeUserSettings() -> VPNUserSettings {
        return VPNUserSettings(killSwitch: preferences.getKillSwitchSync(),
                               allowLan: preferences.getAllowLaneSync(),
                               isRFC: checkLocalIPIsRFC(),
                               isCircumventCensorshipEnabled: preferences.isCircumventCensorshipEnabled(),
                               onDemandRules: getOnDemandRules())
    }

    func emergencyUserSettings() -> VPNUserSettings {
        var onDemandRules: [NEOnDemandRule] = []
        let ruleConnect = NEOnDemandRuleConnect()
        onDemandRules.append(ruleConnect)
        return VPNUserSettings(killSwitch: false,
                               allowLan: true,
                               isRFC: true,
                               isCircumventCensorshipEnabled: false,
                               onDemandRules: onDemandRules)
    }
}

extension VPNManagerImpl {
    private func getOnDemandRules() -> [NEOnDemandRule] {
        var onDemandRules: [NEOnDemandRule] = []
        if let networks = localDB.getNetworksSync() {
            networks.filter { $0.status == true }.forEach { network in
                if network.SSID == TextsAsset.cellular && network.SSID != vpnStateRepository.untrustedOneTimeOnlySSID {
                    let ruleDisconnect = NEOnDemandRuleDisconnect()
                    #if os(iOS)
                        ruleDisconnect.interfaceTypeMatch = .cellular
                    #endif
                    onDemandRules.append(ruleDisconnect)
                    logger.logD("VPNManager", "Added On demand disconnect rule for cellular network.")
                }
            }
            let unsecureWifiNetworks = networks.filter { $0.status == true && $0.SSID != TextsAsset.cellular && $0.SSID != vpnStateRepository.untrustedOneTimeOnlySSID }.map { $0.SSID }.sorted()
            if unsecureWifiNetworks.count > 0 {
                let ruleDisconnect = NEOnDemandRuleDisconnect()
                ruleDisconnect.ssidMatch = unsecureWifiNetworks
                onDemandRules.append(ruleDisconnect)
                logger.logD("VPNManager", "Added On demand disconnect rule for Wi-fi networks. \(unsecureWifiNetworks.joined(separator: "-").description)")
            }
        }
        let ruleConnect = NEOnDemandRuleConnect()
        onDemandRules.append(ruleConnect)
        return onDemandRules
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
        default: return TextsAsset.iKEv2
        }
    }

    init(from key: String) {
        if key == TextsAsset.iKEv2 {
            self = .iKEV2
        } else if key == TextsAsset.openVPN {
            self = .openVPN
        } else {
            self = .wg
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
        "Protocol: \(selectedProtocol) " +
        "Port: \(selectedPort) " +
        "Status: \(status.rawValue) " +
        "Server: \(server ?? "N/A") " +
        "KillSwitch: \(killSwitch) " +
        "OnDemand: \(onDemand)"
    }
}

extension VPNManagerImpl: ConfigurationsManagerDelegate {
    func setActiveManager(with type: VPNManagerType?) {
        guard let type = type else { return }
        activeVPNManager = type
    }
}
