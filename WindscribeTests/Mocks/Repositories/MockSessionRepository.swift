//
//  MockSessionRepository.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockSessionRepository: SessionRepository {

    var session: Session?
    var keepSessionUpdatedTrigger = PassthroughSubject<Void, Never>()

    var isPremium: Bool {
        return session?.isPremium ?? false
    }

    var isUserPro: Bool {
        return session?.isUserPro ?? false
    }

    var email: String? {
        return session?.email
    }

    var userId: String {
        return session?.userId ?? ""
    }

    var sessionStatus: Int? {
        return session?.status
    }

    // Track method calls
    var updateSessionCalled = false
    var lastUpdatedSession: Session?
    var canAccesstoProLocationCalled = false
    var keepSessionUpdatedCalled = false

    init(session: Session? = nil) {
        self.session = session
    }

    func reset() {
        session = nil
        updateSessionCalled = false
        lastUpdatedSession = nil
        canAccesstoProLocationCalled = false
        keepSessionUpdatedCalled = false
    }

    func setMockSession(userId: String, username: String = "testuser", isPremium: Bool = true) {
        let mockSession = Session()
        mockSession.userId = userId
        mockSession.username = username
        mockSession.isPremium = isPremium
        self.session = mockSession
    }

    // MARK: - SessionRepository Protocol Methods

    func updateSession(_ value: Session?) {
        updateSessionCalled = true
        lastUpdatedSession = value
        session = value
    }

    func canAccesstoProLocation() -> Bool {
        canAccesstoProLocationCalled = true
        return isPremium
    }

    func keepSessionUpdated() {
        keepSessionUpdatedCalled = true
        keepSessionUpdatedTrigger.send()
    }
}
