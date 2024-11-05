//
//  Notifications.swift
//  Windscribe
//
//  Created by Yalcin on 2019-04-29.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

enum Notifications {
    static let connectionFailed = Notification.Name(rawValue: "connection-failed")
    static let newNotificationToRead = Notification.Name(rawValue: "news-to-read")
    static let userPreferencesChanged = Notification.Name(rawValue: "user-preferences-changed")
    static let loadSession = Notification.Name(rawValue: "load-session")
    static let dismissPushNotificationPermissionPopup = Notification.Name(rawValue: "push-notification-permission-popup")
    static let userLoggedOut = Notification.Name(rawValue: "user-logged-out")
    static let connectToVPN = Notification.Name(rawValue: "connect-to-vpn")
    static let disconnectVPN = Notification.Name(rawValue: "disconnect-vpn")
    static let serverListOrderPrefChanged = Notification.Name(rawValue: "server-list-order-pref-changed")
    static let serverListLatencyTypeChanged = Notification.Name(rawValue: "server-list-latency-type-changed")
    static let reloadServerList = Notification.Name(rawValue: "reload-server-list")
    static let checkForNotifications = Notification.Name(rawValue: "check-for-notifications")
    static let configureBestLocation = Notification.Name(rawValue: "configure-best-location")
    static let reachabilityChanged = Notification.Name(rawValue: "reachability-changed")
    static let popoverDismissed = Notification.Name(rawValue: "popover-dismissed")
    static let showCustomConfigTab = Notification.Name(rawValue: "show-custom-config-tab")
    static let reloadTableViews = Notification.Name(rawValue: "reload-table-views")
    static let configureVPN = Notification.Name(rawValue: "configure-vpn")
    static let sessionUpdated = Notification.Name(rawValue: "session-updated")
    static let loadLastConnected = Notification.Name(rawValue: "load-last-connected")
}
