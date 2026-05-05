// GRDBLocalDatabaseParityTests.swift
// WindscribeTests
//
// Concrete parity subclass that wires the GRDB backend into
// LocalDatabaseContractTests. Every contract test in the base class
// runs against an in-memory GRDB DatabaseQueue.
//
// testAddPingDataOffMain and testUnblockWgParamsSaveRead are NOT
// overridden here — GRDB must pass both (they are skipped on Realm only).
//
// Copyright © 2026 Windscribe. All rights reserved.

import XCTest
import GRDB
@testable import Windscribe

final class GRDBLocalDatabaseParityTests: LocalDatabaseContractTests {
    override func makeLocalDatabase() -> LocalDatabase? {
        do {
            // In-memory queue: no file I/O, fully isolated per test.
            let queue = try DatabaseQueue()
            try GRDBSchema.makeMigrator().migrate(queue)
            return GRDBLocalDatabaseImpl(
                logger: MockLogger(),
                preferences: MockPreferences(),
                dbQueue: queue
            )
        } catch {
            XCTFail("GRDBLocalDatabaseParityTests: failed to set up in-memory DB: \(error)")
            return nil
        }
    }
}
