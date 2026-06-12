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

    /// Look-and-feel write surface (background effects, sound effects, dark mode).
    @Entry var lookAndFeelStoring: any LookAndFeelStoring = LegacyLookAndFeelStore(
        repository: Assembler.resolve(LookAndFeelRepositoryType.self),
        preferences: Assembler.resolve(Preferences.self)
    )

    /// Background file operations (save/retrieve custom background images).
    @Entry var backgroundFileStoring: any BackgroundFileStoring = LegacyBackgroundFileStore(
        legacy: Assembler.resolve(BackgroundFileManaging.self)
    )

    /// Sound file operations (save/retrieve custom sound files).
    @Entry var soundFileStoring: any SoundFileStoring = LegacySoundFileStore(
        legacy: Assembler.resolve(SoundFileManaging.self)
    )

    /// Location names management (import/export/reset custom location names).
    @Entry var locationNamesManaging: any LocationNamesManaging = LegacyLocationNamesManager(
        legacy: Assembler.resolve(LocationListRepository.self)
    )

    /// R.O.B.E.R.T. filter read/write surface.
    @Entry var robertFiltering: any RobertFiltering = LegacyRobertFilterStore(
        legacy: Assembler.resolve(RobertyFiltersRepository.self)
    )

    /// R.O.B.E.R.T. custom-rules authenticated URL provider.
    @Entry var robertRuleURLProvider: any RobertRuleURLProviding = LegacyRobertRuleURLProvider(
        apiManager: Assembler.resolve(APIManager.self)
    )

    /// Account actions for the Neo Account preferences screen.
    @Entry var accountManaging: any AccountManaging = LegacyAccountManager(
        sessionManager: Assembler.resolve(SessionManager.self),
        apiManager: Assembler.resolve(APIManager.self)
    )

    /// Device attestation surface (DeviceCheck tokens for backend-side device
    /// quota / fraud signals). Default: production `DCDeviceAttestation`.
    @Entry var deviceAttesting: any DeviceAttesting = DCDeviceAttestation()

    /// DNS settings management (validation, resolution).
    @Entry var dnsSettingsManaging: any DNSSettingsManaging = LegacyDNSSettingsManager(
        legacy: Assembler.resolve(DNSSettingsManagerType.self)
    )

    /// Port map provider (available ports per protocol).
    @Entry var portMapProviding: any PortMapProviding = LegacyPortMapProvider(
        legacy: Assembler.resolve(PortMapRepository.self)
    )

    /// Anti-censorship settings management (protocol tweaks, routing type).
    @Entry var antiCensorshipManaging: any AntiCensorshipManaging = LegacyAntiCensorshipManager(
        legacy: Assembler.resolve(AntiCensorshipRepository.self)
    )

    /// Wi-Fi network provider (saved networks list).
    @Entry var wifiNetworkProviding: any WifiNetworkProviding = LegacyWifiNetworkProvider(
        legacy: Assembler.resolve(WifiNetworkRepository.self)
    )

    /// Network connectivity observer (current network state).
    @Entry var connectivityObserving: any ConnectivityObserving = LegacyConnectivityObserver(
        legacy: Assembler.resolve(ConnectivityManager.self)
    )

    /// Wi-Fi network manager (trust status, preferred protocol updates).
    @Entry var wifiNetworkManaging: any WifiNetworkManaging = LegacyWifiNetworkManager(
        legacy: Assembler.resolve(WifiNetworkRepository.self)
    )

    /// VPN state provider (connection status).
    @Entry var vpnStateProviding: any VPNStateProviding = LegacyVPNStateProvider(
        legacy: Assembler.resolve(VPNStateRepository.self)
    )

    /// Protocol manager (protocol switching and refresh).
    @Entry var protocolManaging: any ProtocolManaging = LegacyProtocolManager(
        legacy: Assembler.resolve(ProtocolManagerType.self)
    )

    /// VPN on-demand rules manager (updates trust-based rules).
    @Entry var vpnOnDemandManaging: any VPNOnDemandManaging = LegacyVPNOnDemandManager(
        legacy: Assembler.resolve(VPNManager.self)
    )

    /// Debug log submission surface.
    @Entry var debugLogManaging: any DebugLogManaging = LegacyDebugLogManager(
        legacy: Assembler.resolve(APIManager.self)
    )

    /// Support ticket submission surface.
    @Entry var ticketManaging: any TicketManaging = LegacyTicketManager(
        legacy: Assembler.resolve(APIManager.self)
    )

    /// Referral/share state surface.
    @Entry var referAndSharing: any ReferAndSharing = LegacyReferAndShareManager(
        legacy: Assembler.resolve(ReferAndShareManager.self)
    )
}
