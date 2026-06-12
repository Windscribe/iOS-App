//
//  RobertFiltering.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@preconcurrency import Combine

/// Read/write surface for R.O.B.E.R.T. filters used by Neo Preferences screens.
protocol RobertFiltering: Sendable {
    var filters: [RobertFilterModel] { get }
    var filterUpdates: AsyncStream<[RobertFilterModel]> { get }

    func refreshFilters() async throws
    func updateFilter(_ filter: RobertFilterModel) async throws
}

/// Adapter wrapping the legacy Combine-backed `RobertyFiltersRepository`.
final class LegacyRobertFilterStore: RobertFiltering, @unchecked Sendable {
    private let legacy: RobertyFiltersRepository

    init(legacy: RobertyFiltersRepository) {
        self.legacy = legacy
    }

    var filters: [RobertFilterModel] {
        legacy.robertFilters.value
    }

    var filterUpdates: AsyncStream<[RobertFilterModel]> {
        let subject = legacy.robertFilters
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }

    func refreshFilters() async throws {
        try await legacy.refreshFilters()
    }

    func updateFilter(_ filter: RobertFilterModel) async throws {
        try await legacy.updateFilter(filter)
    }
}
