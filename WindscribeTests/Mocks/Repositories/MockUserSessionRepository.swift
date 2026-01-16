//
//  MockUserSessionRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

@testable import Windscribe
import Foundation
import Combine

class MockUserSessionRepository: UserSessionRepository {

    // MARK: Properties
    var sessionAuth: String? = "mock-session-auth"
    var sessionModel: SessionModel?
    var oldSessionModel: SessionModel?
    var sessionModelSubject = CurrentValueSubject<SessionModel?, Never>(nil)

    // MARK: Tracking
    var getUpdatedUserCalled = false
    var loginCalled = false
    var updateCalled = false
    var lastLoginSession: Session?
    var lastUpdateSession: Session?

    // MARK: Mock Configuration

    var shouldThrowError = false
    var errorToThrow: Error = Errors.notDefined
    var sessionModelToReturn: SessionModel?

    // MARK: UserSessionRepository Protocol

    func update(session: Session) async {
        updateCalled = true
        self.oldSessionModel = self.sessionModel
        self.sessionModel = session.getModel()
        sessionModelSubject.send(sessionModel)
    }

    func clearSession() {
        sessionModel = nil
    }

    func canAccesstoProLocation() -> Bool {
        sessionModel?.isPremium ?? false
    }

    private func createMockSession() -> SessionModel {
        let mockSession = Session()
        mockSession.userId = "123"
        mockSession.username = "TestUser"
        mockSession.sessionAuthHash = sessionAuth ?? "mock-auth-hash"
        sessionModel = mockSession.getModel()
        return mockSession.getModel()
    }

    // MARK: Helper Methods

    func setMockSession(userId: String, username: String = "testuser", isPremium: Bool = true) {
        let mockSession = Session()
        mockSession.userId = userId
        mockSession.username = username
        mockSession.isPremium = isPremium
        self.sessionModel = mockSession.getModel()
    }

    func reset() {
        getUpdatedUserCalled = false
        loginCalled = false
        updateCalled = false
        lastLoginSession = nil
        lastUpdateSession = nil
        shouldThrowError = false
        errorToThrow = Errors.notDefined
    }

    func syncSession() async -> Bool {
        false
    }

    func clean() {

    }
}
