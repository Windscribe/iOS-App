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
    var mockPreferences: MockPreferences!
    var mockKeychainManager: MockKeychainManager!
    var mockLogger: MockLogger!
    var repository: MigrationRepository!

    override func setUp() {
        super.setUp()
        mockPreferences = MockPreferences()
        mockKeychainManager = MockKeychainManager()
        mockLogger = MockLogger()

        repository = MigrationRepositoryImpl(
            preferences: mockPreferences,
            keychainManager: mockKeychainManager,
            logger: mockLogger
        )
    }

    override func tearDown() {
        repository = nil
        mockPreferences = nil
        mockKeychainManager = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        let newRepository = MigrationRepositoryImpl(
            preferences: mockPreferences,
            keychainManager: mockKeychainManager,
            logger: mockLogger
        )

        XCTAssertNotNil(newRepository, "Repository should be initialized")
    }

    // MARK: - Session Auth Migration Tests

    func testExistingUserDefaultsAuthHash_MigratedToKeychain_UDCleared() {
        mockPreferences.mockFirstInstall = true
        mockPreferences.mockUserDefaultsSessionAuth = "old-auth-hash-from-ud"

        repository.runMigrations()

        XCTAssertTrue(mockPreferences.saveSessionAuthHashCalled, "Should save auth hash to Keychain")
        XCTAssertEqual(mockPreferences.lastSavedSessionAuth, "old-auth-hash-from-ud",
                       "Should migrate the exact auth hash value")
        XCTAssertTrue(mockPreferences.clearUserDefaultsSessionAuthCalled,
                      "Should clear the old UserDefaults auth hash")
    }

    func testFreshInstall_StaleSessionAuthCleared() {
        mockPreferences.mockFirstInstall = false
        mockPreferences.sessionAuthToReturn = "stale-auth-hash"

        repository.runMigrations()

        XCTAssertTrue(mockPreferences.clearSessionAuthCalled,
                      "Should clear stale session auth from Keychain")
        XCTAssertFalse(mockPreferences.saveSessionAuthHashCalled,
                       "Should NOT save auth hash on fresh install")
    }

    func testAlreadyMigrated_AuthNotResaved() {
        mockPreferences.mockFirstInstall = true
        mockPreferences.mockUserDefaultsSessionAuth = nil

        repository.runMigrations()

        XCTAssertFalse(mockPreferences.saveSessionAuthHashCalled,
                       "Should NOT re-save auth hash if UD is empty")
        XCTAssertFalse(mockPreferences.clearUserDefaultsSessionAuthCalled,
                       "Should NOT clear UD if there was nothing to migrate")
    }
}
