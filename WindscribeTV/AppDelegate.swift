//
//  AppDelegate.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import Swinject

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private lazy var preferences: Preferences = {
        return Assembler.resolve(Preferences.self)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        setApplicationWindow()
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    /**
     Prepares application window and launches first view controller
     */
    func setApplicationWindow() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = self.window else { return }
        window.backgroundColor = UIColor.black
        // Authenticated user
        if preferences.userSessionAuth() != nil {
            let mainViewController = Assembler.resolve(MainViewController.self)

            // mainViewController.appJustStarted = true
           // let viewController = UINavigationController(rootViewController: mainViewController)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.window?.rootViewController = mainViewController
            }, completion: nil)
        } else {
            let welcomeVC = Assembler.resolve(WelcomeViewController.self)
            let viewController = UINavigationController(rootViewController: welcomeVC)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.window?.rootViewController = viewController
            }, completion: nil)
        }
//        openPreferences()
        self.window?.makeKeyAndVisible()
    }
}
