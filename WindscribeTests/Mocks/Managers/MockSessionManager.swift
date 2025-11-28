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
    var keepSessionUpdatedCalled = false
    var setSessionTimerCalled = false
    var listenForSessionChangesCalled = false
    var logoutUserCalled = false
    var checkForSessionChangeCalled = false
    var updateSessionCalled = false
    var loginCalled = false
    var updateFromCalled = false

    init(session: Session? = nil) {
        self.session = session
    }

    func reset() {
        session = nil
        keepSessionUpdatedCalled = false
        setSessionTimerCalled = false
        listenForSessionChangesCalled = false
        logoutUserCalled = false
        checkForSessionChangeCalled = false
        updateSessionCalled = false
        loginCalled = false
        updateFromCalled = false
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

    func updateSession() async throws {
        updateSessionCalled = true
    }

    func updateSession(_ appleID: String) async throws {
        try await updateSession()
    }

    func login(auth: String) async throws {
        loginCalled = true
    }

    func updateFrom(session: Windscribe.Session) {
        updateFromCalled = true
    }
}
