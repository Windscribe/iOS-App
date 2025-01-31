//
//  ConfigurationsManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RxSwift
import Swinject

protocol ConfigurationsManagerDelegate: AnyObject {
    func configureForConnectionState()
    func setActiveManager(with type: VPNManagerType?)
}

class ConfigurationsManager {
    let logger: FileLogger // = Assembler.resolve(FileLogger.self)
    let localDatabase: LocalDatabase // = Assembler.resolve(LocalDatabase.self)
    let keychainDb: KeyChainDatabase // = Assembler.resolve(KeyChainDatabase.self)
    let fileDatabase: FileDatabase // = Assembler.resolve(FileDatabase.self)
    let advanceRepository: AdvanceRepository
    let wgRepository: WireguardConfigRepository
    let wgCredentials: WgCredentials
    let preferences: Preferences
    let locationsManager: LocationsManagerType
    let ipRepository: IPRepository
    var api: APIManager {
        return Assembler.resolve(APIManager.self)
    }

    weak var delegate: ConfigurationsManagerDelegate?

    var managers: [NEVPNManager] = []
    var reloadManagersTrigger = BehaviorSubject<Void>(value: ())
    var disposeBag = DisposeBag()

    /// Wait for disconnect event after manager is disabled.
    let disconnectWaitTimeout = 5.0

    /// Max timeout for each connection.
    func getMaxTimeout(proto: String) -> Double {
        if proto == TextsAsset.openVPN {
            return 30
        } else {
            return 20
        }
    }

    /// Number of times to retry connectivity test
    let maxConnectivityTestAttempts = 3

    /// Delay between connectivity test attempt.
    let delayBetweenConnectivityAttempts: UInt64 = 500_000_000

    /// NETunnelProvider mangers safe for concurrent use.
    var wgTunnelManager: NETunnelProviderManager?
    var opTunnelManager: NETunnelProviderManager?
    private let tunnelManagerLock = NSLock()

    init(logger: FileLogger, localDatabase: LocalDatabase, keychainDb: KeyChainDatabase, fileDatabase: FileDatabase, advanceRepository: AdvanceRepository, wgRepository: WireguardConfigRepository, wgCredentials: WgCredentials, preferences: Preferences, locationsManager: LocationsManagerType, ipRepository: IPRepository) {
        self.logger = logger
        self.localDatabase = localDatabase
        self.keychainDb = keychainDb
        self.fileDatabase = fileDatabase
        self.advanceRepository = advanceRepository
        self.wgRepository = wgRepository
        self.wgCredentials = wgCredentials
        self.preferences = preferences
        self.locationsManager = locationsManager
        self.ipRepository = ipRepository
        loadTunnelManagers()
        load()
    }

    /// Load OpenVPN and wireguard managers if already configured
    private func loadTunnelManagers() {
        tunnelManagerLock.lock()
        DispatchQueue.main.async {
            NETunnelProviderManager.loadAllFromPreferences { tunnels, _ in
                if let tunnels = tunnels {
                    for tunnel in tunnels {
                        if tunnel.protocolConfiguration?.username == TextsAsset.wireGuard && self.wgTunnelManager == nil {
                            self.wgTunnelManager = tunnel
                        }
                        if tunnel.protocolConfiguration?.username == TextsAsset.openVPN && self.opTunnelManager == nil {
                            self.opTunnelManager = tunnel
                        }
                    }
                }
                self.tunnelManagerLock.unlock()
            }
        }
    }

    /// Cache OpenVPN and wireguard managers when first configured.
    func cacheTunnelManager(manager: NEVPNManager) {
        tunnelManagerLock.withLock {
            if manager.protocolConfiguration?.username == TextsAsset.openVPN &&  opTunnelManager == nil {
                opTunnelManager = manager as? NETunnelProviderManager
            }
            if manager.protocolConfiguration?.username == TextsAsset.wireGuard &&  wgTunnelManager == nil {
                wgTunnelManager = manager as? NETunnelProviderManager
            }
        }
    }

    private func load() {
        reloadManagersTrigger.subscribe { [weak self] _ in
            self?.reloadManagers()
        }.disposed(by: disposeBag)
    }

    private func reloadManagers() {
        Task {
            managers = (try? await getAllManagers()) ?? []
            delegate?.configureForConnectionState()
        }
    }

    private func getNEVPNManager() async throws -> NEVPNManager {
        let manager = NEVPNManager.shared()
        try await manager.loadFromPreferences()
        if manager.protocolConfiguration == nil {
            throw AppIntentError.VPNNotConfigured
        }
        return manager
    }

