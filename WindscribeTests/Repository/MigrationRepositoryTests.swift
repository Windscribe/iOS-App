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
    var mockUserSessionRepository: MockUserSessionRepository!
    var mockLogger: MockLogger!
    var repository: MigrationRepository!

    override func setUp() {
        super.setUp()
        mockPreferences = MockPreferences()
        mockKeychainManager = MockKeychainManager()
        mockUserSessionRepository = MockUserSessionRepository()
        mockLogger = MockLogger()

        repository = MigrationRepositoryImpl(
            preferences: mockPreferences,
            keychainManager: mockKeychainManager,
            userSessionRepository: mockUserSessionRepository,
            logger: mockLogger
        )
    }

    override func tearDown() {
        repository = nil
        mockPreferences = nil
        mockKeychainManager = nil
        mockUserSessionRepository = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        let newRepository = MigrationRepositoryImpl(
            preferences: mockPreferences,
            keychainManager: mockKeychainManager,
            userSessionRepository: mockUserSessionRepository,
            logger: mockLogger
        )

        XCTAssertNotNil(newRepository, "Repository should be initialized")
    }

    // MARK: - Session Auth Migration Tests

    func testExistingUserDefaultsAuthHash_MigratedToKeychain_UDCleared() {
        mockPreferences.mockFirstInstall = true
        mockPreferences.mockUserDefaultsSessionAuth = "old-auth-hash-from-ud"

        repository.runMigrations()

        XCTAssertTrue(mockUserSessionRepository.updateSessionAuthCalled, "Should update session auth via UserSessionRepository")
        XCTAssertEqual(mockUserSessionRepository.lastUpdatedSessionAuth, "old-auth-hash-from-ud",
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
        XCTAssertFalse(mockUserSessionRepository.updateSessionAuthCalled,
                       "Should NOT update session auth on fresh install")
    }

    func testAlreadyMigrated_AuthNotResaved() {
        mockPreferences.mockFirstInstall = true
        mockPreferences.mockUserDefaultsSessionAuth = nil

        repository.runMigrations()

        XCTAssertFalse(mockUserSessionRepository.updateSessionAuthCalled,
                       "Should NOT update session auth if UD is empty")
        XCTAssertFalse(mockPreferences.clearUserDefaultsSessionAuthCalled,
                       "Should NOT clear UD if there was nothing to migrate")
    }
}
