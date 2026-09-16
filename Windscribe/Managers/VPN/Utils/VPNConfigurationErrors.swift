//
//  VPNConfigurationErrors.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-30.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum VPNConfigurationErrors: Error, CustomStringConvertible, Equatable {
    case credentialsNotFound(String)
    case customConfigSupportNotAvailable
    case locationNotFound(String)
    case noValidServerFound
    case invalidConnectionTargetType
    case invalidServerConfig
    case configNotFound
    case incorrectVPNManager
    case connectionTimeout
    case connectivityTestFailed
    case authFailure
    case classified(VPNConnectionFailure)
    case upgradeRequired
    case accountExpired
    case accountBanned
    case networkIsOffline
    case privacyNotAccepted
    case customConfigMissingCredentials(CustomConfigModel)

    var description: String {
        switch self {
        case let .credentialsNotFound(proto):
            return "Couldn't find auth credentials for protocol \(proto)"
        case .customConfigSupportNotAvailable:
            return "IKEv2 does not support custom config."
        case let .locationNotFound(id):
            return "No location found matching location ID: \(id)"
        case .noValidServerFound:
            return "No valid server found to connect."
        case .invalidConnectionTargetType:
            return "Invalid location error."
        case .invalidServerConfig:
            return "Invalid server config."
        case .configNotFound:
            return "Config file not found."
        case .incorrectVPNManager:
            return "Incorrect VPN manager."
        case .connectionTimeout:
            return "Connection timeout."
        case .connectivityTestFailed:
            return "Connectivity test failed."
        case .authFailure:
            return "Authentication failure."
        case let .classified(failure):
            return failure.description
        case .upgradeRequired:
            return "Upgrade required to access location."
        case .networkIsOffline:
            return "Network seems offline."
        case .privacyNotAccepted:
            return "Privacy has not been accepted yet."
        case .customConfigMissingCredentials:
            return "Custom config is missing the credentials."
        case .accountExpired:
            return "You have used all your data."
        case .accountBanned:
            return "Your account is banned for misuse."
        }
    }
}

enum ConnectionFailureReason: Sendable, Equatable {
    case accountSessionInvalid
    case authentication
    case wireGuardRegistration
    case wireGuardConfiguration
    case dns
    case backendStartup
    case networkUnavailable
    case accountLimitation
    case timedOut
    case unknown
}

enum VPNFailureStage: String, Sendable, Equatable {
    case configuration
    case tunnel
    case timeout
    case connectivity
}

struct VPNSystemError: Sendable, Equatable {
    let domain: String
    let code: Int
}

struct VPNFailureEvidence: Sendable, Equatable {
    let protocolName: String
    let stage: VPNFailureStage
    let systemError: VPNSystemError?
    let providerError: PacketTunnelProviderError?
    let disconnectReason: DisconnectReason?
}

struct VPNConnectionFailure: Error, CustomStringConvertible, Sendable, Equatable {
    let reason: ConnectionFailureReason
    let evidence: VPNFailureEvidence

    var description: String {
        "VPN connection failed: \(reason)"
    }
}

enum VPNFailureClassifier {
    static func classify(protocolName: String,
                         stage: VPNFailureStage,
                         error: Error? = nil,
                         providerError: PacketTunnelProviderError? = nil,
                         disconnectReason: DisconnectReason = .unknown,
                         fallback: ConnectionFailureReason = .unknown) -> VPNConnectionFailure {
        let nsError = error.map { $0 as NSError }
        let evidence = VPNFailureEvidence(
            protocolName: protocolName,
            stage: stage,
            systemError: nsError.map { VPNSystemError(domain: $0.domain, code: $0.code) },
            providerError: providerError,
            disconnectReason: disconnectReason == .unknown ? nil : disconnectReason
        )

        let reason: ConnectionFailureReason
        switch disconnectReason {
        case .invalidSession:
            reason = .accountSessionInvalid
        case .accountStatusChanged, .userStatusChanged:
            reason = .accountLimitation
        case .unknown:
            if let providerError {
                reason = providerReason(providerError)
            } else if let nsError,
                      nsError.domain == NSURLErrorDomain,
                      nsError.code == NSURLErrorNotConnectedToInternet {
                reason = .networkUnavailable
            } else if let nsError,
                      nsError.domain == NSURLErrorDomain,
                      nsError.code == NSURLErrorTimedOut {
                reason = .timedOut
            } else if fallback != .unknown {
                reason = fallback
            } else if stage == .timeout {
                reason = .timedOut
            } else {
                reason = .unknown
            }
        }
        return VPNConnectionFailure(reason: reason, evidence: evidence)
    }

    private static func providerReason(_ error: PacketTunnelProviderError) -> ConnectionFailureReason {
        switch error {
        case .savedProtocolConfigurationIsInvalid:
            return .wireGuardConfiguration
        case .dnsResolutionFailure:
            return .dns
        case .couldNotStartBackend,
                .couldNotDetermineFileDescriptor,
                .couldNotSetNetworkSettings:
            return .backendStartup
        }
    }
}
