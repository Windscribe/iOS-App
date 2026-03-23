//
//  SceneDelegate.swift
//  Windscribe
//
//  Created by Anthony on 2026-03-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Swinject
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private lazy var windowProvider: WindowProvider = Assembler.resolve(WindowProvider.self)
    private lazy var windowSetupService: WindowSetupService = Assembler.resolve(WindowSetupService.self)
    private lazy var lifecycleHandler: SceneLifecycleHandler = Assembler.resolve(SceneLifecycleHandler.self)
    private lazy var actionHandler: SceneActionHandler = Assembler.resolve(SceneActionHandler.self)

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // Store cold-launch values immediately as value types on WindowProvider.
        // LifecycleManager.handleShortcutLaunch() consumes these when sceneDidBecomeActive
        windowProvider.pendingURL = connectionOptions.urlContexts.first?.url
        windowProvider.pendingActivityType = connectionOptions.userActivities.first?.activityType

        if let shortcutType = connectionOptions.shortcutItem?.type {
            if shortcutType.contains("Notifications") {
                windowProvider.shortcutType = .notifications
            } else if shortcutType.contains("NetworkSecurity") {
                windowProvider.shortcutType = .networkSecurity
            }
        }

        let window = UIWindow(windowScene: windowScene)
        self.window = window
        windowProvider.sceneWindow = window
        windowSetupService.configureWindow(window)
    }

    func sceneWillResignActive(_ scene: UIScene) {
        lifecycleHandler.handleWillResignActive()
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        lifecycleHandler.handleDidEnterBackground()
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        lifecycleHandler.handleWillEnterForeground()
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        lifecycleHandler.handleDidBecomeActive()
    }

    func sceneDidDisconnect(_ scene: UIScene) {
        lifecycleHandler.handleWillTerminate()
    }

    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        guard let url = URLContexts.first?.url else { return }
        _ = actionHandler.handleURL(url)
    }

    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) {
        _ = actionHandler.handleUserActivity(userActivity)
    }

    func windowScene(_ windowScene: UIWindowScene,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        actionHandler.handleShortcutItem(shortcutItem)
        completionHandler(true)
    }
}
