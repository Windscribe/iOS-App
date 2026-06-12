//
//  ConnectivityObserving.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-06-05.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Network connectivity observation surface.
protocol ConnectivityObserving: Sendable {
    /// Current network state.
    var currentNetwork: AppNetwork { get }

    /// Updates stream for network changes.
    var networkUpdates: AsyncStream<AppNetwork> { get }
}

/// Adapter wrapping the legacy `ConnectivityManager`.
final class LegacyConnectivityObserver: ConnectivityObserving, Sendable {
    private let legacy: ConnectivityManager

    init(legacy: ConnectivityManager) {
        self.legacy = legacy
    }

    var currentNetwork: AppNetwork {
        legacy.getNetwork()
    }

    var networkUpdates: AsyncStream<AppNetwork> {
        let subject = legacy.network
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
