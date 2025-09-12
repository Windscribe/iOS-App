//
//  PushNotificationManagerImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-10.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Combine

protocol PushNotificationManager {
    func askForPushNotificationPermission()
    func handleSilentPushNotificationActions(payload: PushNotificationPayload)
    func addPushNotification(notificationPayload: PushNotificationPayload?)
    func setNotificationCount(count: Int)
    func isAuthorizedForPushNotifications(completion: @escaping (_ result: Bool) -> Void)
    var notification: CurrentValueSubject<PushNotificationPayload?, Never> { get }
}

class PushNotificationManagerImpl: PushNotificationManager {
    let notification: CurrentValueSubject<PushNotificationPayload?, Never> = CurrentValueSubject(nil)
    let vpnManager: VPNManager
    let session: SessionManager
    let logger: FileLogger

    init(vpnManager: VPNManager, session: SessionManager, logger: FileLogger) {
        self.vpnManager = vpnManager
        self.session = session
        self.logger = logger
    }

    func addPushNotification(notificationPayload: PushNotificationPayload?) {
        if let notificationPayload = notificationPayload {
            notification.send(notificationPayload)
            handleSilentPushNotificationActions(payload: notificationPayload)
        }
    }

    func handleSilentPushNotificationActions(payload: PushNotificationPayload) {
        guard let type = payload.type else { return }
        switch type {
        case "disable_ondemand", "force_disconnect":
            vpnManager.simpleDisableConnection()
        case "account_downgraded":
            session.keepSessionUpdated()
        case "promo":
            notification.send(payload)
        default:
            return
        }
    }

    func askForPushNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted && error == nil {
                self.logger.logD("PushNotificationManager", "Push Notification Permission granted, registering for remote notifications.")
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                self.logger.logE("PushNotificationManager", "Push Notification Permission Not Granted. \(String(describing: error?.localizedDescription))")
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
