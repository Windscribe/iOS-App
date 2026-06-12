//
//  LookAndFeelStoring.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-05-26.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Write surface for look-and-feel settings (background effects, sound effects,
/// aspect ratio, dark mode). The Neo-side contract used by feature modules;
/// back this with an adapter over the legacy `LookAndFeelRepositoryType` +
/// `Preferences` until those migrate.
///
/// Crosses isolation boundaries (called from `@MainActor` view models, updates
/// legacy non-isolated state), so it's `Sendable`.
protocol LookAndFeelStoring: Sendable {
    /// Updates the background effect for the connected state.
    func updateBackgroundEffectConnect(effect: BackgroundEffectType)

    /// Updates the background effect for the disconnected state.
    func updateBackgroundEffectDisconnect(effect: BackgroundEffectType)

    /// Updates the path to the custom background image for the connected state.
    func updateBackgroundCustomConnectPath(path: String)

    /// Updates the path to the custom background image for the disconnected state.
    func updateBackgroundCustomDisconnectPath(path: String)

    /// Updates the aspect ratio for custom background images.
    func updateBackgroundCustomAspectRatio(aspectRatio: BackgroundAspectRatioType)

    /// Updates the sound effect for the connected state.
    func updateSoundEffectConnect(value: String)

    /// Updates the sound effect for the disconnected state.
    func updateSoundEffectDisconnect(value: String)

    /// Updates the custom sound file path for the connected state.
    func updateCustomSoundPathConnect(path: String)

    /// Updates the custom sound file path for the disconnected state.
    func updateCustomSoundPathDisconnect(path: String)

    /// Updates the dark mode setting.
    func updateDarkMode(enabled: Bool)
}

/// Adapter that wraps the legacy `LookAndFeelRepositoryType` + `Preferences`
/// (Combine-based, pre-Sendable) and exposes the Neo `LookAndFeelStoring` surface.
///
/// Lives at the Neo composition seam: created in
/// `Windscribe/App/Environment+Dependencies.swift`, never inside a feature module.
final class LegacyLookAndFeelStore: LookAndFeelStoring, Sendable {
    private let repository: LookAndFeelRepositoryType
    private let preferences: Preferences

    init(repository: LookAndFeelRepositoryType, preferences: Preferences) {
        self.repository = repository
        self.preferences = preferences
    }

    func updateBackgroundEffectConnect(effect: BackgroundEffectType) {
        repository.updateBackgroundEffectConnect(effect: effect)
    }

    func updateBackgroundEffectDisconnect(effect: BackgroundEffectType) {
        repository.updateBackgroundEffectDisconnect(effect: effect)
    }

    func updateBackgroundCustomConnectPath(path: String) {
        repository.updateBackgroundCustomConnectPath(path: path)
    }

    func updateBackgroundCustomDisconnectPath(path: String) {
        repository.updateBackgroundCustomDisconnectPath(path: path)
    }

    func updateBackgroundCustomAspectRatio(aspectRatio: BackgroundAspectRatioType) {
        repository.updateBackgroundCustomAspectRatio(aspectRatio: aspectRatio)
    }

    func updateSoundEffectConnect(value: String) {
        preferences.saveSoundEffectConnect(value: value)
    }

    func updateSoundEffectDisconnect(value: String) {
        preferences.saveSoundEffectDisconnect(value: value)
    }

    func updateCustomSoundPathConnect(path: String) {
        preferences.saveCustomSoundEffectPathConnect(path)
    }

    func updateCustomSoundPathDisconnect(path: String) {
        preferences.saveCustomSoundEffectPathDisconnect(path)
    }

    func updateDarkMode(enabled: Bool) {
        preferences.saveDarkMode(darkMode: enabled)
    }
}
