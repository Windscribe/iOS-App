//
//  HapticFeedbacking.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

protocol HapticFeedbacking: Sendable {
    var hapticFeedbackEnabled: Bool { get }

    func checkSettingsAction(action: MenuEntryActionResponseType)
    func run(level: HapticFeedbackLevel)
}

/// Adapter wrapping the legacy `HapticFeedbackManager`.
final class LegacyHapticFeedbackManager: HapticFeedbacking, Sendable {
    private let legacy: HapticFeedbackManager

    init(legacy: HapticFeedbackManager) {
        self.legacy = legacy
    }

    var hapticFeedbackEnabled: Bool {
        legacy.hapticFeedbackEnabled
    }

    func run(level: HapticFeedbackLevel) {
        legacy.run(level: level)
    }

    func checkSettingsAction(action: MenuEntryActionResponseType) {
        if case .toggle = action {
            run(level: .light)
        }
    }
}
