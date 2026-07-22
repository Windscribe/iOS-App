//
//  PreferencesReading.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@preconcurrency import Combine

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
    var locationOrder: String? { get }
    var isHapticFeedbackEnabled: Bool { get }
    var isLocationLoadEnabled: Bool { get }
    var soundEffectConnect: String? { get }
    var soundEffectDisconnect: String? { get }
    var customSoundPathConnect: String? { get }
    var customSoundPathDisconnect: String? { get }
    var customAppIcon: String? { get }
    var connectionMode: String? { get }
    var connectedDNS: String? { get }
    var customDNSValue: String { get }
    var egressProtocol: String? { get }
    var ingressProtocol: String? { get }
    var autoSecureNewNetworks: Bool { get }
    var ssoProvider: String? { get }
    var tlsServerName: String? { get }

    var locationLoadUpdates: AsyncStream<Bool> { get }
    var hapticFeedbackUpdates: AsyncStream<Bool> { get }
    var locationOrderUpdates: AsyncStream<String> { get }
    var selectedProtocolUpdates: AsyncStream<String?> { get }
    var selectedPortUpdates: AsyncStream<String?> { get }
    var killSwitchUpdates: AsyncStream<Bool> { get }
    var allowLANUpdates: AsyncStream<Bool> { get }
    var connectionModeUpdates: AsyncStream<String?> { get }
    var connectedDNSUpdates: AsyncStream<String?> { get }
    var egressProtocolUpdates: AsyncStream<String?> { get }
    var ingressProtocolUpdates: AsyncStream<String?> { get }
    var autoSecureUpdates: AsyncStream<Bool> { get }
    var advanceParams: String? { get }

    func getCustomAppIcon() -> String?
}

/// Adapter wrapping the legacy `Preferences` store.
final class LegacyPreferencesReader: PreferencesReading, Sendable {
    private let legacy: Preferences

    init(legacy: Preferences) {
        self.legacy = legacy
    }

    var killSwitchEnabled: Bool { legacy.getKillSwitchSync() }
    var allowLAN: Bool { legacy.getAllowLaneSync() }
    var isHapticFeedbackEnabled: Bool { legacy.getHapticFeedbackSync() }
    var isLocationLoadEnabled: Bool { legacy.getShowServerNetLoadSync() }
    var locationOrder: String? { legacy.getOrderLocationsBySync() }
    var soundEffectConnect: String? { legacy.getSoundEffectConnect() }
    var soundEffectDisconnect: String? { legacy.getSoundEffectDisconnect() }
    var customSoundPathConnect: String? { legacy.getCustomSoundEffectPathConnect() }
    var customSoundPathDisconnect: String? { legacy.getCustomSoundEffectPathDisconnect() }
    var customAppIcon: String? { legacy.getCustomAppIcon() }
    var connectionMode: String? { legacy.getConnectionModeSync() }
    var connectedDNS: String? { legacy.getConnectedDNS() }
    var customDNSValue: String { legacy.getCustomDNSValue().value }
    var egressProtocol: String? { legacy.getEgressProtocolPreferenceSync() }
    var ingressProtocol: String? { legacy.getIngressProtocolPreferenceSync() }
    var autoSecureNewNetworks: Bool { legacy.getAutoSecureNewNetworksSync() }
    var ssoProvider: String? { legacy.getSSOProvider() }
    var tlsServerName: String? { legacy.getTlsServerName() }

    // Legacy protocol overloads `getSelectedProtocolSync` by return type (String / String?); pick the optional one.
    var selectedProtocol: String? {
        let value: String? = legacy.getSelectedProtocolSync()
        return value
    }
    var selectedPort: String? {
        let value: String? = legacy.getSelectedPortSync()
        return value
    }

    var locationLoadUpdates: AsyncStream<Bool> {
        let subject = legacy.getShowServerNetLoad()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value ?? false)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var hapticFeedbackUpdates: AsyncStream<Bool> {
        let subject = legacy.getHapticFeedback()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value ?? false)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var locationOrderUpdates: AsyncStream<String> {
        let subject = legacy.getOrderLocationsBy()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value ?? DefaultValues.orderLocationsBy)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var selectedProtocolUpdates: AsyncStream<String?> {
        let subject = legacy.getSelectedProtocol()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var selectedPortUpdates: AsyncStream<String?> {
        let subject = legacy.getSelectedPort()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var killSwitchUpdates: AsyncStream<Bool> {
        let subject = legacy.getKillSwitch()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value ?? DefaultValues.killSwitch)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var allowLANUpdates: AsyncStream<Bool> {
        let subject = legacy.getAllowLAN()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value ?? DefaultValues.allowLANMode)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var connectionModeUpdates: AsyncStream<String?> {
        let subject = legacy.getConnectionMode()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var connectedDNSUpdates: AsyncStream<String?> {
        let subject = legacy.getConnectedDNSObservable()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var egressProtocolUpdates: AsyncStream<String?> {
        let subject = legacy.getEgressProtocolPreference()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var ingressProtocolUpdates: AsyncStream<String?> {
        let subject = legacy.getIngressProtocolPreference()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var autoSecureUpdates: AsyncStream<Bool> {
        let subject = legacy.getAutoSecureNewNetworks()
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value ?? DefaultValues.autoSecure)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    var advanceParams: String? {
        legacy.getAdvanceParams()
    }

    func getCustomAppIcon() -> String? {
        return legacy.getCustomAppIcon()
    }
}
