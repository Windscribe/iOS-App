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
    var mockPreferences: MockPreferences!
    var mockSessionStore: MockSessionKeychainStore!
    var mockLogger: MockLogger!
    var repository: MigrationRepository!

    override func setUp() {
        super.setUp()
        mockLocalDatabase = MockLocalDatabase()
        mockPreferences = MockPreferences()
        mockSessionStore = MockSessionKeychainStore()
        mockLogger = MockLogger()

        repository = MigrationRepositoryImpl(
            localDatabase: mockLocalDatabase,
            preferences: mockPreferences,
            sessionStore: mockSessionStore,
            logger: mockLogger
        )
    }

    override func tearDown() {
        repository = nil
        mockLocalDatabase = nil
        mockPreferences = nil
        mockSessionStore = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        // Given/When
        let newRepository = MigrationRepositoryImpl(
            localDatabase: mockLocalDatabase,
            preferences: mockPreferences,
            sessionStore: mockSessionStore,
            logger: mockLogger
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
        let migrationRepo = MigrationRepositoryImpl(
            localDatabase: freshDatabase,
            preferences: mockPreferences,
            sessionStore: mockSessionStore,
            logger: mockLogger
        )

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

    // MARK: - Session Auth Migration Tests (Anthony's review scenarios)

    func testExistingUserDefaultsAuthHash_MigratedToKeychain_UDCleared() {
        // Given — existing user with auth hash in UserDefaults
        mockPreferences.mockFirstInstall = true
        mockPreferences.mockUserDefaultsSessionAuth = "old-auth-hash-from-ud"

        // When
        repository.runMigrations()

        // Then — auth hash should be saved to Keychain (via Preferences)
        XCTAssertTrue(mockPreferences.saveSessionAuthHashCalled, "Should save auth hash to Keychain")
        XCTAssertEqual(mockPreferences.lastSavedSessionAuth, "old-auth-hash-from-ud",
                       "Should migrate the exact auth hash value")
        // And UserDefaults should be cleared
        XCTAssertTrue(mockPreferences.clearUserDefaultsSessionAuthCalled,
                      "Should clear the old UserDefaults auth hash")
    }

    func testExistingRealmSession_MigratedToKeychain_RealmCleared() {
        // Given — existing user with a Realm Session object
        mockPreferences.mockFirstInstall = true
        let mockSession = MockSession()
        mockSession.configureLists()
        mockLocalDatabase.sessionSubject.send(mockSession)

        // When
        repository.runMigrations()

        // Then — session should be saved to Keychain store
        XCTAssertTrue(mockSessionStore.saveCalled, "Should save session to Keychain store")
        XCTAssertNotNil(mockSessionStore.storedSession, "Stored session should not be nil")
        XCTAssertEqual(mockSessionStore.storedSession?.username, "mockUsername",
                       "Should migrate the correct session data")
        // And Realm should be cleared
        XCTAssertTrue(mockLocalDatabase.clearSessionFromRealmCalled,
                      "Should clear the session from Realm after migration")
    }

    func testFreshInstall_StaleKeychainCleared() {
        // Given — fresh install (firstInstall == false), but Keychain has stale data
        mockPreferences.mockFirstInstall = false
        mockPreferences.sessionAuthToReturn = "stale-auth-hash"
        mockSessionStore.storedSession = SessionModel(from: MockSession())

        // When
        repository.runMigrations()

        // Then — stale Keychain entries should be cleared
        XCTAssertTrue(mockPreferences.clearSessionAuthCalled,
                      "Should clear stale session auth from Keychain")
        XCTAssertTrue(mockSessionStore.clearCalled,
                      "Should clear stale stored session from Keychain")
        // And nothing should be saved
        XCTAssertFalse(mockPreferences.saveSessionAuthHashCalled,
                       "Should NOT save auth hash on fresh install")
        XCTAssertFalse(mockSessionStore.saveCalled,
                       "Should NOT save session on fresh install")
    }

    func testAlreadyMigrated_NothingSquashed() {
        // Given — existing user, auth already in Keychain, session already in store
        mockPreferences.mockFirstInstall = true
        // No UserDefaults auth hash (already migrated or never had one)
        mockPreferences.mockUserDefaultsSessionAuth = nil
        // Session already in Keychain store
        let existingSession = SessionModel(from: MockSession())
        mockSessionStore.storedSession = existingSession

        // When
        repository.runMigrations()

        // Then — existing Keychain data should NOT be overwritten
        XCTAssertFalse(mockPreferences.saveSessionAuthHashCalled,
                       "Should NOT re-save auth hash if UD is empty")
        XCTAssertFalse(mockPreferences.clearUserDefaultsSessionAuthCalled,
                       "Should NOT clear UD if there was nothing to migrate")
        // Session store should be loaded (to check) but NOT saved over
        XCTAssertTrue(mockSessionStore.loadCalled, "Should check if session already exists")
        XCTAssertFalse(mockSessionStore.saveCalled,
                       "Should NOT overwrite existing Keychain session")
        XCTAssertEqual(mockSessionStore.storedSession?.username, existingSession.username,
                       "Existing session data should be preserved")
    }
}
