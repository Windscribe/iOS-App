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
    var lastUpdateSession: SessionModel?

    // MARK: Mock Configuration

    var shouldThrowError = false
    var errorToThrow: Error = Errors.notDefined
    var sessionModelToReturn: SessionModel?

    // MARK: UserSessionRepository Protocol

    func update(session: Windscribe.SessionModel) async {
        updateCalled = true
        lastUpdateSession = session
        self.oldSessionModel = self.sessionModel
        self.sessionModel = session
        sessionModelSubject.send(session)
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
        lastUpdateSession = nil
        shouldThrowError = false
        errorToThrow = Errors.notDefined
        sessionModel = nil
        oldSessionModel = nil
    }

    func syncSession() async -> Bool {
        false
    }

    func clean() {

    }
}
