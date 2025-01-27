//
//  PushNotificationManagerV2.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-10.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol PushNotificationManagerV2 {
    func askForPushNotificationPermission()
    func handleSilentPushNotificationActions(payload: PushNotificationPayload)
    func addPushNotification(notificationPayload: PushNotificationPayload?)
    func setNotificationCount(count: Int)
    func isAuthorizedForPushNotifications(completion: @escaping (_ result: Bool) -> Void)
    var notification: BehaviorSubject<PushNotificationPayload?> { get }
}
