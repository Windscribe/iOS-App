//
//  RepositoryErrors.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-26.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum RepositoryError: Error, CustomStringConvertible, Equatable {
    case invalidConfigData
    case failedToTemplateWgConfig
    case missingServerConfig
    case failedToTemplateOpenVPNConfig
    case failedToLoadConfiguration
    case missingHashedCIDR
    case ipGenerationFailed(String)

    var description: String {
        switch self {
        case .invalidConfigData:
            return "Invalid custom data found."
        case .failedToTemplateWgConfig:
            return "Error templating wg config."
        case .missingServerConfig:
            return "Missing OpenVPN server config."
        case .failedToTemplateOpenVPNConfig:
            return "Error templating OpenVPN config."
        case .failedToLoadConfiguration:
            return "Failed to loadConfigration"
        case .missingHashedCIDR:
            return "Missing hashedCIDR from server response."
        case .ipGenerationFailed(let message):
            return "Failed to generate WireGuard IP: \(message)"
        }
    }
}
