//
//  Environment+Dependencies.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

extension EnvironmentValues {
    /// Look-and-feel observation surface (dark-mode state + updates).
    /// Default: adapter wrapping the Swinject-resolved legacy repository.
    @Entry var lookAndFeel: any LookAndFeelObserving = LegacyLookAndFeelObserver(
        repository: Assembler.resolve(LookAndFeelRepositoryType.self)
    )

    /// VPN connect / disconnect commands + status stream
    /// (`AsyncStream<VPNConnectionState>` over `NEVPNStatusDidChange`).
    @Entry var vpnConnecting: any VPNConnecting = LegacyVPNConnector(
        legacy: Assembler.resolve(VPNManager.self),
        stateRepository: Assembler.resolve(VPNStateRepository.self)
    )

    /// Read-side surface over the location list.
    @Entry var serverProviding: any ServerProviding = LegacyServerProvider(
        legacy: Assembler.resolve(LocationListRepository.self)
    )

    /// Read + refresh surface for OpenVPN / IKEv2 server credentials.
    @Entry var credentialStoring: any CredentialStoring = LegacyCredentialStore(
        legacy: Assembler.resolve(CredentialsRepository.self)
    )

    /// Sync read surface over the high-frequency `Preferences` reads Neo
    /// features need today. Grows per-feature.
    @Entry var preferencesReading: any PreferencesReading = LegacyPreferencesReader(
        legacy: Assembler.resolve(Preferences.self)
    )

    /// Sync write surface over the high-frequency `Preferences` writes Neo
    /// features need today. Grows per-feature.
    @Entry var preferencesWriting: any PreferencesWriting = LegacyPreferencesWriter(
        legacy: Assembler.resolve(Preferences.self)
    )

    /// Active user session + session-update stream.
    @Entry var sessionProviding: any SessionProviding = LegacySessionProvider(
        legacy: Assembler.resolve(UserSessionRepository.self)
    )

    /// Active language + update stream.
    @Entry var languageStoring: any LanguageStoring = LegacyLanguageStore(
        legacy: Assembler.resolve(LanguageManager.self)
    )

    /// Logger.
    @Entry var logger: any LogStoring = LegacyLogStore(
        legacy: Assembler.resolve(FileLogger.self)
    )

    /// Push Notifications actions.
    @Entry var pushNotifications: any PushNotificationManaging = LegacyPushNotificationManager(
        legacy: Assembler.resolve(PushNotificationManager.self)
    )

    /// Haptic Feedback actions.
    @Entry var hapticFeedback: any HapticFeedbacking = LegacyHapticFeedbackManager(
        legacy: Assembler.resolve(HapticFeedbackManager.self)
    )

    /// Device attestation surface (DeviceCheck tokens for backend-side device
    /// quota / fraud signals). Default: production `DCDeviceAttestation`.
    @Entry var deviceAttesting: any DeviceAttesting = DCDeviceAttestation()
}
