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

enum PushNotificationActionType: String, CaseIterable {
    case userDowngraded = "user_downgraded"
    case userExpired = "user_expired"
    case promo = "promo"

    init?(from string: String?) {
        guard let string = string,
              let type = PushNotificationActionType(rawValue: string) else {
            return nil
        }
        self = type
    }
}

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
    let sessionRepository: SessionRepository
    let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()

    init(vpnManager: VPNManager,
         sessionRepository: SessionRepository,
         logger: FileLogger) {
        self.vpnManager = vpnManager
        self.sessionRepository = sessionRepository
        self.logger = logger
    }

    func addPushNotification(notificationPayload: PushNotificationPayload?) {
        if let notificationPayload = notificationPayload {
            notification.send(notificationPayload)
            handleSilentPushNotificationActions(payload: notificationPayload)
        }
    }

    func handleSilentPushNotificationActions(payload: PushNotificationPayload) {
        guard let actionType = PushNotificationActionType(from: payload.type) else { return }
        switch actionType {
        case .userDowngraded:
            sessionRepository.keepSessionUpdated()
        case .userExpired:
            vpnManager.disconnectFromViewModel()
                .sink(receiveCompletion: { [weak self] _ in
                    self?.sessionRepository.keepSessionUpdated()
                }, receiveValue: { _ in })
                .store(in: &cancellables)
        case .promo:
            notification.send(payload)
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
