//
//  AppDelegate.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift
import Swinject
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?

    private lazy var customConfigRepository: CustomConfigRepository = Assembler.resolve(CustomConfigRepository.self)

    let disposeBag = DisposeBag()
    private lazy var apiManager: APIManager = Assembler.resolve(APIManager.self)

    private lazy var sessionManager: SessionManager = Assembler.resolve(SessionManager.self)

    private lazy var preferences: Preferences = Assembler.resolve(Preferences.self)

    private lazy var logger: FileLogger = Assembler.resolve(FileLogger.self)

    private lazy var vpnStateRepository: VPNStateRepository = Assembler.resolve(VPNStateRepository.self)

    private lazy var localDatabase: LocalDatabase = Assembler.resolve(LocalDatabase.self)

    private lazy var purchaseManager: InAppPurchaseManager = Assembler.resolve(InAppPurchaseManager.self)

    private lazy var latencyRepository: LatencyRepository = Assembler.resolve(LatencyRepository.self)

    private lazy var pushNotificationManager: PushNotificationManager = Assembler.resolve(PushNotificationManager.self)

    private lazy var lookAndFeelRepository: LookAndFeelRepositoryType = Assembler.resolve(LookAndFeelRepositoryType.self)

    private lazy var connectivity: ConnectivityManager = Assembler.resolve(ConnectivityManager.self)

    private lazy var livecycleManager: LivecycleManagerType = Assembler.resolve(LivecycleManagerType.self)

    private lazy var protocolManager: ProtocolManagerType = Assembler.resolve(ProtocolManagerType.self)

    lazy var languageManager: LanguageManager = Assembler.resolve(LanguageManager.self)

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        localDatabase.migrate()
        logger.logDeviceInfo()
        languageManager.setAppLanguage()
        connectivity.refreshNetwork()
        recordInstallIfFirstLoad()
        resetCountryOverrideForServerList()
        purchaseManager.verifyPendingTransaction()
        setApplicationWindow()
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        if preferences.userSessionAuth() != nil {
            delay(2) {
                self.latencyRepository.loadLatency()
            }
        }
        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                try await sessionManager.updateSession()
            } catch {
                await MainActor.run {
                    self.logger.logE("AppDelegate", "Failed to get session from server with error \(error).")
                }
            }
        }

        Task.detached { [unowned self] in
            try? await latencyRepository.loadCustomConfigLatency().await(with: disposeBag)
            if await preferences.userSessionAuth() != nil {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                await self.latencyRepository.loadLatency()
                }
        }

        return true
    }

    /**
     Records app install.
     */
    private func recordInstallIfFirstLoad() {
        if preferences.getFirstInstall() == false {
            preferences.saveFirstInstall(bool: true)
            Task { [weak self] in
                guard let self = self else { return }

                do {
                    _ = try await self.apiManager.recordInstall(platform: "tvos")
                    self.logger.logI("AppDelegate", "Successfully recorded new install.")
                } catch {
                    self.logger.logE("AppDelegate", "Failed to record new install: \(error)")
                }
            }
        }
    }

    /**
     If vpn state is disconnected on app launch reset country override for the server list.
     */
    private func resetCountryOverrideForServerList() {
        if vpnStateRepository.isDisconnected() {
            preferences.saveCountryOverrride(value: nil)
        }
    }

    func applicationWillResignActive(_: UIApplication) {
        logger.logI("AppDelegate", "App state changed to WillResignActive")
    }

    func applicationDidEnterBackground(_: UIApplication) {
        logger.logI("AppDelegate", "App state changed to DidEnterBackground")
    }

    func applicationWillEnterForeground(_: UIApplication) {
        logger.logI("AppDelegate", "App state changed to WillEnterForeground.")
        protocolManager.resetGoodProtocol()
    }

    func applicationDidBecomeActive(_: UIApplication) {
        logger.logI("AppDelegate", "App state changed to Active.")
        livecycleManager.appEnteredForeground()
    }

    /**
     Prepares application window and launches first view controller
     */
    func setApplicationWindow() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = window else { return }
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
