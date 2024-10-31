//
//  ConfigurationsManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject
import RxSwift

protocol ConfigurationsManagerDelegate: AnyObject {
    func setRestartOnDisconnect(with value: Bool)
}

class ConfigurationsManager {
    let logger: FileLogger// = Assembler.resolve(FileLogger.self)
    let localDatabase: LocalDatabase// = Assembler.resolve(LocalDatabase.self)
    let keychainDb: KeyChainDatabase// = Assembler.resolve(KeyChainDatabase.self)
    let fileDatabase: FileDatabase// = Assembler.resolve(FileDatabase.self)

    let wgCredentials = Assembler.resolve(WgCredentials.self)

    weak var delegate: ConfigurationsManagerDelegate?

    var managers: [NEVPNManager] = []
    var reloadManagersTrigger = BehaviorSubject<Void>(value: ())
    var disposeBag = DisposeBag()
    var noResponseTimer: Timer?

    init(logger: FileLogger, localDatabase: LocalDatabase, keychainDb: KeyChainDatabase, fileDatabase: FileDatabase) {
        self.logger = logger
        self.localDatabase = localDatabase
        self.keychainDb = keychainDb
        self.fileDatabase = fileDatabase
        load()
    }

    private func load() {
        reloadManagersTrigger.subscribe { [weak self] _ in
            self?.reloadManagers()
        }.disposed(by: disposeBag)
    }

    private func reloadManagers() {
        Task {
            managers = (try? await getAllManagers()) ?? []
        }
    }

    func getActiveManager(completionHandler: @escaping (Swift.Result<NEVPNManager, Error>) -> Void) {
        Task {
            do {
                let manager = try await getActiveManager()
                await MainActor.run {
                    completionHandler(.success(manager))
                }
            } catch {
                await MainActor.run {
                    completionHandler(.failure(error))
                }
            }
        }
    }

    func getActiveManager() async throws -> NEVPNManager {
        do {
            return try await getNETunnelProvider()
        } catch let e {
            if let e = e as? AppIntentError, e == AppIntentError.VPNNotConfigured {
                return try await getNEVPNManager()
            } else {
                throw e
            }
        }
    }

    private func getNETunnelProvider() async throws -> NEVPNManager {
        let providers = try await NETunnelProviderManager.loadAllFromPreferences()
        if providers.count > 0 {
            return providers[0]
        } else {
            throw AppIntentError.VPNNotConfigured
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

    private func getAllManagers() async throws -> [NEVPNManager] {
        var providers: [NEVPNManager] = await [try? getNEVPNManager()].compactMap { $0 }
        let tunnelProviders = try? await NETunnelProviderManager.loadAllFromPreferences()
        providers.append(contentsOf: tunnelProviders ?? [])
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

    func isConfigured(manager: NEVPNManager?) -> Bool {
        guard let manager = manager else { return false }
        return manager.protocolConfiguration?.username != nil
    }

    func updateOnDemandRules(manager: NEVPNManager, onDemandRules: [NEOnDemandRule]) async {
        manager.onDemandRules?.removeAll()
        manager.onDemandRules = onDemandRules
        await save(manager: manager)
    }

    func save(manager: NEVPNManager) async {
        try? await manager.saveToPreferences()
        try? await manager.loadFromPreferences()
        reloadManagersTrigger.onNext(())
    }

    func remove(manager: NEVPNManager) async {
        try? await manager.removeFromPreferences()
        try? await manager.loadFromPreferences()
        reloadManagersTrigger.onNext(())
    }

    func saveThrowing(manager: NEVPNManager) async throws {
        try await manager.saveToPreferences()
        try await manager.loadFromPreferences()
        reloadManagersTrigger.onNext(())
    }

    func isIKEV2(manager: NEVPNManager) -> Bool {
        return ![TextsAsset.openVPN, TextsAsset.wireGuard].contains(manager.protocolConfiguration?.username)
        && manager.protocolConfiguration?.username != nil
    }

    func isWireguard(manager: NEVPNManager) -> Bool {
        return  manager.protocolConfiguration?.username == TextsAsset.wireGuard
    }

    func isOpenVPN(manager: NEVPNManager) -> Bool {
        return  manager.protocolConfiguration?.username == TextsAsset.openVPN
    }

    func iKEV2Manager() -> NEVPNManager? {
        managers.first { isIKEV2(manager: $0 ) }
    }

    func wireguardManager() -> NEVPNManager? {
        managers.first { isWireguard(manager: $0 ) }
    }

    func openVPNdManager() -> NEVPNManager? {
        managers.first { isOpenVPN(manager: $0 ) }
    }

    func manager(with type: VPNManagerType) -> NEVPNManager? {
        managers.first { $0.protocolConfiguration?.username == type.username }
    }

    func getManagerName(from manager: NEVPNManager) -> String {
        if let username = manager.protocolConfiguration?.username {
            if username == TextsAsset.wireGuard || username == TextsAsset.wireGuard {
                return username
            }
            return TextsAsset.iKEv2
        }
        return ""
    }

    func setOnDemandMode(_ status: Bool, for manager: NEVPNManager?) {
        guard let manager = manager else { return }
        Task {
            guard (try? await manager.loadFromPreferences()) != nil else { return }
            manager.isOnDemandEnabled = status
            await save(manager: manager)
        }
    }

    func reset(manager: NEVPNManager?) async {
        guard let manager = manager else { return }
        manager.isOnDemandEnabled = false
        manager.isEnabled = false
#if os(iOS)
        manager.protocolConfiguration?.includeAllNetworks = false
#endif
        if (try? await saveThrowing(manager: manager)) != nil,
           [NEVPNStatus.connected, NEVPNStatus.connecting].contains(manager.connection.status) {
                manager.connection.stopVPNTunnel()
            }
        try? await Task.sleep(nanoseconds: 2000000000)
    }
}
