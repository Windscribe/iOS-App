//
//  VPNOnDemandManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// VPN on-demand rules management surface.
protocol VPNOnDemandManaging: Sendable {
    /// Updates the VPN on-demand rules based on current network trust settings.
    func updateOnDemandRules()
}

/// Adapter wrapping the legacy `VPNManager`.
final class LegacyVPNOnDemandManager: VPNOnDemandManaging, Sendable {
    private let legacy: VPNManager

    init(legacy: VPNManager) {
        self.legacy = legacy
    }

    func updateOnDemandRules() {
        legacy.updateOnDemandRules()
    }
}
