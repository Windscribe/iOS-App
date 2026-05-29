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
    var updateSessionAuthCalled = false
    var lastUpdatedSessionAuth: String?

    // MARK: Mock Configuration

    var shouldThrowError = false
    var errorToThrow: Error = Errors.notDefined
    var sessionModelToReturn: SessionModel?
    /// When non-nil, both `canAccesstoProLocation` overloads return this value
    /// instead of computing from the session model. Useful when tests exercise
    /// callers (e.g. BridgeApiRepository) that go through `locationId:` but the
    /// mock has no LocationListRepository to resolve the id.
    var mockCanAccessProLocation: Bool?

    // MARK: UserSessionRepository Protocol

    func update(session: Windscribe.SessionModel) async {
        updateCalled = true
        lastUpdateSession = session
        self.oldSessionModel = self.sessionModel
        self.sessionModel = session
        sessionModelSubject.send(session)
    }

    func updateSessionAuth(with sessionAuthHash: String?) {
        updateSessionAuthCalled = true
        lastUpdatedSessionAuth = sessionAuthHash
        sessionAuth = sessionAuthHash
    }

    func clearSession() {
        sessionModel = nil
    }

    func canAccesstoProLocation(location: LocationModel) -> Bool {
        if let override = mockCanAccessProLocation { return override }
        let isLocationALC = sessionModel?.alc.contains(location.shortName) ?? false
        let isUserPro = sessionModel?.isPremium ?? false
        return isLocationALC || isUserPro
    }

    func canAccesstoProLocation(locationId: Int) -> Bool {
        if let override = mockCanAccessProLocation { return override }
        return sessionModel?.isPremium ?? false
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
        updateSessionAuthCalled = false
        lastUpdatedSessionAuth = nil
        shouldThrowError = false
        errorToThrow = Errors.notDefined
        mockCanAccessProLocation = nil
        sessionModel = nil
        oldSessionModel = nil
    }

    func syncSession() async -> Bool {
        false
    }

    func clean() {

    }
}
