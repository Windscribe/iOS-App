//
//  LivecycleManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 08/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import RxSwift

protocol LivecycleManagerType {
    var showNetworkSecurityTrigger: PublishSubject<Void> { get }
    var showNotificationsTrigger: PublishSubject<Void> { get }
    var becameActiveTrigger: PublishSubject<Void> { get }

    func onAppStart()
    func appEnteredForeground()
}

class LivecycleManager: LivecycleManagerType {
    let logger: FileLogger
    let sessionManager: SessionManagerV2
    let preferences: Preferences
    let vpnManager: VPNManager
    let connectivity: Connectivity
    let credentialsRepo: CredentialsRepository
    let notificationRepo: NotificationRepository

    let showNetworkSecurityTrigger = PublishSubject<Void>()
    let showNotificationsTrigger = PublishSubject<Void>()
    let becameActiveTrigger = PublishSubject<Void>()
    
    private var connectivityTestTimer: Timer?

    init(logger: FileLogger,
         sessionManager: SessionManagerV2,
         preferences: Preferences,
         vpnManager: VPNManager,
         connectivity: Connectivity,
         credentialsRepo: CredentialsRepository,
         notificationRepo: NotificationRepository) {
        self.logger = logger
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.vpnManager = vpnManager
        self.connectivity = connectivity
        self.credentialsRepo = credentialsRepo
        self.notificationRepo = notificationRepo
    }

    func onAppStart() {
        notificationRepo.loadNotifications()
    }

    func appEnteredForeground() {
        becameActiveTrigger.onNext(())
        //TODO:  I Don't think this is necessary as Ginder mentioned the process will just continue from where it was
        if vpnManager.isConnecting(), connectivity.internetConnectionAvailable() {
            logger.logD(self, "Recovery: App entered foreground while connecting. Will restart connection.")
            enableVPNConnection()
        }
        if (preferences.getConnectionCount() ?? 0) >= 1 {
            connectivityTestTimer?.invalidate()
            connectivityTestTimer = Timer.scheduledTimer(timeInterval: 1.0,
                                                         target: self,
                                                         selector: #selector(runConnectivityTest),
                                                         userInfo: nil,
                                                         repeats: false)
        }
        sessionManager.keepSessionUpdated()
        guard let lastNotificationTimestamp = preferences.getLastNotificationTimestamp() else {
            preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
            return
        }
        if Date().timeIntervalSince1970 - lastNotificationTimestamp >= 3600 {
            preferences.saveLastNotificationTimestamp(timeStamp: Date().timeIntervalSince1970)
            notificationRepo.loadNotifications()
        }
        credentialsRepo.updateServerConfig()
        handleShortcutLaunch()
    }

    private func handleShortcutLaunch() {
        LivecycleManager.self 
        let shortcut = (UIApplication.shared.delegate as? AppDelegate)?.shortcutType ?? .none
        (UIApplication.shared.delegate as? AppDelegate)?.shortcutType = ShortcutType.none
        if shortcut == .networkSecurity {
            showNetworkSecurityTrigger.onNext(())
        } else if shortcut == .notifications {
            showNotificationsTrigger.onNext(())
        }
    }
    
    private func enableVPNConnection() {
        
    }
    
    // TODO: VPN MANAGER
    @objc private func runConnectivityTest() {
        if vpnManager.isConnected() {
            vpnManager.runConnectivityTest(connectToAnotherNode: true, checkForIPAddressChange: false)
        }
    }
}
