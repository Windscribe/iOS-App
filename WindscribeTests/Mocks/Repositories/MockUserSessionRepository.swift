//
//  MockUserSessionRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockUserSessionRepository: UserSessionRepository {

    // MARK: Properties

    var sessionAuth: String? = "mock-session-auth"
    var user: User?

    // MARK: Tracking

    var getUpdatedUserCalled = false
    var loginCalled = false
    var updateCalled = false
    var lastLoginSession: Session?
    var lastUpdateSession: Session?

    // MARK: Mock Configuration

    var shouldThrowError = false
    var errorToThrow: Error = Errors.notDefined
    var userToReturn: User?

    // MARK: UserSessionRepository Protocol

    func getUpdatedUser() async throws -> User {
        getUpdatedUserCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        if let mockUser = userToReturn {
            self.user = mockUser
            return mockUser
        }

        // Return default mock user
        let mockSession = createMockSession()
        let mockUser = User(session: mockSession)
        self.user = mockUser
        return mockUser
    }

    func login(session: Session) {
        loginCalled = true
        lastLoginSession = session
        self.user = User(session: session)
    }

    func update(session: Session) {
        updateCalled = true
        lastUpdateSession = session
        self.user = User(session: session)
    }

    // MARK: Helper Methods

    func reset() {
        getUpdatedUserCalled = false
        loginCalled = false
        updateCalled = false
        lastLoginSession = nil
        lastUpdateSession = nil
        shouldThrowError = false
        errorToThrow = Errors.notDefined
        userToReturn = nil
        user = nil
    }

    private func createMockSession() -> Session {
        let mockSession = Session()
        mockSession.userId = "123"
        mockSession.username = "TestUser"
        mockSession.sessionAuthHash = sessionAuth ?? "mock-auth-hash"
        return mockSession
    }
}
