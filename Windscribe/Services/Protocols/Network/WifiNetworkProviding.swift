//
//  WifiNetworkProviding.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Wi-Fi network read surface for Network Options settings.
protocol WifiNetworkProviding: Sendable {
    /// Current list of saved Wi-Fi networks.
    var networks: [WifiNetworkModel] { get }

    /// Updates stream for saved networks changes.
    var networksUpdates: AsyncStream<[WifiNetworkModel]> { get }

    /// Finds a network by SSID.
    func findNetwork(with ssid: String) -> WifiNetworkModel?
}

/// Adapter wrapping the legacy `WifiNetworkRepository`.
final class LegacyWifiNetworkProvider: WifiNetworkProviding, Sendable {
    private let legacy: WifiNetworkRepository

    init(legacy: WifiNetworkRepository) {
        self.legacy = legacy
    }

    var networks: [WifiNetworkModel] {
        legacy.networks.value
    }

    var networksUpdates: AsyncStream<[WifiNetworkModel]> {
        let subject = legacy.networks
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    func findNetwork(with ssid: String) -> WifiNetworkModel? {
        legacy.findNetwork(with: ssid)
    }
}
