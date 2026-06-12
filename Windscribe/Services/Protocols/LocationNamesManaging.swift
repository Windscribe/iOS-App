//
//  LocationNamesManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-05-26.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Surface for managing custom location names (import/export/reset). The
/// Neo-side contract used by feature modules; back this with an adapter over
/// the legacy `LocationListRepository` until it migrates.
///
/// Sendable since it crosses isolation boundaries.
protocol LocationNamesManaging: Sendable {
    /// Returns the current location models for export.
    var currentLocationModels: [LocationModel] { get }

    /// Updates location regions with custom names from imported data.
    /// Pass an empty array to reset to defaults.
    /// - Parameter regions: The exported region data to apply
    func updateRegions(with regions: [ExportedRegion])
}

/// Adapter that wraps the legacy `LocationListRepository` and exposes the Neo
/// `LocationNamesManaging` surface.
///
/// Lives at the Neo composition seam: created in
/// `Windscribe/App/Environment+Dependencies.swift`, never inside a feature module.
final class LegacyLocationNamesManager: LocationNamesManaging, Sendable {
    private let legacy: LocationListRepository

    init(legacy: LocationListRepository) {
        self.legacy = legacy
    }

    var currentLocationModels: [LocationModel] {
        legacy.currentLocationModels
    }

    func updateRegions(with regions: [ExportedRegion]) {
        legacy.updateRegions(with: regions)
    }
}
