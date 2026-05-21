//
//  PreferencesWriting.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

protocol PreferencesWriting: Sendable {
    func saveShowServerNetLoad(show: Bool)
    func saveHapticFeedback(haptic: Bool)
    func saveOrderLocationsBy(order: String)
}

/// Adapter wrapping the legacy `Preferences` store.
final class LegacyPreferencesWriter: PreferencesWriting, Sendable {
    private let legacy: Preferences

    init(legacy: Preferences) {
        self.legacy = legacy
    }

    func saveShowServerNetLoad(show: Bool) {
        legacy.saveShowServerNetLoad(show: show)
    }

    func saveHapticFeedback(haptic: Bool) {
        legacy.saveHapticFeedback(haptic: haptic)
    }

    func saveOrderLocationsBy(order: String) {
        legacy.saveOrderLocationsBy(order: order)
    }
}
