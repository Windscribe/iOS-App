//
//  PushNotificationViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 22/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol PushNotificationViewModelType {
    func wasShown()
    func action()
    func cancel()
}

class PushNotificationViewModel: PushNotificationViewModelType {
    var logger: FileLogger!
    var pushNotificationsManager: PushNotificationManagerV2!

    init(logger: FileLogger!, pushNotificationsManager: PushNotificationManagerV2!) {
        self.logger = logger
        self.pushNotificationsManager = pushNotificationsManager
    }

    func wasShown() {
        logger.logD(self, "Displaying Push Notifications Popup View")
    }

    func action() {
        logger.logD(self, "Asking for push notification permission.")
        pushNotificationsManager.askForPushNotificationPermission()
    }

    func cancel() {
        NotificationCenter.default.post(Notification(name: Notifications.dismissPushNotificationPermissionPopup))
    }
}
