//
//  MockNotificationRepository.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockNotificationRepository: NotificationRepository {

    // Protocol Properties
    var notices = CurrentValueSubject<[NoticeModel], Never>([])
    var readNotices = CurrentValueSubject<[Int], Never>([])

    // Mock Configuration
    var shouldThrowError = false
    var errorToThrow: Error = Errors.notDefined

    var mockNotices: [NoticeModel] = []
    var mockReadNotices: [Int] = []

    // Tracking
    var getUpdatedNotificationsCalled = false
    var loadNotificationsCalled = false
    var readNoticeCalled = false
    var lastReadNoticeId: Int?

    // NotificationRepository Implementation

    func getUpdatedNotifications() async throws -> [NoticeModel] {
        getUpdatedNotificationsCalled = true

        if shouldThrowError {
            throw errorToThrow
        }

        notices.send(mockNotices)
        return mockNotices
    }

    func loadNotifications() async {
        loadNotificationsCalled = true
        notices.send(mockNotices)
    }

    func readNotice(with id: Int) {
        readNoticeCalled = true
        lastReadNoticeId = id

        if !mockReadNotices.contains(id) {
            mockReadNotices.append(id)
            readNotices.send(mockReadNotices)
        }
    }

    // MARK: Helper Methods

    func reset() {
        notices.send([])
        readNotices.send([])
        shouldThrowError = false
        errorToThrow = Errors.notDefined
        mockNotices = []
        mockReadNotices = []
        getUpdatedNotificationsCalled = false
        loadNotificationsCalled = false
        readNoticeCalled = false
        lastReadNoticeId = nil
    }
}
