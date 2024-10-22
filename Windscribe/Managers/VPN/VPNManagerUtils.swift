//
//  VPNManagerUtils.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

struct VPNManagerUtils {
    static func getActiveManager(completionHandler: @escaping (Swift.Result<NEVPNManager, Error>) -> Void) {
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

    static func getActiveManager() async throws -> NEVPNManager {
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

    // Open and wireguard
    static func getNETunnelProvider() async throws -> NEVPNManager {
        let providers = try await NETunnelProviderManager.loadAllFromPreferences()
        if providers.count > 0 {
            return providers[0]
        } else {
            throw AppIntentError.VPNNotConfigured
        }
    }

    // iKEV2
    static func getNEVPNManager() async throws -> NEVPNManager {
        let manager = NEVPNManager.shared()
        try await manager.loadFromPreferences()
        if manager.protocolConfiguration == nil {
            throw AppIntentError.VPNNotConfigured
        }
        return manager
    }

    static func getAllManagers() async throws -> [NEVPNManager] {
        var providers: [NEVPNManager] = try await NETunnelProviderManager.loadAllFromPreferences()
        guard providers.count > 0 else { throw AppIntentError.VPNNotConfigured }
        await providers.append(try getNEVPNManager())
        return providers
    }

    static func isManagerConfigured(for manager: NEVPNManager) -> Bool {
        if [TextsAsset.openVPN, TextsAsset.wireGuard].contains(manager.protocolConfiguration?.username) {
            return true
        }
        return manager.protocolConfiguration?.username != nil
    }
}
