//
//  PortMapProviding.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Port map read surface for Connection settings.
protocol PortMapProviding: Sendable {
    /// Returns available ports for the given protocol type.
    /// - Parameter protocolType: The protocol name (e.g., "WireGuard", "IKEv2", "UDP")
    /// - Returns: Array of port strings, or nil if protocol not found
    func getPorts(protocolType: String) -> [String]?
}

/// Adapter wrapping the legacy `PortMapRepository`.
final class LegacyPortMapProvider: PortMapProviding, Sendable {
    private let legacy: PortMapRepository

    init(legacy: PortMapRepository) {
        self.legacy = legacy
    }

    func getPorts(protocolType: String) -> [String]? {
        legacy.getPorts(protocolType: protocolType)
    }
}
