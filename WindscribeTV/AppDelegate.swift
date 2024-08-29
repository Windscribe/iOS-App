//
//  AppDelegate.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import UIKit
import Swinject
import RxSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    private lazy var customConfigRepository: CustomConfigRepository = {
        return Assembler.resolve(CustomConfigRepository.self)
    }()
    let disposeBag = DisposeBag()
    private lazy var apiManager: APIManager = {
        return Assembler.resolve(APIManager.self)
    }()
    private lazy var preferences: Preferences = {
        return Assembler.resolve(Preferences.self)
    }()
    private lazy var logger: FileLogger = {
        return Assembler.resolve(FileLogger.self)
    }()
    private lazy var vpnManager: VPNManager = {
        return Assembler.resolve(VPNManager.self)
    }()
    private lazy var localDatabase: LocalDatabase = {
        return Assembler.resolve(LocalDatabase.self)
    }()
    private lazy var purchaseManager: InAppPurchaseManager = {
        return Assembler.resolve(InAppPurchaseManager.self)
    }()
    private lazy var latencyRepository: LatencyRepository = {
        return Assembler.resolve(LatencyRepository.self)
    }()
    private lazy var languageManager: LanguageManagerV2 = {
        return Assembler.resolve(LanguageManagerV2.self)
    }()
    private lazy var pushNotificationManager: PushNotificationManagerV2 = {
        return Assembler.resolve(PushNotificationManagerV2.self)
    }()
    private lazy var themeManager: ThemeManager = {
        return Assembler.resolve(ThemeManager.self)
    }()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        localDatabase.migrate()
        logger.logDeviceInfo()
        languageManager.setAppLanguage()
        vpnManager.setup { [self] in
            recordInstallIfFirstLoad()
            //registerForPushNotifications()
            resetCountryOverrideForServerList()
            purchaseManager.verifyPendingTransaction()
            latencyRepository.loadLatency()
            latencyRepository.loadCustomConfigLatency().subscribe(on: MainScheduler.asyncInstance).subscribe(onCompleted: {}, onError: { _ in}).disposed(by: disposeBag)
            setApplicationWindow()
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
        return true

    }
    /**
     Records app install.
     */
    private func recordInstallIfFirstLoad() {
        if preferences.getFirstInstall() == false {
            preferences.saveFirstInstall(bool: true)
            apiManager.recordInstall(platform: "tvos").subscribe(onSuccess: { _ in
                self.logger.logD(self, "Successfully recorded new install.")
            }, onFailure: { error in
                self.logger.logE(self, "Failed to record new install: \(error)")
            }).disposed(by: disposeBag)
        }
    }

    /**
     If vpn state is disconnected on app launch reset country override for the server list.
     */
    private func resetCountryOverrideForServerList() {
        if vpnManager.connectionStatus() == .disconnected {
            preferences.saveCountryOverrride(value: nil)
        }
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
            let viewController = UINavigationController(rootViewController: mainViewController)
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
