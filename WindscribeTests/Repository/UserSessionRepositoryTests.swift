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
        mockContainer.register(LocalDatabase.self) { _ in
            return MockLocalDatabase()
        }

        mockContainer.register(UserSessionRepository.self) { r in
            return UserSessionRepositoryImpl(preferences: r.resolve(Preferences.self)!,
                                             localDatabase: r.resolve(LocalDatabase.self)!)
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
        let mockSession = createMockSession()
        let mockSessionSecond = createMockSessionSecond()

        XCTAssertNil(repository.sessionModel, "Session should be nil at the beginning")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil at the beginning")

        await repository.update(session: mockSession)
        XCTAssertEqual(repository.sessionModel, mockSession.getModel(), "The session should now update to the new one")
        XCTAssertNil(repository.oldSessionModel, "Old Session should still be nil")

        await repository.update(session: mockSessionSecond)
        XCTAssertEqual(repository.sessionModel, mockSessionSecond.getModel(), "The session should now update to the new one")
        XCTAssertEqual(repository.oldSessionModel, mockSession.getModel(), "Old Session should now update to the first one")
    }

    func test_clearSession() async {
        // Given
        let mockSession = createMockSession()
        let mockSessionSecond = createMockSessionSecond()

        XCTAssertNil(repository.sessionModel, "Session should be nil at the beginning")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil at the beginning")

        await repository.update(session: mockSession)
        await repository.update(session: mockSessionSecond)
        XCTAssertNotNil(repository.sessionModel, "The session should not be nil after 2 updates")
        XCTAssertNotNil(repository.oldSessionModel, "Old Session should not be nil after 2 updates")

        repository.clearSession()
        XCTAssertNil(repository.sessionModel, "Session should be nil after clear")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil after clear")
    }

    func test_canAccesstoProLocation() async {
        // Given
        let mockSession = createMockSession()
        let mockSessionSecond = createMockSessionSecond()

        await repository.update(session: mockSession)
        XCTAssertTrue(repository.canAccesstoProLocation(), "First Session IS pro and CAN Access to Pro Location")

        await repository.update(session: mockSessionSecond)
        XCTAssertFalse(repository.canAccesstoProLocation(), "Second Session is NOT pro and CANNOT Access to Pro Location")
    }

    // MARK: - Helper Methods

    private func createMockSession() -> Session {
        let session = Session()
        session.userId = "123"
        session.username = "TestUser"
        session.sessionAuthHash = "test-auth-hash"
        session.isPremium = true
        session.locHash = "test-loc-hash"
        return session
    }

    private func createMockSessionSecond() -> Session {
        let session = Session()
        session.userId = "123"
        session.username = "TestUser"
        session.sessionAuthHash = "test-auth-hash-second"
        session.isPremium = false
        session.locHash = "test-loc-hash-second"
        return session
    }
}
