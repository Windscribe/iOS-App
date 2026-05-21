//
//  PushNotificationManaging.swift
//  Windscribe
//
//  Created by Andre Fonseca on 14/05/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import UserNotifications

protocol PushNotificationManaging: Sendable {
    func askForPushNotificationPermission()

    /// Routes a "push notification settings" tap: if the OS has already made a
    /// decision (authorized/denied), open iOS Settings; otherwise prompt.
    /// Encapsulated here so feature view models stay free of `UIKit` /
    /// `UserNotifications` imports.
    @MainActor func handleSettingsTap() async
}

/// Adapter wrapping the legacy `PushNotificationManager`.
final class LegacyPushNotificationManager: PushNotificationManaging, Sendable {
    private let legacy: PushNotificationManager

    init(legacy: PushNotificationManager) {
        self.legacy = legacy
    }

    func askForPushNotificationPermission() {
        legacy.askForPushNotificationPermission()
    }

    @MainActor
    func handleSettingsTap() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .denied:
            if let url = URL(string: UIApplication.openSettingsURLString) {
                await UIApplication.shared.open(url)
            }
        case .notDetermined:
            legacy.askForPushNotificationPermission()
        default:
            break
        }
    }
}
