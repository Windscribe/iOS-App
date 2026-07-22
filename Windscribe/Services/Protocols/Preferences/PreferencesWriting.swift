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
    func saveSSOProvider(provider: String)
    func saveCustomAppIcon(value: String)
    func saveConnectionMode(mode: String)
    func saveSelectedProtocol(selectedProtocol: String)
    func saveSelectedPort(port: String)
    func saveKillSwitch(killSwitch: Bool)
    func saveAllowLAN(mode: Bool)
    func saveConnectedDNS(mode: String)
    func saveCustomDNSValue(value: DNSValue)
    func saveEgressProtocolPreference(value: String)
    func saveIngressProtocolPreference(value: String)
    func saveAutoSecureNewNetworks(autoSecure: Bool)
    func saveAdvanceParams(params: String)
    func saveTlsServerName(value: String)
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

    func saveSSOProvider(provider: String) {
        legacy.saveSSOProvider(provider: provider)
    }

    func saveCustomAppIcon(value: String) {
        legacy.saveCustomAppIcon(value: value)
    }

    func saveConnectionMode(mode: String) {
        legacy.saveConnectionMode(mode: mode)
    }

    func saveSelectedProtocol(selectedProtocol: String) {
        legacy.saveSelectedProtocol(selectedProtocol: selectedProtocol)
    }

    func saveSelectedPort(port: String) {
        legacy.saveSelectedPort(port: port)
    }

    func saveKillSwitch(killSwitch: Bool) {
        legacy.saveKillSwitch(killSwitch: killSwitch)
    }

    func saveAllowLAN(mode: Bool) {
        legacy.saveAllowLane(mode: mode)
    }

    func saveConnectedDNS(mode: String) {
        legacy.saveConnectedDNS(mode: mode)
    }

    func saveCustomDNSValue(value: DNSValue) {
        legacy.saveCustomDNSValue(value: value)
    }

    func saveEgressProtocolPreference(value: String) {
        legacy.saveEgressProtocolPreference(value: value)
    }

    func saveIngressProtocolPreference(value: String) {
        legacy.saveIngressProtocolPreference(value: value)
    }

    func saveAutoSecureNewNetworks(autoSecure: Bool) {
        legacy.saveAutoSecureNewNetworks(autoSecure: autoSecure)
    }

    func saveAdvanceParams(params: String) {
        legacy.saveAdvanceParams(params: params)
    }

    func saveTlsServerName(value: String) {
        legacy.saveTlsServerName(value: value)
    }
}
