//
//  IntentCommon.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

@available(iOS 13.0.0, *)
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

@available(iOS 13.0.0, *)
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
// Open and wireguard
@available(iOS 13.0.0, *)
func getNETunnelProvider() async throws -> NEVPNManager {
    let providers = try await NETunnelProviderManager.loadAllFromPreferences()
    let providersFound = providers.map {$0.protocolConfiguration?.username ?? ""}.joined(separator: ", ")
    print(providersFound)
    if providers.count > 0 {
        return providers[0]
    } else {
        throw AppIntentError.VPNNotConfigured
    }
}

// iKEV2
@available(iOS 13.0.0, *)
func getNEVPNManager() async throws -> NEVPNManager {
    let manager = NEVPNManager.shared()
    try await manager.loadFromPreferences()
    if manager.protocolConfiguration == nil {
        throw AppIntentError.VPNNotConfigured
    }
    return manager
}
