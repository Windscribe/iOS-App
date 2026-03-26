//
//  SceneDelegate.swift
//  WindscribeTV
//
//  Created by Anthony on 2026-03-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Swinject
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    private lazy var windowProvider: WindowProvider = Assembler.resolve(WindowProvider.self)
    private lazy var windowSetupService: WindowSetupService = Assembler.resolve(WindowSetupService.self)
    private lazy var lifecycleHandler: SceneLifecycleHandler = Assembler.resolve(SceneLifecycleHandler.self)

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

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
}
