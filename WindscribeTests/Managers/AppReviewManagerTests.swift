//
//  DefaultAppReviewManagerTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxBlocking
import Swinject
@testable import Windscribe
import XCTest

class AppReviewManagerTests: XCTestCase {

    private var reviewManager: AppReviewManaging!
    private var mockPreferences: MockPreferences!
    private var mockDatabase: MockLocalDatabase!
    private var mockLogger: MockLogger!

    override func setUp() {
        super.setUp()
        mockPreferences = MockPreferences()
        mockDatabase = MockLocalDatabase()
        mockLogger = MockLogger()
        reviewManager = AppReviewManager(
            preferences: mockPreferences,
            localDatabase: mockDatabase,
            logger: mockLogger)
    }

    override func tearDown() {
        reviewManager = nil
        mockPreferences = nil
        mockDatabase = nil
        mockLogger = nil

        super.tearDown()
    }

    func test_ShouldShowReviewRequest_AllCriteriaMet() {
        let mockSession = MockSession()
        mockSession.configureLists()
        mockSession.status = 1
        mockSession.trafficUsed = 2 * 1024 * 1024 * 1024 // 2GB in bytes

        mockPreferences.mockLoginDate = Date().addingTimeInterval(-3 * 24 * 60 * 60) // Logged in 3 days ago
        mockPreferences.mockLastReviewDate = Date().addingTimeInterval(-190 * 24 * 60 * 60) // Last review 190 days ago

        XCTAssertTrue(reviewManager.shouldShowReviewRequest(session: mockSession))
    }

    func test_ShouldNotShowReviewRequest_TooSoonAfterLastReview() {
        let mockSession = MockSession()
        mockSession.configureLists()
        mockSession.status = 1
        mockSession.trafficUsed = 2 * 1024 * 1024 * 1024

        mockPreferences.mockLoginDate = Date().addingTimeInterval(-3 * 24 * 60 * 60)
        mockPreferences.mockHasReviewed = true
        mockPreferences.mockLastReviewDate = Date().addingTimeInterval(-10 * 24 * 60 * 60) // Only 10 days ago

        XCTAssertFalse(reviewManager.shouldShowReviewRequest(session: mockSession))
    }

    func test_ShouldNotShowReviewRequest_NotEnoughDataUsed() {
        let mockSession = MockSession()
        mockSession.configureLists()
        mockSession.status = 1
        mockSession.trafficUsed = 500 * 1024 * 1024 // 500MB in bytes

        mockPreferences.mockLoginDate = Date().addingTimeInterval(-3 * 24 * 60 * 60)
        mockPreferences.mockLastReviewDate = Date().addingTimeInterval(-190 * 24 * 60 * 60)

        XCTAssertFalse(reviewManager.shouldShowReviewRequest(session: mockSession))
    }

    func test_ShouldNotShowReviewRequest_IfBannedUser() {
        let mockSession = MockSession()
        mockSession.configureLists()
        mockSession.status = 3 // Banned status
        mockSession.trafficUsed = 2 * 1024 * 1024 * 1024

        mockPreferences.mockLoginDate = Date().addingTimeInterval(-3 * 24 * 60 * 60)
        mockPreferences.mockLastReviewDate = Date().addingTimeInterval(-190 * 24 * 60 * 60)

        XCTAssertFalse(reviewManager.shouldShowReviewRequest(session: mockSession))
    }

    func test_RequestReviewIfAvailable_TriggersPromptReview() {
        let mockSession = MockSession()
        mockSession.configureLists()
        mockSession.status = 1
        mockSession.trafficUsed = 2 * 1024 * 1024 * 1024

        mockPreferences.mockLoginDate = Date().addingTimeInterval(-3 * 24 * 60 * 60)
        mockPreferences.mockLastReviewDate = Date().addingTimeInterval(-190 * 24 * 60 * 60)

        reviewManager.requestReviewIfAvailable(session: mockSession)

        let expectation = expectation(description: "Wait for 1 second")

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
            XCTAssertTrue(self.mockPreferences.getRateUsActionCompleted()) // Expect review flag to be set
            expectation.fulfill()
        }

        waitForExpectations(timeout: 1.0, handler: nil)
    }
}