    func getAllManagers() async throws -> [NEVPNManager] {
        var providers: [NEVPNManager] = await [try? getNEVPNManager()].compactMap { $0 }
        tunnelManagerLock.withLock {
            if let wgTunnelManager = wgTunnelManager {
                providers.append(wgTunnelManager)
            }
            if let opTunnelManager = opTunnelManager {
                providers.append(opTunnelManager)
            }
        }
        guard providers.count > 0 else { throw AppIntentError.VPNNotConfigured }
        return providers
    }

    func isManagerConfigured(for manager: NEVPNManager) -> Bool {
        if [TextsAsset.openVPN, TextsAsset.wireGuard].contains(manager.protocolConfiguration?.username) {
            return true
        }
        return manager.protocolConfiguration?.username != nil
    }

    func getConfiguredManager() async throws -> NEVPNManager? {
        try? await getAllManagers().first { isManagerConfigured(for: $0) }
    }

    func remove(manager: NEVPNManager) async {
        try? await manager.removeFromPreferences()
        try? await manager.loadFromPreferences()
        reloadManagersTrigger.onNext(())
    }

    func saveToPreferences(manager: NEVPNManager) async throws {
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        reloadManagersTrigger.onNext(())
    }

    func isIKEV2(manager: NEVPNManager) -> Bool {
        return manager.protocolConfiguration is NEVPNProtocolIKEv2
    }

    func isWireguard(manager: NEVPNManager) -> Bool {
        return manager.protocolConfiguration?.username == TextsAsset.wireGuard
    }

    func isOpenVPN(manager: NEVPNManager) -> Bool {
        return manager.protocolConfiguration?.username == TextsAsset.openVPN
    }

    func iKEV2Manager() -> NEVPNManager? {
        managers.first { isIKEV2(manager: $0) }
    }

    func wireguardManager() -> NEVPNManager? {
        managers.first { isWireguard(manager: $0) }
    }

    func openVPNdManager() -> NEVPNManager? {
        managers.first { isOpenVPN(manager: $0) }
    }

    func getManager(for type: VPNManagerType) -> NEVPNManager? {
        switch type {
        case .iKEV2: iKEV2Manager()
        case .wg: wireguardManager()
        case .openVPN: openVPNdManager()
        }
    }

    private func currentManagerMap() async -> [String: NEVPNManager] {
        var managerMap = [String: NEVPNManager]()
        // Not sure if this needs to do getAllManagers, I think just accessing the `managers` would do
        guard let managers = try? await getAllManagers() else {
            return managerMap
        }
        for manager in managers {
            switch manager.protocolConfiguration {
            case is NEVPNProtocolIKEv2:
                managerMap[TextsAsset.iKEv2] = manager
            case let tunnelProtocol as NETunnelProviderProtocol where tunnelProtocol.username == TextsAsset.openVPN:
                managerMap[TextsAsset.openVPN] = manager
            case let tunnelProtocol as NETunnelProviderProtocol where tunnelProtocol.username == TextsAsset.wireGuard:
                managerMap[TextsAsset.wireGuard] = manager
            default:
                break
            }
        }
        return managerMap
    }

    func getNextManager(proto: String) async -> NEVPNManager {
        let map = await currentManagerMap()
        if map.keys.contains(proto) {
            return map[proto]!
        }
        if proto == TextsAsset.iKEv2 {
            return NEVPNManager.shared()
        } else {
            return NETunnelProviderManager()
        }
    }

    func getOtherManagers(proto: String) async -> [NEVPNManager] {
        let map = await currentManagerMap().filter { $0.key != proto }
        return map.map { $0.value }
    }

    func getManagerName(from manager: NEVPNManager) -> String {
        if let username = manager.protocolConfiguration?.username {
            if username == TextsAsset.wireGuard || username == TextsAsset.openVPN {
                return username
            }
            return TextsAsset.iKEv2
        }
        return ""
    }

    func updateOnDemandRules(manager: NEVPNManager, onDemandRules: [NEOnDemandRule]) async {
        manager.onDemandRules?.removeAll()
        manager.onDemandRules = onDemandRules
        try? await saveToPreferences(manager: manager)
    }

    func setOnDemandMode(_ status: Bool, for manager: NEVPNManager?) {
        guard let manager = manager else { return }
        Task {
            guard (try? await manager.loadFromPreferences()) != nil else { return }
            manager.isOnDemandEnabled = status
            try? await saveToPreferences(manager: manager)
        }
    }

    func reset(manager: NEVPNManager?) async {
        guard let manager = manager else { return }
        manager.isOnDemandEnabled = false
        manager.isEnabled = false
        #if os(iOS)
            manager.protocolConfiguration?.includeAllNetworks = false
        #endif
        if (try? await saveToPreferences(manager: manager)) != nil,
           [NEVPNStatus.connected, NEVPNStatus.connecting].contains(manager.connection.status) {
            manager.connection.stopVPNTunnel()
        }
        try? await Task.sleep(nanoseconds: 2_000_000_000)
    }
}
