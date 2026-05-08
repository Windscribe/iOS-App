//
//  PreferencesReading.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// A small read surface over the legacy `Preferences` store. The legacy
/// protocol exposes ~150 methods covering every saved preference; this
/// Neo-side surface exposes only the high-frequency reads early Neo
/// features need.
///
/// **Scope note:** intentionally minimal. Each new Neo feature that needs
/// a preference adds the property here and a one-line forwarder in the
/// adapter — no batch migrations.
protocol PreferencesReading: Sendable {
    var killSwitchEnabled: Bool { get }
    var allowLAN: Bool { get }
    var selectedProtocol: String? { get }
    var selectedPort: String? { get }
}

/// Adapter wrapping the legacy `Preferences` store.
final class LegacyPreferencesReader: PreferencesReading, Sendable {
    private let legacy: Preferences

    init(legacy: Preferences) {
        self.legacy = legacy
    }

    var killSwitchEnabled: Bool { legacy.getKillSwitchSync() }
    var allowLAN: Bool { legacy.getAllowLaneSync() }

    // Legacy protocol overloads `getSelectedProtocolSync` by return type (String / String?); pick the optional one.
    var selectedProtocol: String? {
        let value: String? = legacy.getSelectedProtocolSync()
        return value
    }
    var selectedPort: String? {
        let value: String? = legacy.getSelectedPortSync()
        return value
    }
}
