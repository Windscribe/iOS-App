//
//  UserSessionRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class UserSessionRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: UserSessionRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockPreferences: MockPreferences!
    var mockWgCredentials: MockWgCredentials!
    var mockLogger: MockLogger!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockPreferences = MockPreferences()
        mockWgCredentials = MockWgCredentials()
        mockLogger = MockLogger()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        mockContainer.register(WgCredentials.self) { _ in
            return self.mockWgCredentials
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        // Register UserSessionRepository
        mockContainer.register(UserSessionRepository.self) { r in
            return UserSessionRepositoryImpl(
                preferences: r.resolve(Preferences.self)!,
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                wgCredentials: r.resolve(WgCredentials.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        // Resolve repository from container
        repository = mockContainer.resolve(UserSessionRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockPreferences = nil
        mockWgCredentials = nil
        mockLogger = nil
        repository = nil
        super.tearDown()
    }

    // MARK: Init Tests

    func test_init_withSessionInDatabase_shouldSetUser() {
        // Given
        let mockSession = createMockSession()
        mockLocalDatabase.sessionSubject.send(mockSession)

        // When
        let repo = UserSessionRepositoryImpl(
            preferences: mockPreferences,
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase,
            wgCredentials: mockWgCredentials,
            logger: mockLogger
        )

        // Then
        XCTAssertNotNil(repo.user)
        XCTAssertEqual(repo.user?.username, mockSession.username)
    }

    func test_init_withoutSessionInDatabase_shouldHaveNilUser() {
        // Given
        mockLocalDatabase.sessionSubject.send(nil)

        // When
        let repo = UserSessionRepositoryImpl(
            preferences: mockPreferences,
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase,
            wgCredentials: mockWgCredentials,
            logger: mockLogger
        )

        // Then
        XCTAssertNil(repo.user)
    }

    // MARK: GetUpdatedUser Tests

    func test_getUpdatedUser_success_shouldReturnUser() async throws {
        // Given
        let mockSession = createMockSession()
        mockAPIManager.mockSession = mockSession

        // When
        let user = try await repository.getUpdatedUser()

        // Then
        XCTAssertNotNil(user)
        XCTAssertEqual(user.username, mockSession.username)
        XCTAssertEqual(user.locationHash, mockSession.locHash)
    }

    func test_getUpdatedUser_success_shouldSaveOldSession() async throws {
        // Given
        let mockSession = createMockSession()
        mockAPIManager.mockSession = mockSession
        mockLocalDatabase.saveOldSessionCalled = false

        // When
        _ = try await repository.getUpdatedUser()

        // Then
        XCTAssertTrue(mockLocalDatabase.saveOldSessionCalled, "Should save old session before updating")
    }

    func test_getUpdatedUser_success_shouldSaveNewSession() async throws {
        // Given
        let mockSession = createMockSession()
        mockSession.username = "UpdatedUser"
        mockAPIManager.mockSession = mockSession

        // When
        _ = try await repository.getUpdatedUser()

        // Then
        // Wait a bit for async operation
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        let savedSession = mockLocalDatabase.sessionSubject.value
        XCTAssertNotNil(savedSession)
        XCTAssertEqual(savedSession?.username, "UpdatedUser")
    }

    func test_getUpdatedUser_success_shouldUpdateRepositoryUser() async throws {
        // Given
        let mockSession = createMockSession()
        mockSession.username = "NewUser"
        mockAPIManager.mockSession = mockSession

        // When
        let user = try await repository.getUpdatedUser()

        // Then
        XCTAssertEqual(repository.user?.username, "NewUser")
        XCTAssertEqual(user.username, "NewUser")
    }

    func test_getUpdatedUser_apiFailure_shouldThrowError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.notDefined

        // When/Then
        do {
            _ = try await repository.getUpdatedUser()
            XCTFail("Should throw error when API fails")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_getUpdatedUser_multipleCalls_shouldReturnLatestUser() async throws {
        // Given
        let session1 = createMockSession()
        session1.username = "User1"
        let session2 = createMockSession()
        session2.username = "User2"

        // When - first call
        mockAPIManager.mockSession = session1
        let user1 = try await repository.getUpdatedUser()

        // Then
        XCTAssertEqual(user1.username, "User1")

        // When - second call
        mockAPIManager.mockSession = session2
        let user2 = try await repository.getUpdatedUser()

        // Then
        XCTAssertEqual(user2.username, "User2")
        XCTAssertEqual(repository.user?.username, "User2")
    }

    // MARK: Login Tests

    func test_login_shouldDeleteWgCredentials() {
        // Given
        let mockSession = createMockSession()
        mockWgCredentials.deleteCalled = false

        // When
        repository.login(session: mockSession)

        // Then
        XCTAssertTrue(mockWgCredentials.deleteCalled, "Should delete WireGuard credentials on login")
    }

    func test_login_shouldSaveSessionAuth() {
        // Given
        let mockSession = createMockSession()
        mockSession.sessionAuthHash = "test-auth-hash"

        // When
        repository.login(session: mockSession)

        // Then
        XCTAssertEqual(mockPreferences.lastSavedSessionAuth, "test-auth-hash")
    }

    func test_login_shouldSaveOldSession() async throws {
        // Given
        let mockSession = createMockSession()
        mockLocalDatabase.saveOldSessionCalled = false

        // When
        repository.login(session: mockSession)

        // Then
        try await Task.sleep(nanoseconds: 100_000_000) // Wait for Task to complete
        XCTAssertTrue(mockLocalDatabase.saveOldSessionCalled, "Should save old session on login")
    }

    func test_login_shouldSaveNewSession() async throws {
        // Given
        let mockSession = createMockSession()
        mockSession.username = "LoginUser"

        // When
        repository.login(session: mockSession)

        // Then
        try await Task.sleep(nanoseconds: 100_000_000) // Wait for Task to complete
        let savedSession = mockLocalDatabase.sessionSubject.value
        XCTAssertEqual(savedSession?.username, "LoginUser")
    }

    func test_login_shouldUpdateUser() async throws {
        // Given
        let mockSession = createMockSession()
        mockSession.username = "LoginUser"

        // When
        repository.login(session: mockSession)

        // Then
        try await Task.sleep(nanoseconds: 100_000_000) // Wait for Task to complete
        XCTAssertNotNil(repository.user)
        XCTAssertEqual(repository.user?.username, "LoginUser")
    }

    // MARK: Update Tests

    func test_update_shouldSaveSession() async throws {
        // Given
        let mockSession = createMockSession()
        mockSession.username = "UpdatedUser"

        // When
        repository.update(session: mockSession)

        // Then
        try await Task.sleep(nanoseconds: 100_000_000) // Wait for Task to complete
        let savedSession = mockLocalDatabase.sessionSubject.value
        XCTAssertEqual(savedSession?.username, "UpdatedUser")
    }

    func test_update_shouldUpdateUser() async throws {
        // Given
        let mockSession = createMockSession()
        mockSession.username = "UpdatedUser"

        // When
        repository.update(session: mockSession)

        // Then
        try await Task.sleep(nanoseconds: 100_000_000) // Wait for Task to complete
        XCTAssertNotNil(repository.user)
        XCTAssertEqual(repository.user?.username, "UpdatedUser")
    }

    func test_update_shouldNotDeleteWgCredentials() {
        // Given
        let mockSession = createMockSession()
        mockWgCredentials.deleteCalled = false

        // When
        repository.update(session: mockSession)

        // Then
        XCTAssertFalse(mockWgCredentials.deleteCalled, "Update should not delete WireGuard credentials")
    }

    func test_update_shouldNotSaveSessionAuth() {
        // Given
        let mockSession = createMockSession()
        mockSession.sessionAuthHash = "new-hash"
        mockPreferences.lastSavedSessionAuth = nil

        // When
        repository.update(session: mockSession)

        // Then
        XCTAssertNil(mockPreferences.lastSavedSessionAuth, "Update should not save session auth")
    }

    // MARK: SessionAuth Tests

    func test_sessionAuth_shouldReturnPreferencesValue() {
        // Given
        mockPreferences.sessionAuthToReturn = "test-session-auth"

        // When
        let sessionAuth = repository.sessionAuth

        // Then
        XCTAssertEqual(sessionAuth, "test-session-auth")
    }

    func test_sessionAuth_withNilPreference_shouldReturnNil() {
        // Given
        mockPreferences.sessionAuthToReturn = nil

        // When
        let sessionAuth = repository.sessionAuth

        // Then
        XCTAssertNil(sessionAuth)
    }

    // MARK: Integration Tests

    func test_loginThenGetUpdatedUser_shouldWorkCorrectly() async throws {
        // Given
        let loginSession = createMockSession()
        loginSession.username = "LoginUser"
        let updatedSession = createMockSession()
        updatedSession.username = "UpdatedUser"

        // When - login first
        repository.login(session: loginSession)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(repository.user?.username, "LoginUser")

        // When - get updated user
        mockAPIManager.mockSession = updatedSession
        let user = try await repository.getUpdatedUser()

        // Then
        XCTAssertEqual(user.username, "UpdatedUser")
        XCTAssertEqual(repository.user?.username, "UpdatedUser")
    }

    func test_loginThenUpdate_shouldWorkCorrectly() async throws {
        // Given
        let loginSession = createMockSession()
        loginSession.username = "LoginUser"
        let updateSession = createMockSession()
        updateSession.username = "UpdatedUser"

        // When - login first
        repository.login(session: loginSession)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(repository.user?.username, "LoginUser")

        // When - update
        repository.update(session: updateSession)
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(repository.user?.username, "UpdatedUser")
    }

    // MARK: Edge Cases

    func test_getUpdatedUser_withDifferentErrors_shouldThrowCorrectly() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.validationFailure

        // When/Then
        do {
            _ = try await repository.getUpdatedUser()
            XCTFail("Should throw error")
        } catch let error as Errors {
            XCTAssertEqual(error, Errors.validationFailure)
        } catch {
            XCTFail("Should throw Errors.validationFailure")
        }
    }

    func test_user_withNoLogin_shouldBeNil() {
        // Given - fresh repository with no session

        // When
        let user = repository.user

        // Then
        XCTAssertNil(user)
    }

    // MARK: - Helper Methods

    private func createMockSession() -> Session {
        let session = Session()
        session.userId = "123"
        session.username = "TestUser"
        session.sessionAuthHash = "test-auth-hash"
        session.isPremium = true
        session.locHash = "test-loc-hash"
        return session
    }
}
