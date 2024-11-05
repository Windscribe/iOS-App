//
//  PushNotificationManagerV2Impl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-10.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

class PushNotificationManagerV2Impl: PushNotificationManagerV2 {
    let notification: BehaviorSubject<PushNotificationPayload?> = BehaviorSubject(value: nil)
    let vpnManager: VPNManager
    let session: SessionManagerV2
    let logger: FileLogger

    init(vpnManager: VPNManager, session: SessionManagerV2, logger: FileLogger) {
        self.vpnManager = vpnManager
        self.session = session
        self.logger = logger
    }

    func addPushNotification(notificationPayload: PushNotificationPayload?) {
        notification.onNext(notificationPayload)
        if let notificationPayload = notificationPayload {
            handleSilentPushNotificationActions(payload: notificationPayload)
        }
    }

    func handleSilentPushNotificationActions(payload: PushNotificationPayload) {
        guard let type = payload.type else { return }
        switch type {
        case "disable_ondemand", "force_disconnect":
            vpnManager.disconnectActiveVPNConnection()
        case "account_downgraded":
            session.keepSessionUpdated()
        case "promo":
            notification.onNext(payload)
        default:
            return
        }
    }

    func askForPushNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted && error == nil {
                self.logger.logD(self, "Push Notification Permission granted, registering for remote notifications.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    NotificationCenter.default.post(Notification(name: Notifications.dismissPushNotificationPermissionPopup))
                }
            } else {
                self.logger.logD(self, "Push Notification Permission Not Granted. \(String(describing: error?.localizedDescription))")
            }
        }
    }

    func isAuthorizedForPushNotifications(completion: @escaping (_ result: Bool) -> Void) {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            completion(settings.authorizationStatus == .authorized)
        }
    }

    func setNotificationCount(count: Int) {
        DispatchQueue.main.async {
            UIApplication.shared.applicationIconBadgeNumber = count
        }
    }
}
