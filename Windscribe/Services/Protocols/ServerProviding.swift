//
//  ServerProviding.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

/// Read access to the location list. The Neo-side surface used by feature
/// modules; back this with a thin adapter over the legacy
/// `LocationListRepository` until that repository itself migrates.
///
/// **Scope note:** intentionally minimal. Datacenter / server / favourite
/// reads, mutations, and refresh-triggers stay on the legacy interface for
/// now and will be added to this protocol piecemeal as Neo features need
/// them.
protocol ServerProviding: Sendable {
    /// Synchronous snapshot of the current location list.
    var locations: [LocationModel] { get }

    /// Async stream of location-list updates. The first value emitted is the
    /// current value, so callers can drive UI directly off this stream.
    var locationUpdates: AsyncStream<[LocationModel]> { get }
}

/// Adapter wrapping the legacy `LocationListRepository`.
final class LegacyServerProvider: ServerProviding, Sendable {
    private let legacy: LocationListRepository

    init(legacy: LocationListRepository) {
        self.legacy = legacy
    }

    var locations: [LocationModel] { legacy.currentLocationModels }

    var locationUpdates: AsyncStream<[LocationModel]> {
        let subject = legacy.locationListSubject
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
