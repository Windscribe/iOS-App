//
//  ShakeDataRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class ShakeDataRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: ShakeDataRepository!
    var mockAPIManager: MockAPIManager!
    var mockSessionRepository: MockSessionRepository!
    private var cancellables = Set<AnyCancellable>()

    // Test constants
    private let testScore = 150
    private let testUserId = "test-user-123"
    private let testUsername = "testuser"

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockSessionRepository = MockSessionRepository()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(SessionRepository.self) { _ in
            return self.mockSessionRepository
        }.inObjectScope(.container)

        // Register ShakeDataRepository
        mockContainer.register(ShakeDataRepository.self) { r in
            return ShakeDataRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                sessionRepository: r.resolve(SessionRepository.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(ShakeDataRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockAPIManager.reset()
        mockSessionRepository.reset()
        mockContainer = nil
        repository = nil
        mockAPIManager = nil
        mockSessionRepository = nil
        super.tearDown()
    }

    // MARK: - getLeaderboardScores Tests

    func test_getLeaderboardScores_success_shouldReturnScores() {
        let expectation = self.expectation(description: "Get leaderboard scores")

        repository.getLeaderboardScores()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { scores in
                XCTAssertTrue(self.mockAPIManager.getLeaderboardCalled)
                XCTAssertEqual(scores.count, 3)
                XCTAssertEqual(scores[0].score, 100)
                XCTAssertEqual(scores[0].user, "player1")
                XCTAssertFalse(scores[0].you)
                XCTAssertEqual(scores[1].score, 90)
                XCTAssertEqual(scores[1].user, "player2")
                XCTAssertTrue(scores[1].you)
                XCTAssertEqual(scores[2].score, 80)
                XCTAssertEqual(scores[2].user, "player3")
                XCTAssertFalse(scores[2].you)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_getLeaderboardScores_apiFailure_shouldReturnError() {
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noDataReceived

        let expectation = self.expectation(description: "Get leaderboard scores failure")

        repository.getLeaderboardScores()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertTrue(self.mockAPIManager.getLeaderboardCalled)
                    XCTAssertTrue(error is Errors)
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected error, but got success")
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_getLeaderboardScores_emptyLeaderboard_shouldReturnEmptyArray() {
        // Create empty leaderboard
        let jsonData = SampleDataLeaderboard.emptyLeaderboardJSON.data(using: .utf8)!
        let emptyLeaderboard = try! JSONDecoder().decode(Leaderboard.self, from: jsonData)
        mockAPIManager.mockLeaderboard = emptyLeaderboard

        let expectation = self.expectation(description: "Get empty leaderboard")

        repository.getLeaderboardScores()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { scores in
                XCTAssertTrue(self.mockAPIManager.getLeaderboardCalled)
                XCTAssertEqual(scores.count, 0)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - recordShakeForDataScore Tests

    func test_recordShakeForDataScore_success_shouldReturnMessage() {
        // Set up valid session
        mockSessionRepository.setMockSession(userId: testUserId, username: testUsername)

        let expectation = self.expectation(description: "Record score success")

        repository.recordShakeForDataScore(score: testScore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { message in
                XCTAssertTrue(self.mockAPIManager.recordScoreCalled)
                XCTAssertEqual(self.mockAPIManager.lastRecordedScore, self.testScore)
                XCTAssertEqual(self.mockAPIManager.lastRecordedUserId, self.testUserId)
                XCTAssertEqual(message, "Score recorded successfully")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_recordShakeForDataScore_invalidSession_shouldReturnError() {
        // No session set (session is nil)
        mockSessionRepository.session = nil

        let expectation = self.expectation(description: "Record score invalid session")

        repository.recordShakeForDataScore(score: testScore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertFalse(self.mockAPIManager.recordScoreCalled)
                    XCTAssertTrue(error is Errors)
                    if let errors = error as? Errors {
                        XCTAssertEqual(errors, Errors.sessionIsInvalid)
                    }
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected error, but got success")
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_recordShakeForDataScore_apiFailure_shouldReturnError() {
        // Set up valid session
        mockSessionRepository.setMockSession(userId: testUserId, username: testUsername)

        // Configure API to fail
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noDataReceived

        let expectation = self.expectation(description: "Record score API failure")

        repository.recordShakeForDataScore(score: testScore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTAssertTrue(self.mockAPIManager.recordScoreCalled)
                    XCTAssertTrue(error is Errors)
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected error, but got success")
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_recordShakeForDataScore_zeroScore_shouldRecordSuccessfully() {
        mockSessionRepository.setMockSession(userId: testUserId, username: testUsername)

        let expectation = self.expectation(description: "Record zero score")

        repository.recordShakeForDataScore(score: 0)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { message in
                XCTAssertTrue(self.mockAPIManager.recordScoreCalled)
                XCTAssertEqual(self.mockAPIManager.lastRecordedScore, 0)
                XCTAssertEqual(message, "Score recorded successfully")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_recordShakeForDataScore_highScore_shouldRecordSuccessfully() {
        mockSessionRepository.setMockSession(userId: testUserId, username: testUsername)

        let highScore = 9999

        let expectation = self.expectation(description: "Record high score")

        repository.recordShakeForDataScore(score: highScore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { message in
                XCTAssertTrue(self.mockAPIManager.recordScoreCalled)
                XCTAssertEqual(self.mockAPIManager.lastRecordedScore, highScore)
                XCTAssertEqual(message, "Score recorded successfully")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_recordShakeForDataScore_customAPIMessage_shouldReturnCustomMessage() {
        mockSessionRepository.setMockSession(userId: testUserId, username: testUsername)

        // Set custom API message
        let jsonData = SampleDataLeaderboard.apiMessageCustomJSON.data(using: .utf8)!
        let customMessage = try! JSONDecoder().decode(APIMessage.self, from: jsonData)
        mockAPIManager.mockAPIMessage = customMessage

        let expectation = self.expectation(description: "Record score custom message")

        repository.recordShakeForDataScore(score: testScore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { message in
                XCTAssertEqual(message, "New high score!")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - updateCurrentScore Tests

    func test_updateCurrentScore_shouldUpdateScore() {
        // Initial score should be 0
        XCTAssertEqual(repository.currentScore, 0)

        // Update score
        repository.updateCurrentScore(testScore)

        // Verify score is updated
        XCTAssertEqual(repository.currentScore, testScore)
    }

    func test_updateCurrentScore_multipleUpdates_shouldRetainLatestScore() {
        XCTAssertEqual(repository.currentScore, 0)

        repository.updateCurrentScore(50)
        XCTAssertEqual(repository.currentScore, 50)

        repository.updateCurrentScore(100)
        XCTAssertEqual(repository.currentScore, 100)

        repository.updateCurrentScore(75)
        XCTAssertEqual(repository.currentScore, 75)
    }

    func test_updateCurrentScore_zeroScore_shouldUpdate() {
        repository.updateCurrentScore(testScore)
        XCTAssertEqual(repository.currentScore, testScore)

        repository.updateCurrentScore(0)
        XCTAssertEqual(repository.currentScore, 0)
    }

    func test_updateCurrentScore_negativeScore_shouldUpdate() {
        // Edge case: negative scores (though not expected in real usage)
        repository.updateCurrentScore(-10)
        XCTAssertEqual(repository.currentScore, -10)
    }

    // MARK: - Integration Tests

    func test_fullGameFlow_shouldWorkCorrectly() {
        // Simulate full game flow: update score, then record it
        mockSessionRepository.setMockSession(userId: testUserId, username: testUsername)

        // Step 1: Update current score (like during game)
        repository.updateCurrentScore(testScore)
        XCTAssertEqual(repository.currentScore, testScore)

        // Step 2: Record score to API
        let expectation = self.expectation(description: "Full game flow")

        repository.recordShakeForDataScore(score: repository.currentScore)
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { message in
                XCTAssertEqual(self.mockAPIManager.lastRecordedScore, self.testScore)
                XCTAssertEqual(message, "Score recorded successfully")
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    func test_concurrentAPIRequests_shouldHandleGracefully() {
        mockSessionRepository.setMockSession(userId: testUserId, username: testUsername)

        let expectation1 = self.expectation(description: "Get leaderboard")
        let expectation2 = self.expectation(description: "Record score")

        // Call both API methods concurrently
        repository.getLeaderboardScores()
            .sink(receiveCompletion: { _ in },
                  receiveValue: { scores in
                XCTAssertEqual(scores.count, 3)
                expectation1.fulfill()
            })
            .store(in: &cancellables)

        repository.recordShakeForDataScore(score: testScore)
            .sink(receiveCompletion: { _ in },
                  receiveValue: { message in
                XCTAssertEqual(message, "Score recorded successfully")
                expectation2.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 2.0, handler: nil)

        XCTAssertTrue(mockAPIManager.getLeaderboardCalled)
        XCTAssertTrue(mockAPIManager.recordScoreCalled)
    }

    // MARK: - Property Access Tests

    func test_currentScore_initialValue_shouldBeZero() {
        XCTAssertEqual(repository.currentScore, 0)
    }

    func test_currentScore_readAfterUpdate_shouldReturnUpdatedValue() {
        repository.updateCurrentScore(999)
        XCTAssertEqual(repository.currentScore, 999)

        let currentScore = repository.currentScore
        XCTAssertEqual(currentScore, 999)
    }
}
