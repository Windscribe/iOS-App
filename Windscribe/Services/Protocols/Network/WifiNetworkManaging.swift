//
//  WifiNetworkManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Wi-Fi network write surface for Network Settings.
protocol WifiNetworkManaging: Sendable {
    /// Updates the trust status of a network.
    func updateNetworkTrustStatus(network: WifiNetworkModel, trusted: Bool)

    /// Updates the preferred protocol status for a network.
    func updateNetworkPreferredProtocolStatus(network: WifiNetworkModel, status: Bool)

    /// Updates the preferred protocol and port for a network.
    func updateNetworkPreferredProtocol(network: WifiNetworkModel, protocol: String, port: String)

    /// Updates the preferred port for a network.
    func updateNetworkPreferredPort(network: WifiNetworkModel, port: String)

    /// Removes a network from saved networks.
    func removeNetwork(network: WifiNetworkModel)
}

/// Adapter wrapping the legacy `WifiNetworkRepository`.
final class LegacyWifiNetworkManager: WifiNetworkManaging, Sendable {
    private let legacy: WifiNetworkRepository

    init(legacy: WifiNetworkRepository) {
        self.legacy = legacy
    }

    func updateNetworkTrustStatus(network: WifiNetworkModel, trusted: Bool) {
        legacy.updateNetworkTrustStatus(network: network, trusted: trusted)
    }

    func updateNetworkPreferredProtocolStatus(network: WifiNetworkModel, status: Bool) {
        legacy.updateNetworkPreferredProtocolStatus(network: network, status: status)
    }

    func updateNetworkPreferredProtocol(network: WifiNetworkModel, protocol: String, port: String) {
        legacy.updateNetworkPreferredProtocol(network: network, protocol: `protocol`, port: port)
    }

    func updateNetworkPreferredPort(network: WifiNetworkModel, port: String) {
        legacy.updateNetworkPreferredPort(network: network, port: port)
    }

    func removeNetwork(network: WifiNetworkModel) {
        legacy.removeNetwork(network: network)
    }
}
