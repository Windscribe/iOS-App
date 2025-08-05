//
//  IntentCommon.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import AppIntents
import Foundation
import NetworkExtension

enum AppIntentError: Error, LocalizedError {
    case VPNNotConfigured

    var errorDescription: String? {
        return "Configure using Windscribe."
    }
}

@available(iOS 13.0.0, *)
func getActiveManager(for protocolType: String, completionHandler: @escaping (Swift.Result<NEVPNManager, Error>) -> Void) {
    Task {
        do {
            let manager = try await getNEVPNManager(for: protocolType)
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
func getNEVPNManager(for protocolType: String) async throws -> NEVPNManager {
    let providers = try await NETunnelProviderManager.loadAllFromPreferences()
    let provider = providers
        .compactMap { $0 }
        .first { $0.protocolConfiguration?.username == protocolType }
    if let provider = provider {
        return provider
    } else {
        let provider = NEVPNManager.shared()
        try await provider.loadFromPreferences()
        guard provider.protocolConfiguration != nil else {
            throw AppIntentError.VPNNotConfigured
        }
        return provider
    }
}

@available(iOS 16.0, macOS 13.0, watchOS 9.0, tvOS 16.0, *)
extension IntentDialog {
    static var responseSuccess: Self {
        "Connection request to the VPN was successful."
    }

    static var responseFailure: Self {
        "Sorry, something went wrong while trying to connect, please check the Windscribe app."
    }

    static var responseTimeoutFailure: Self {
        "Sorry, VPN is taking too long to connect, please check the Windscribe app."
    }

    static var responseSuccessDisconnect: Self {
        "Disconnect request of the VPN was successful."
    }

    static var responseFailureDisconnect: Self {
        "Sorry, something went wrong while trying to disconnect, please check the Windscribe app."
    }

    static func responseSuccess(cityName: String, nickName: String, ipAddress: String) -> Self {
        "You are connected to \(cityName), \(nickName) and your IP address is \(ipAddress)."
    }

    static func responseSuccessWithNoConnection(ipAddress: String) -> Self {
        "You are not connected to VPN. Your  IP address is \(ipAddress)."
    }

    static var responseFailureState: Self {
        "Sorry, something went wrong while trying to get your connection state, please check the Windscribe app."
    }
}
