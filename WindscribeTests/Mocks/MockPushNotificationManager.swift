//
//  MockPushNotificationManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockPushNotificationManager: PushNotificationManager {
    let notification = CurrentValueSubject<PushNotificationPayload?, Never>(nil)

    var askForPushNotificationPermissionCalled = false
    var handleSilentPushNotificationActionsCalled = false
    var addPushNotificationCalled = false
    var setNotificationCountCalled = false
    var lastNotificationCount: Int?

    func reset() {
        notification.send(nil)
        askForPushNotificationPermissionCalled = false
        handleSilentPushNotificationActionsCalled = false
        addPushNotificationCalled = false
        setNotificationCountCalled = false
        lastNotificationCount = nil
    }

    func askForPushNotificationPermission() {
        askForPushNotificationPermissionCalled = true
    }

    func handleSilentPushNotificationActions(payload: PushNotificationPayload) {
        handleSilentPushNotificationActionsCalled = true
    }

    func addPushNotification(notificationPayload: PushNotificationPayload?) {
        addPushNotificationCalled = true
        notification.send(notificationPayload)
    }

    func setNotificationCount(count: Int) {
        setNotificationCountCalled = true
        lastNotificationCount = count
    }

    func isAuthorizedForPushNotifications(completion: @escaping (_ result: Bool) -> Void) {
        completion(true)
    }
}
