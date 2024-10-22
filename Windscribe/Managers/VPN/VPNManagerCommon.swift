//
//  VPNManagerCommon.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

struct VPNManagerCommon {
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
}
