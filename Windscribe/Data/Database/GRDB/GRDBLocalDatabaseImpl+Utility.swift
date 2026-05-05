// GRDBLocalDatabaseImpl+Utility.swift
// Windscribe
//
// Generic reactive helpers for GRDBLocalDatabaseImpl.
// These wrap GRDB's ValueObservation in Combine publishers and merge
// cleanSubject so that clean() triggers an immediate nil/empty emission.
//
// Copyright © 2026 Windscribe. All rights reserved.

import Foundation
import Combine
import GRDB

extension GRDBLocalDatabaseImpl {

    /// Publisher for a single optional model value.
    /// - Emits the current value immediately (`.immediate` scheduling).
    /// - Re-emits whenever the underlying table changes.
    /// - Emits `nil` when `cleanSubject` fires (before the DELETE transaction).
    func safeModelObjectPublisher<M>(
        tracking: @escaping (GRDB.Database) throws -> M?
    ) -> AnyPublisher<M?, Never> {
        let cleanPub = cleanSubject
            .map { _ in nil as M? }
            .eraseToAnyPublisher()

        let obsPub = ValueObservation
            .tracking(tracking)
            .publisher(in: dbQueue, scheduling: .immediate)
            .replaceError(with: nil)
            .eraseToAnyPublisher()

        return Publishers.Merge(cleanPub, obsPub)
            .eraseToAnyPublisher()
    }

    /// Publisher for an array of model values.
    /// - Emits the current array immediately (`.immediate` scheduling).
    /// - Re-emits whenever the underlying table changes.
    /// - Emits `[]` when `cleanSubject` fires.
    func safeModelArrayPublisher<M>(
        tracking: @escaping (GRDB.Database) throws -> [M]
    ) -> AnyPublisher<[M], Never> {
        let cleanPub = cleanSubject
            .map { _ in [M]() }
            .eraseToAnyPublisher()

        let obsPub = ValueObservation
            .tracking(tracking)
            .publisher(in: dbQueue, scheduling: .immediate)
            .replaceError(with: [])
            .eraseToAnyPublisher()

        return Publishers.Merge(cleanPub, obsPub)
            .eraseToAnyPublisher()
    }
}
