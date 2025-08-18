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
    case noValidNodeFound
    case invalidLocationType
    case invalidServerConfig
    case configNotFound
    case incorrectVPNManager
    case connectionTimeout
    case connectivityTestFailed
    case authFailure
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
        case .noValidNodeFound:
            return "No valid found to connect."
        case .invalidLocationType:
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
