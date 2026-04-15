//
//  SceneLifecycleHandler.swift
//  Windscribe
//
//  Created by Anthony on 2026-03-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import UIKit

protocol SceneLifecycleHandler {
    func handleWillResignActive()
    func handleDidEnterBackground()
    func handleWillEnterForeground()
    func handleDidBecomeActive()
    func handleWillTerminate()
}

class SceneLifecycleHandlerImpl: SceneLifecycleHandler {
    private let logger: FileLogger
    private let preferences: Preferences
    private let protocolManager: ProtocolManagerType
    private let lifecycleManager: LifecycleManagerType
    private let pushNotificationManager: PushNotificationManager

    init(logger: FileLogger,
         preferences: Preferences,
         protocolManager: ProtocolManagerType,
         lifecycleManager: LifecycleManagerType,
         pushNotificationManager: PushNotificationManager) {
        self.logger = logger
        self.preferences = preferences
        self.protocolManager = protocolManager
        self.lifecycleManager = lifecycleManager
        self.pushNotificationManager = pushNotificationManager
    }

    func handleWillResignActive() {
        logger.logI("SceneLifecycleHandler", "App state changed to WillResignActive.")
    }

    func handleDidEnterBackground() {
        logger.logI("SceneLifecycleHandler", "App state changed to EnterBackground.")
        preferences.saveServerSettings(settings: WSNet.instance().currentPersistentSettings())
    }

    func handleWillEnterForeground() {
        logger.logI("SceneLifecycleHandler", "App state changed to WillEnterForeground.")
        protocolManager.resetGoodProtocol()
    }

    func handleDidBecomeActive() {
        logger.logI("SceneLifecycleHandler", "App state changed to Active.")
        registerForPushNotifications()
        lifecycleManager.appEnteredForeground()
    }

    func handleWillTerminate() {
        logger.logI("SceneLifecycleHandler", "App state changed to WillTerminate.")
        preferences.saveServerSettings(settings: WSNet.instance().currentPersistentSettings())
    }

    private func registerForPushNotifications() {
        pushNotificationManager.isAuthorizedForPushNotifications { result in
            if result {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}
