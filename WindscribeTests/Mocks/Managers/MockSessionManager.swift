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
    var checkSessionCalled = false

    init(session: Session? = nil) {
        self.session = session
    }

    func reset() {
        session = nil
        setSessionTimerCalled = false
        listenForSessionChangesCalled = false
        logoutUserCalled = false
        checkForSessionChangeCalled = false
        checkSessionCalled = false
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

    func checkSession() async throws {
        checkSessionCalled = true
        guard session != nil else {
            throw Errors.sessionIsInvalid
        }
    }
}
