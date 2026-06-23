//
//  SceneLifecycleHandler.swift
//  Windscribe
//
//  Created by Anthony on 2026-03-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Swinject
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

    // .container singleton: resolve .userScope deps live so they can't go stale across a userScope reset.
    private var protocolManager: ProtocolManagerType { Assembler.resolve(ProtocolManagerType.self) }
    private var lifecycleManager: LifecycleManagerType { Assembler.resolve(LifecycleManagerType.self) }
    private var pushNotificationManager: PushNotificationManager { Assembler.resolve(PushNotificationManager.self) }

    init(logger: FileLogger,
         preferences: Preferences) {
        self.logger = logger
        self.preferences = preferences
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
