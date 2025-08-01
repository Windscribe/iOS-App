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
import RxSwift
import Swinject

enum ConfigurationState {
    case configuring
    case disabling
    case initial
    case testing
}

protocol VPNManagerProtocol {}

class VPNManager: VPNManagerProtocol {
    let disposeBag = DisposeBag()

    var vpnInfo = BehaviorSubject<VPNConnectionInfo?>(value: nil)
    var connectionStateUpdatedTrigger = PublishSubject<Void>()

    var lastConnectionStatus: NEVPNStatus = .disconnected

    var isFromProtocolFailover: Bool = false
    var isFromProtocolChange: Bool = false
    var awaitingConnectionCheck = false

    var untrustedOneTimeOnlySSID: String = ""

    /// Represents the configuration state of the VPN.
    private var _configurationState = ConfigurationState.initial

    /// A lock used to synchronize access to the configuration state.
    private let configureStateLock = NSLock()

    private let activeManagerKey = "activeManager"

    let logger: FileLogger
    let localDB: LocalDatabase
    let serverRepository: ServerRepository
    let staticIpRepository: StaticIpRepository
    let preferences: Preferences
    let connectivity: Connectivity
    let configManager: ConfigurationsManager
    let alertManager: AlertManagerV2
    let locationsManager: LocationsManagerType

    var connectionTaskPublisher: AnyCancellable?

    lazy var credentialsRepository: CredentialsRepository = Assembler.resolve(CredentialsRepository.self)
    lazy var ipRepository: IPRepository =  Assembler.resolve(IPRepository.self)
    lazy var sessionManager: SessionManaging = Assembler.resolve(SessionManaging.self)
    lazy var protocolManager: ProtocolManagerType =  Assembler.resolve(ProtocolManagerType.self)

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
            configureForConnectionState()
        }
    }

    init(logger: FileLogger, localDB: LocalDatabase, serverRepository: ServerRepository, staticIpRepository: StaticIpRepository, preferences: Preferences, connectivity: Connectivity, configManager: ConfigurationsManager, alertManager: AlertManagerV2, locationsManager: LocationsManagerType) {
        self.logger = logger
        self.localDB = localDB
        self.serverRepository = serverRepository
        self.staticIpRepository = staticIpRepository
        self.preferences = preferences
        self.connectivity = connectivity
        self.configManager = configManager
        self.alertManager = alertManager
        self.locationsManager = locationsManager

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(connectionStatusChanged(_:)),
                                               name: NSNotification.Name.NEVPNStatusDidChange,
                                               object: nil)
        connectionStateUpdatedTrigger
            .debounce(.milliseconds(250), scheduler: MainScheduler.instance)
            .subscribe { _ in
                self.configureForConnectionState()
        }.disposed(by: disposeBag)

        self.configManager.delegate = self
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
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .compactMap { $0 }
            .map { [weak self] info in
                guard let self = self else { return NEVPNStatus.invalid }
                switch self.configurationState {
                case .configuring:
                    self.logger.logD("VPNConfiguration", "vpnInfo update to: configuring -> connecting")
                    return NEVPNStatus.connecting
                case .disabling:
                    self.logger.logD("VPNConfiguration", "vpnInfo update to: disabling -> disconnecting")
                    return NEVPNStatus.disconnecting
                case .initial:
                    self.logger.logD("VPNConfiguration", "vpnInfo update to: Initial -> \(info.description)")
                    return info.status
                case .testing:
                    return info.status
                }
            }
            .distinctUntilChanged()
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

extension VPNManager {
    private func getOnDemandRules() -> [NEOnDemandRule] {
        var onDemandRules: [NEOnDemandRule] = []
        if let networks = localDB.getNetworksSync() {
            networks.filter { $0.status == true }.forEach { network in
                if network.SSID == TextsAsset.cellular && network.SSID != untrustedOneTimeOnlySSID {
                    let ruleDisconnect = NEOnDemandRuleDisconnect()
                    #if os(iOS)
                        ruleDisconnect.interfaceTypeMatch = .cellular
                    #endif
                    onDemandRules.append(ruleDisconnect)
                    logger.logD("VPNManager", "Added On demand disconnect rule for cellular network.")
                }
            }
            let unsecureWifiNetworks = networks.filter { $0.status == true && $0.SSID != TextsAsset.cellular && $0.SSID != untrustedOneTimeOnlySSID }.map { $0.SSID }.sorted()
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

extension VPNManager: ConfigurationsManagerDelegate {
    func setActiveManager(with type: VPNManagerType?) {
        guard let type = type else { return }
        activeVPNManager = type
    }
}
