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

    override func setUp() {
        super.setUp()
        mockContainer = Container()

        mockContainer.register(Preferences.self) { _ in
            return MockPreferences()
        }

        mockContainer.register(UserSessionRepository.self) { r in
            return UserSessionRepositoryImpl(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.container)

        repository = mockContainer.resolve(UserSessionRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        repository = nil
        super.tearDown()
    }

    // MARK: GetUpdatedUser Tests

    func test_updateSession() async {
        // Given
        let mockSession = createMockSessionModel()
        let mockSessionSecond = createMockSessionModelSecond()

        XCTAssertNil(repository.sessionModel, "Session should be nil at the beginning")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil at the beginning")

        await repository.update(sessionModel: mockSession)
        XCTAssertEqual(repository.sessionModel, mockSession, "The session should now update to the new one")
        XCTAssertNil(repository.oldSessionModel, "Old Session should still be nil")

        await repository.update(sessionModel: mockSessionSecond)
        XCTAssertEqual(repository.sessionModel, mockSessionSecond, "The session should now update to the new one")
        XCTAssertEqual(repository.oldSessionModel, mockSession, "Old Session should now update to the first one")
    }

    func test_clearSession() async {
        // Given
        let mockSession = createMockSessionModel()
        let mockSessionSecond = createMockSessionModelSecond()

        XCTAssertNil(repository.sessionModel, "Session should be nil at the beginning")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil at the beginning")

        await repository.update(sessionModel: mockSession)
        await repository.update(sessionModel: mockSessionSecond)
        XCTAssertNotNil(repository.sessionModel, "The session should not be nil after 2 updates")
        XCTAssertNotNil(repository.oldSessionModel, "Old Session should not be nil after 2 updates")

        repository.clearSession()
        XCTAssertNil(repository.sessionModel, "Session should be nil after clear")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil after clear")
    }

    func test_canAccesstoProLocation() async {
        // Given
        let mockSession = createMockSessionModel()
        let mockSessionSecond = createMockSessionModelSecond()

        await repository.update(sessionModel: mockSession)
        XCTAssertTrue(repository.canAccesstoProLocation(), "First Session IS pro and CAN Access to Pro Location")

        await repository.update(sessionModel: mockSessionSecond)
        XCTAssertFalse(repository.canAccesstoProLocation(), "Second Session is NOT pro and CANNOT Access to Pro Location")
    }

    // MARK: - Helper Methods

    private func createMockSessionModel() -> SessionModel {
        let session = Session()
        session.userId = "123"
        session.username = "TestUser"
        session.sessionAuthHash = "test-auth-hash"
        session.isPremium = true
        session.locHash = "test-loc-hash"
        return SessionModel(session: session)
    }

    private func createMockSessionModelSecond() -> SessionModel {
        let session = Session()
        session.userId = "123"
        session.username = "TestUser"
        session.sessionAuthHash = "test-auth-hash-second"
        session.isPremium = false
        session.locHash = "test-loc-hash-second"
        return SessionModel(session: session)
    }
}
