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
    var mockPreferences: MockPreferences!
    var mockLocalDatabase: MockLocalDatabase!
    var mockLocationListRepository: MockLocationListRepository!
    var repository: UserSessionRepository!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockPreferences = MockPreferences()
        mockLocalDatabase = MockLocalDatabase()
        mockLocationListRepository = MockLocationListRepository()

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }
        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }
        mockContainer.register(LocationListRepository.self) { _ in
            return self.mockLocationListRepository
        }

        mockContainer.register(UserSessionRepository.self) { r in
            return UserSessionRepositoryImpl(preferences: r.resolve(Preferences.self)!,
                                             localDatabase: r.resolve(LocalDatabase.self)!,
                                             locationListRepository: r.resolve(LocationListRepository.self)!)
        }.inObjectScope(.container)

        repository = mockContainer.resolve(UserSessionRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        repository = nil
        mockPreferences = nil
        mockLocalDatabase = nil
        mockLocationListRepository = nil
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
        XCTAssertEqual(repository.sessionModel, mockSession, "The session should now update to the new one")
        XCTAssertNil(repository.oldSessionModel, "Old Session should still be nil")

        await repository.update(session: mockSessionSecond)
        XCTAssertEqual(repository.sessionModel, mockSessionSecond, "The session should now update to the new one")
        XCTAssertEqual(repository.oldSessionModel, mockSession, "Old Session should now update to the first one")
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

    private func createMockSession() -> SessionModel {
        return SessionModel(
            sessionAuthHash: "test-auth-hash",
            username: "TestUser",
            userId: "123",
            isUserPro: true,
            isPremium: true,
            email: "test@example.com",
            emailStatus: true,
            billing: 1,
            alc: [],
            rebill: 0,
            billingPlanId: 1,
            trafficUsed: 0,
            trafficMax: 10737418240, // 10 GB
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: "2026-01-01",
            regDate: "2021",
            deviceId: "test-device",
            sipCount: 0,
            loc: "",
            locHash: "test-loc-hash",
            revisionHash: "test-revision"
        )
    }

    private func createMockSessionSecond() -> SessionModel {
        return SessionModel(
            sessionAuthHash: "test-auth-hash-second",
            username: "TestUser",
            userId: "123",
            isUserPro: false,
            isPremium: false,
            email: "test@example.com",
            emailStatus: true,
            billing: 0,
            alc: [],
            rebill: 0,
            billingPlanId: 0,
            trafficUsed: 0,
            trafficMax: 10737418240, // 10 GB
            status: 1,
            expiryDate: "",
            lastReset: "2026-01-01",
            regDate: "2021",
            deviceId: "test-device",
            sipCount: 0,
            loc: "",
            locHash: "test-loc-hash-second",
            revisionHash: "test-revision"
        )
    }
}
