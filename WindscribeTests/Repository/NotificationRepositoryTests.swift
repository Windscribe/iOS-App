//
//  NotificationRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class NotificationRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: NotificationRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockLogger: MockLogger!
    var mockPushNotificationManager: MockPushNotificationManager!
    private var cancellables = Set<AnyCancellable>()

    // Test constants
    private let testPcpid = "test-pcpid-123"

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockLogger = MockLogger()
        mockPushNotificationManager = MockPushNotificationManager()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(PushNotificationManager.self) { _ in
            return self.mockPushNotificationManager
        }.inObjectScope(.container)

        // Register NotificationRepository
        mockContainer.register(NotificationRepository.self) { r in
            return NotificationRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                pushNotificationsManager: r.resolve(PushNotificationManager.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(NotificationRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockAPIManager.reset()
        mockPushNotificationManager.reset()
        mockContainer = nil
        repository = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockLogger = nil
        mockPushNotificationManager = nil
        super.tearDown()
    }

    // MARK: GetUpdatedNotifications Tests

    @MainActor
    func test_getUpdatedNotifications_success_shouldReturnNotifications() async {
        do {
            let notifications = try await repository.getUpdatedNotifications()

            XCTAssertTrue(mockAPIManager.getNotificationsCalled)
            XCTAssertTrue(mockLocalDatabase.saveNotificationsCalled)
            XCTAssertEqual(notifications.count, 3)
            XCTAssertEqual(notifications[0].id, 1)
            XCTAssertEqual(notifications[0].title, "Welcome to Windscribe")
            XCTAssertEqual(notifications[1].id, 2)
            XCTAssertEqual(notifications[1].title, "Special Offer")
            XCTAssertEqual(notifications[2].id, 3)
            XCTAssertEqual(notifications[2].title, "Server Maintenance")
        } catch {
            XCTFail("Expected success, but got error: \(error)")
        }
    }

    @MainActor
    func test_getUpdatedNotifications_withPcpid_shouldPassCorrectPcpid() async {
        // Set pcpid in push notification manager
        let userInfo: [String: AnyObject] = [
            "pcpid": testPcpid as AnyObject,
            "type": "promo" as AnyObject
        ]
        let payload = PushNotificationPayload(userInfo: userInfo)
        mockPushNotificationManager.notification.send(payload)

        do {
            _ = try await repository.getUpdatedNotifications()

            XCTAssertTrue(mockAPIManager.getNotificationsCalled)
            XCTAssertEqual(mockAPIManager.lastPcpid, testPcpid)
        } catch {
            XCTFail("Expected success, but got error: \(error)")
        }
    }

    @MainActor
    func test_getUpdatedNotifications_withoutPcpid_shouldPassEmptyString() async {
        // No pcpid set (nil payload)
        mockPushNotificationManager.notification.send(nil)

        do {
            _ = try await repository.getUpdatedNotifications()

            XCTAssertTrue(mockAPIManager.getNotificationsCalled)
            XCTAssertEqual(mockAPIManager.lastPcpid, "")
        } catch {
            XCTFail("Expected success, but got error: \(error)")
        }
    }

    @MainActor
    func test_getUpdatedNotifications_apiFailure_shouldThrowError() async {
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noDataReceived

        do {
            _ = try await repository.getUpdatedNotifications()
            XCTFail("Expected error, but got success")
        } catch {
            XCTAssertTrue(mockAPIManager.getNotificationsCalled)
            XCTAssertFalse(mockLocalDatabase.saveNotificationsCalled)
            XCTAssertTrue(error is Errors)
        }
    }

    @MainActor
    func test_getUpdatedNotifications_emptyNotifications_shouldReturnEmptyArray() async {
        // Create empty notification list
        let jsonData = SampleDataNotifications.emptyNotificationListJSON.data(using: .utf8)!
        let emptyNoticeList = try! JSONDecoder().decode(NoticeList.self, from: jsonData)
        mockAPIManager.noticeListToReturn = emptyNoticeList

        do {
            let notifications = try await repository.getUpdatedNotifications()

            XCTAssertTrue(mockAPIManager.getNotificationsCalled)
            XCTAssertTrue(mockLocalDatabase.saveNotificationsCalled)
            XCTAssertEqual(notifications.count, 0)
        } catch {
            XCTFail("Expected success, but got error: \(error)")
        }
    }

    @MainActor
    func test_getUpdatedNotifications_shouldSaveToLocalDatabase() async {
        do {
            let notifications = try await repository.getUpdatedNotifications()

            XCTAssertTrue(mockLocalDatabase.saveNotificationsCalled)
            XCTAssertEqual(mockLocalDatabase.notificationsToReturn?.count, notifications.count)
        } catch {
            XCTFail("Expected success, but got error: \(error)")
        }
    }

    // MARK: LoadNotifications Tests

    @MainActor
    func test_loadNotifications_success_shouldNotThrow() async {
        await repository.loadNotifications()

        XCTAssertTrue(mockAPIManager.getNotificationsCalled)
        XCTAssertTrue(mockLocalDatabase.saveNotificationsCalled)
    }

    @MainActor
    func test_loadNotifications_apiFailure_shouldNotThrow() async {
        // loadNotifications should handle errors gracefully
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noDataReceived

        await repository.loadNotifications()

        XCTAssertTrue(mockAPIManager.getNotificationsCalled)
        XCTAssertFalse(mockLocalDatabase.saveNotificationsCalled)
        // Should not crash or throw
    }

    // MARK: Reactive notices Subject Tests

    func test_notices_shouldEmitWhenDatabaseChanges() async {
        let expectation = self.expectation(description: "Notices emitted")

        // Subscribe to notices
        repository.notices
            .dropFirst() // Skip initial empty value
            .sink { notices in
                XCTAssertEqual(notices.count, 2)
                XCTAssertEqual(notices[0].id, 1)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Simulate database update
        let jsonData = SampleDataNotifications.singleNotificationListJSON.data(using: .utf8)!
        let noticeList = try! JSONDecoder().decode(NoticeList.self, from: jsonData)
        let noticesArray = Array(noticeList.notices)

        // Append one more to make it 2
        let secondNotice = Notice()
        secondNotice.id = 2
        secondNotice.title = "Second Notification"
        secondNotice.message = "Test"
        secondNotice.date = 1697530800

        mockLocalDatabase.notificationsSubject.onNext([noticesArray[0], secondNotice])

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_notices_initialValue_shouldBeEmpty() async {
        let expectation = self.expectation(description: "Initial value emitted")

        repository.notices
            .sink { notices in
                XCTAssertEqual(notices.count, 0)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func test_notices_shouldReactToMultipleUpdates() async {
        var emissionCount = 0
        let expectation = self.expectation(description: "Multiple emissions")

        repository.notices
            .sink { notices in
                emissionCount += 1
                if emissionCount == 3 { // Initial + 2 updates
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // First update
        mockLocalDatabase.notificationsSubject.onNext([Notice()])

        // Second update
        let notice1 = Notice()
        notice1.id = 1
        let notice2 = Notice()
        notice2.id = 2
        mockLocalDatabase.notificationsSubject.onNext([notice1, notice2])

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(emissionCount, 3)
    }

    // MARK: Integration Tests

    @MainActor
    func test_fullFlow_fetchAndReactiveUpdate() async {
        let expectation = self.expectation(description: "Reactive update after fetch")

        // Subscribe to notices
        repository.notices
            .dropFirst() // Skip initial empty
            .sink { notices in
                XCTAssertEqual(notices.count, 3)
                XCTAssertEqual(notices[0].title, "Welcome to Windscribe")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Fetch notifications (which saves to database and triggers reactive chain)
        do {
            _ = try await repository.getUpdatedNotifications()
        } catch {
            XCTFail("Fetch failed: \(error)")
        }

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    @MainActor
    func test_loadNotifications_shouldTriggerReactiveChain() async {
        let expectation = self.expectation(description: "Reactive update from loadNotifications")

        // Subscribe to notices
        repository.notices
            .dropFirst() // Skip initial empty
            .sink { notices in
                XCTAssertEqual(notices.count, 3)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // Load notifications
        await repository.loadNotifications()

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: Edge Cases

    @MainActor
    func test_concurrentFetches_shouldHandleGracefully() async {
        // Simulate multiple concurrent fetches
        async let fetch1 = repository.getUpdatedNotifications()
        async let fetch2 = repository.getUpdatedNotifications()
        async let fetch3 = repository.getUpdatedNotifications()

        do {
            let results = try await [fetch1, fetch2, fetch3]
            XCTAssertEqual(results.count, 3)
            XCTAssertTrue(mockAPIManager.getNotificationsCalled)
        } catch {
            XCTFail("Concurrent fetches failed: \(error)")
        }
    }

    @MainActor
    func test_notificationWithAction_shouldPreserveActionData() async {
        // Use notification list with action
        let jsonData = SampleDataNotifications.notificationWithPcpidJSON.data(using: .utf8)!
        let noticeList = try! JSONDecoder().decode(NoticeList.self, from: jsonData)
        mockAPIManager.noticeListToReturn = noticeList

        do {
            let notifications = try await repository.getUpdatedNotifications()

            XCTAssertEqual(notifications.count, 1)
            XCTAssertNotNil(notifications[0].action)
            XCTAssertEqual(notifications[0].action?.pcpid, "test-pcpid-123")
            XCTAssertEqual(notifications[0].action?.promoCode, "TESTCODE")
            XCTAssertEqual(notifications[0].action?.label, "Claim Now")
        } catch {
            XCTFail("Expected success, but got error: \(error)")
        }
    }
}
