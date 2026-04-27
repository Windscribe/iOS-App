//
//  MockSessionManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockSessionManager: SessionManager {

    var sessionFetchInProgress: Bool = false

    var updateSessionTask: Task<Void, any Error>?

    var session: Session?

    var checkForDiscconectReasonTrigger = PassthroughSubject<Void, Never>()

    // Track method calls
    var keepSessionUpdatedCalled = false
    var setSessionTimerCalled = false
    var listenForSessionChangesCalled = false
    var logoutUserCalled = false
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

    func keepSessionUpdated() {
        keepSessionUpdatedCalled = true
    }

    func updateSession(force: Bool) async throws {
        updateSessionCalled = true
    }

    func updateSession(_ appleID: String, force: Bool) async throws {
        try await updateSession(force: force)
    }

    func updateSession() async throws {
        try await updateSession(force: false)
    }

    func updateSession(_ appleID: String) async throws {
        try await updateSession(force: false)
    }

    func login(auth: String) async throws {
        loginCalled = true
    }

    func updateFrom(session: Windscribe.SessionModel) async {
        updateFromCalled = true
    }
    func updateAfterLoginIn() async {}
}
