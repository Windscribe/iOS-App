//
//  VPNManagerUtils.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject
import RxSwift

protocol VPNManagerUtilsDelegate: AnyObject {
    func setRestartOnDisconnect(with value: Bool)
}

class VPNManagerUtils {
    let logger: FileLogger// = Assembler.resolve(FileLogger.self)
    let localDatabase: LocalDatabase// = Assembler.resolve(LocalDatabase.self)
    let keychainDb: KeyChainDatabase// = Assembler.resolve(KeyChainDatabase.self)
    let fileDatabase: FileDatabase// = Assembler.resolve(FileDatabase.self)
    let advanceRepository: AdvanceRepository
    let wgRepository: WireguardConfigRepository
    let wgCredentials: WgCredentials

    weak var delegate: VPNManagerUtilsDelegate?

    var managers: [NEVPNManager] = []
    var reloadManagersTrigger = BehaviorSubject<Void>(value: ())
    var disposeBag = DisposeBag()

    init(logger: FileLogger, localDatabase: LocalDatabase, keychainDb: KeyChainDatabase, fileDatabase: FileDatabase, advanceRepository: AdvanceRepository ,wgRepository: WireguardConfigRepository, wgCredentials: WgCredentials) {
        self.logger = logger
        self.localDatabase = localDatabase
        self.keychainDb = keychainDb
        self.fileDatabase = fileDatabase
        self.advanceRepository = advanceRepository
        self.wgRepository = wgRepository
        self.wgCredentials = wgCredentials
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

    func iKEV2() -> NEVPNManager? {
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

    func getIKEV2ConnectionInfo(manager: NEVPNManager?) -> VPNConnectionInfo? {
        guard let manager = manager else { return nil }
#if os(iOS)
        return VPNConnectionInfo(selectedProtocol: iKEv2, selectedPort: "500", status: manager.connection.status, server: manager.protocolConfiguration?.serverAddress, killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
#else
        return VPNConnectionInfo(selectedProtocol: iKEv2, selectedPort: "500", status: manager.connection.status, server: manager.protocolConfiguration?.serverAddress,killSwitch: false, onDemand: manager.isOnDemandEnabled)
#endif
    }

    func getVPNConnectionInfo(manager: NEVPNManager) -> VPNConnectionInfo? {
        guard let conf = manager as? NETunnelProviderManager else { return nil }
        if let wgConfig = conf.tunnelConfiguration,
           let hostAndPort = wgConfig.peers.first?.endpoint?.stringRepresentation.splitToArray(separator: ":") {
#if os(iOS)
            return VPNConnectionInfo(selectedProtocol: wireGuard, selectedPort: hostAndPort[1], status: manager.connection.status, server: hostAndPort[0], killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
#else
            return VPNConnectionInfo(selectedProtocol: wireGuard, selectedPort: hostAndPort[1], status: manager.connection.status, server: hostAndPort[0], killSwitch: false, onDemand: manager.isOnDemandEnabled)
#endif
        }
        guard let neProtocol = conf.protocolConfiguration as? NETunnelProviderProtocol,
              let ovpn = neProtocol.providerConfiguration?["ovpn"] as? Data
        else { return nil }
        return getVPNConnectionInfo(ovpn: ovpn, manager: manager)
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
            return VPNConnectionInfo(selectedProtocol: proto, selectedPort: port, status: manager.connection.status, server: server, killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
#else
            return VPNConnectionInfo(selectedProtocol: proto, selectedPort: port, status: manager.connection.status, server: server, killSwitch: false, onDemand: manager.isOnDemandEnabled)
#endif
        } else {
            return nil
        }
    }
}
