//
//  Environment+Dependencies.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

@available(iOS 17.0, *)
extension EnvironmentValues {
    /// Look-and-feel observation surface (dark-mode state + updates).
    /// Default: adapter wrapping the Swinject-resolved legacy repository.
    @Entry var lookAndFeel: any LookAndFeelObserving = LegacyLookAndFeelObserver(
        repository: Assembler.resolve(LookAndFeelRepositoryType.self)
    )

    /// VPN connect / disconnect command surface.
    /// (Status stream is M4 work — see T4.2.)
    @Entry var vpnConnecting: any VPNConnecting = LegacyVPNConnector(
        legacy: Assembler.resolve(VPNManager.self)
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

    /// Active user session + session-update stream.
    @Entry var sessionProviding: any SessionProviding = LegacySessionProvider(
        legacy: Assembler.resolve(UserSessionRepository.self)
    )
}
