//
//  MockSessionManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockSessionManager: SessionManager {
    var session: Session?

    // Track method calls
    var setSessionTimerCalled = false
    var listenForSessionChangesCalled = false
    var logoutUserCalled = false
    var checkForSessionChangeCalled = false
    var keepSessionUpdatedCalled = false

    init(session: Session? = nil) {
        self.session = session
    }

    func reset() {
        session = nil
        setSessionTimerCalled = false
        listenForSessionChangesCalled = false
        logoutUserCalled = false
        checkForSessionChangeCalled = false
        keepSessionUpdatedCalled = false
    }

    func setMockSession(userId: String, username: String = "testuser") {
        let mockSession = MockSession()
        mockSession.userId = userId
        mockSession.username = username
        self.session = mockSession
    }

    // MARK: - SessionManager Protocol Methods

    func setSessionTimer() {
        setSessionTimerCalled = true
    }

    func listenForSessionChanges() {
        listenForSessionChangesCalled = true
    }

    func logoutUser() {
        logoutUserCalled = true
        session = nil
    }

    func checkForSessionChange() {
        checkForSessionChangeCalled = true
    }

    func keepSessionUpdated() {
        keepSessionUpdatedCalled = true
    }

    func canAccesstoProLocation() -> Bool {
        return session?.isPremium ?? false
    }

    func getUpdatedSession() async throws -> Session {
        guard let session = session else {
            throw Errors.sessionIsInvalid
        }
        return session
    }

    func checkSession() async throws {

    }
}
