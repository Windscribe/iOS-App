//
//  VPNConfigurationErrors.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-30.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
enum VPNConfigurationErrors: Error, LocalizedError {
    case credentialsNotFound(String)
    case customConfigSupportNotAvailable
    case locationNotFound(String)
    case noValidNodeFound
    case invalidLocationType
    case invalidServerConfig
    case configNotFound

    var errorDescription: String? {
        switch self {
            case .credentialsNotFound(let proto):
                return "Couldn't find auth credentials for protocol \(proto)"
            case .customConfigSupportNotAvailable:
                return "IKEv2 does not support custom config."
            case .locationNotFound(let id):
                return "No location found matching location ID: \(id)"
            case .noValidNodeFound:
                return "No valid found to connect."
            case .invalidLocationType:
                return "Invalid location error."
            case .invalidServerConfig:
                return "Invalid server config."
            case .configNotFound:
                return "Config file not found."
        }
    }
}
