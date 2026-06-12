//
//  VPNStateProviding.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// VPN connection state read surface.
protocol VPNStateProviding: Sendable {
    /// Returns true if VPN is currently connected.
    func isConnected() -> Bool
}

/// Adapter wrapping the legacy `VPNStateRepository`.
final class LegacyVPNStateProvider: VPNStateProviding, Sendable {
    private let legacy: VPNStateRepository

    init(legacy: VPNStateRepository) {
        self.legacy = legacy
    }

    func isConnected() -> Bool {
        legacy.isConnected()
    }
}
