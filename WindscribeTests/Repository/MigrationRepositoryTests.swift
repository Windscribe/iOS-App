//
//  MigrationRepositoryTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 20/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import XCTest
@testable import Windscribe

class MigrationRepositoryTests: XCTestCase {
    var mockLocalDatabase: MockLocalDatabase!
    var repository: MigrationRepository!

    override func setUp() {
        super.setUp()
        mockLocalDatabase = MockLocalDatabase()

        repository = MigrationRepositoryImpl(
            localDatabase: mockLocalDatabase
        )
    }

    override func tearDown() {
        repository = nil
        mockLocalDatabase = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Given/When
        let newRepository = MigrationRepositoryImpl(
            localDatabase: mockLocalDatabase
        )

        // Then
        XCTAssertNotNil(newRepository, "Repository should be initialized")
    }

    // MARK: - Migration Tests

    func testRunMigrationsCallsDatabaseMigrate() {
        // Given
        XCTAssertFalse(mockLocalDatabase.migrateCalled, "Should not be called initially")

        // When
        repository.runMigrations()

        // Then
        XCTAssertTrue(mockLocalDatabase.migrateCalled, "Should call database migrate")
    }

    func testRunMigrationsCanBeCalledMultipleTimes() {
        // Given
        XCTAssertFalse(mockLocalDatabase.migrateCalled, "Should not be called initially")

        // When - Call multiple times
        repository.runMigrations()
        XCTAssertTrue(mockLocalDatabase.migrateCalled, "Should be called after first run")

        // Reset the flag to track second call
        mockLocalDatabase.migrateCalled = false

        repository.runMigrations()

        // Then
        XCTAssertTrue(mockLocalDatabase.migrateCalled, "Should be called again")
    }

    func testRunMigrationsIsIdempotent() {
        // Given
        var callCount = 0
        mockLocalDatabase.onMigrate = {
            callCount += 1
        }

        // When - Call migrations multiple times
        repository.runMigrations()
        repository.runMigrations()
        repository.runMigrations()

        // Then
        XCTAssertEqual(callCount, 3, "Should call migrate for each invocation")
    }

    // MARK: - Integration Tests

    func testMigrationRepositoryWithFreshDatabase() {
        // Given - Fresh database
        let freshDatabase = MockLocalDatabase()
        let migrationRepo = MigrationRepositoryImpl(localDatabase: freshDatabase)

        // When
        migrationRepo.runMigrations()

        // Then
        XCTAssertTrue(freshDatabase.migrateCalled, "Should run migrations on fresh database")
    }

    func testMigrationRepositoryWithExistingDatabase() {
        // Given - Database with existing data
        mockLocalDatabase.sessionSubject.send(Session())

        // When
        repository.runMigrations()

        // Then
        XCTAssertTrue(mockLocalDatabase.migrateCalled, "Should run migrations even with existing data")
    }
}
