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
    private lazy var connectivity: Connectivity = {
        return Assembler.resolve(Connectivity.self)
    }()
    private lazy var connectionStateViewModel: ConnectionStateViewModelType = {
        return Assembler.resolve(ConnectionStateViewModelType.self)

    }()
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        localDatabase.migrate()
        logger.logDeviceInfo()
        languageManager.setAppLanguage()
        connectivity.refreshNetwork()
        vpnManager.setup { [self] in
            recordInstallIfFirstLoad()
            // registerForPushNotifications()
            resetCountryOverrideForServerList()
            purchaseManager.verifyPendingTransaction()
            latencyRepository.loadLatency()
            latencyRepository.loadCustomConfigLatency().subscribe(on: MainScheduler.asyncInstance).subscribe(onCompleted: {}, onError: { _ in}).disposed(by: disposeBag)
            setApplicationWindow()
            UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        }
        apiManager.getSession(nil).observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { [self] session in
            localDatabase.saveOldSession()
            localDatabase.saveSession(session: session).disposed(by: disposeBag)
        }, onFailure: { [self] error in
            logger.logE(self, "Failed to get session from server with error \(error).")
        }).disposed(by: disposeBag)
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
        logger.logD(self, "App state changed to WillResignActive")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        logger.logD(self, "App state changed to DidEnterBackground")
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.logD(self, "App state changed to WillEnterForeground.")
        connectionStateViewModel.becameActive()
        connectivity.refreshNetwork()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.logD(self, "App state changed to Active.")
        connectionStateViewModel.becameActive()
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
            if preferences.getLoginDate() == nil {
                preferences.saveLoginDate(date: Date())
            }
            let mainViewController = Assembler.resolve(MainViewController.self)
            let viewController = UINavigationController(rootViewController: mainViewController)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.window?.rootViewController = viewController
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
