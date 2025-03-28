//
//  AppDelegate.swift
//  Windscribe
//
//  Created by Yalcin on 2018-11-29.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import CoreData
import NetworkExtension
import RealmSwift
import RxSwift
import StoreKit
import Swinject
import SwiftUI
import UIKit
import WidgetKit
import BackgroundTasks

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var customConfigRepository: CustomConfigRepository = Assembler.resolve(CustomConfigRepository.self)

    private lazy var apiManager: APIManager = Assembler.resolve(APIManager.self)

    private lazy var preferences: Preferences = Assembler.resolve(Preferences.self)

    private lazy var logger: FileLogger = Assembler.resolve(FileLogger.self)

    private lazy var vpnManager: VPNManager = Assembler.resolve(VPNManager.self)

    private lazy var localDatabase: LocalDatabase = Assembler.resolve(LocalDatabase.self)

    private lazy var purchaseManager: InAppPurchaseManager = Assembler.resolve(InAppPurchaseManager.self)

    private lazy var latencyRepository: LatencyRepository = Assembler.resolve(LatencyRepository.self)

    private lazy var pushNotificationManager: PushNotificationManagerV2 = Assembler.resolve(PushNotificationManagerV2.self)

    private lazy var livecycleManager: LivecycleManagerType = Assembler.resolve(LivecycleManagerType.self)

    private lazy var themeManager: ThemeManager = Assembler.resolve(ThemeManager.self)

    private lazy var sessionManager: SessionManagerV2 = Assembler.resolve(SessionManagerV2.self)

    lazy var languageManager: LanguageManagerV2 = Assembler.resolve(LanguageManagerV2.self)

    var window: UIWindow?

    var shortcutType = ShortcutType.none

    private let disposeBag = DisposeBag()

    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        localDatabase.migrate()
        logger.logDeviceInfo()
        languageManager.setAppLanguage()
        livecycleManager.onAppStart()
        recordInstallIfFirstLoad()
        resetCountryOverrideForServerList()
        purchaseManager.verifyPendingTransaction()
        setApplicationWindow()

        return true
    }

    func applicationWillResignActive(_: UIApplication) {
        logger.logD(self, "App state changed to WillResignActive.")
    }

    func applicationDidEnterBackground(_: UIApplication) {
        // Once user have left the app remove last push notification payload.
        logger.logD(self, "App state changed to EnterBackground.")
        pushNotificationManager.addPushNotification(notificationPayload: nil)
        preferences.saveServerSettings(settings: WSNet.instance().currentPersistentSettings())
    }

    func applicationWillEnterForeground(_: UIApplication) {
        logger.logD(self, "App state changed to WillEnterForeground.")
        ProtocolManager.shared.resetGoodProtocol()
    }

    func applicationDidBecomeActive(_: UIApplication) {
        logger.logD(self, "App state changed to Active.")
        registerForPushNotifications()
        AutomaticMode.shared.resetFailCounts()
        livecycleManager.appEnteredForeground()
    }

    func applicationWillTerminate(_: UIApplication) {
        logger.logD(self, "App state changed to WillTerminate.")
    }

    /// Records app install.
    private func recordInstallIfFirstLoad() {
        if preferences.getFirstInstall() == false {
            preferences.saveFirstInstall(bool: true)
            apiManager.recordInstall(platform: "ios").subscribe(onSuccess: { _ in
                self.logger.logD(self, "Successfully recorded new install.")
            }, onFailure: { error in
                self.logger.logE(self, "Failed to record new install: \(error)")
            }).disposed(by: disposeBag)
        }
    }

    /// Load Latency Information
    private func loadLatencyConfiguration() {
        Task.detached { [unowned self] in
            try? await latencyRepository.loadCustomConfigLatency().await(with: disposeBag)
            if await preferences.userSessionAuth() != nil {
                    try? await Task.sleep(nanoseconds: 2_000_000_000)
                await self.latencyRepository.loadLatency()
                }
        }
    }

    /// If vpn state is disconnected on app launch reset country override for the server list.
    private func resetCountryOverrideForServerList() {
        if vpnManager.isDisconnected() {
            preferences.saveCountryOverrride(value: nil)
        }
    }
}

// MARK: Shortcut Actions and User Activity

extension AppDelegate {

    /// Called when app receives connect and disconnect vpn events from siri.
    func application(_: UIApplication,
                     continue userActivity: NSUserActivity,
                     restorationHandler _: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if preferences.userSessionAuth() != nil {
            if userActivity.activityType == SiriIdentifiers.connect {
                NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
            } else if userActivity.activityType == SiriIdentifiers.disconnect {
                NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))
            }
        }
        return true
    }

    /// Called when url is loaded in to app.
    func application(_: UIApplication, open url: URL, sourceApplication _: String?, annotation _: Any) -> Bool {
        if preferences.userSessionAuth() != nil {
            if url.isFileURL && url.pathExtension == "ovpn" {
                logger.logD(self, "Importing OpenVPN .ovpn file")
                if let error = customConfigRepository.saveOpenVPNConfig(url: url) {
                    AlertManager.shared.showSimpleAlert(title: TextsAsset.error, message: error.description, buttonText: TextsAsset.okay)
                } else {
                    NotificationCenter.default.post(Notification(name: Notifications.showCustomConfigTab))
                }
            } else if url.isFileURL && url.pathExtension == "conf" {
                logger.logD(self, "Importing WireGuard .conf file")
                if let error = customConfigRepository.saveWgConfig(url: url) {
                    AlertManager.shared.showSimpleAlert(title: TextsAsset.error, message: error.description, buttonText: TextsAsset.okay)
                } else {
                    NotificationCenter.default.post(Notification(name: Notifications.showCustomConfigTab))
                }
            } else {
                if url.absoluteString.contains("disconnect") {
                    NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))
                } else {
                    NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
                }
            }
        }
        return true
    }

    /// Called when app is launched from a shorcut.
    func application(_: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler _: @escaping (Bool) -> Void) {
        if preferences.userSessionAuth() != nil {
            if shortcutItem.type.contains("Notifications") {
                shortcutType = .notifications
            } else if shortcutItem.type.contains("NetworkSecurity") {
                shortcutType = .networkSecurity
            }
        }
    }
}

// MARK: - Push notifications

extension AppDelegate: UNUserNotificationCenterDelegate {

    func application(_: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void) {
        logger.logD(self, "Push notification received [didReceiveRemoteNotification].")
        if let userInfo = userInfo as? [String: AnyObject] {
            logger.logD(self, "Push notification received while app was in background now handling silent actions: \(userInfo)")
            pushNotificationManager.handleSilentPushNotificationActions(
                payload: PushNotificationPayload(userInfo: userInfo))
        }
        #if arch(arm64) || arch(i386) || arch(x86_64)
            WidgetCenter.shared.reloadAllTimelines()
        #endif
    }

    /// Called when registerForRemoteNotification is successful. Sends device token to the server.
    func application(_: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("") { $0 + String(format: "%02.2hhX", $1) }
        logger.logD(self, "Sending notifcation token to server.")
        apiManager.getSession(token)
            .subscribe(on: MainScheduler.asyncInstance)
            .observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { [self] session in
            logger.logD(self, "Remote notification token registered with server. \(token)")
            localDatabase.saveOldSession()
            localDatabase.saveSession(session: session).disposed(by: disposeBag)
            preferences.saveRegisteredForPushNotifications(bool: true)
        }, onFailure: { [self] error in
            logger.logE(self, "Failed to register remote notification token with server \(error).")
        }).disposed(by: disposeBag)
    }

    /// Called when registerForRemoteNotification calls fails. App will retry on next app launch.
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.logE("app", "Fail to register for remote notifications. \(error.localizedDescription)")
    }

    /// Called if a new push notification is received while app was in foreground.
    func userNotificationCenter(_: UNUserNotificationCenter,
                                willPresent response: UNNotification,
                                withCompletionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        logger.logD(self, "Push notification received [willPresent].")
        if let userInfo = response.request.content.userInfo as? [String: AnyObject] {
            logger.logD(self, "Push notification received while app was in background now handling silent actions: \(userInfo)")
            pushNotificationManager.handleSilentPushNotificationActions(
                payload: PushNotificationPayload(userInfo: userInfo))
        }
        withCompletionHandler([.banner, .list, .sound, .badge])
    }

    /// Called when user clicks on push notification. Save its payload in memory for later use.
    func userNotificationCenter(_: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler: @escaping () -> Void) {
        logger.logD(self, "Push notification received [didReiceive].")
        if let userInfo = response.notification.request.content.userInfo as? [String: AnyObject] {
            logger.logD(self, "User clicked on push notification: \(userInfo)")
            pushNotificationManager.addPushNotification(
                notificationPayload: PushNotificationPayload(userInfo: userInfo))
        }
        withCompletionHandler()
    }

    /// Checks for notification permission . if avaialble register for push notification on each app launch to make sure server has updated device token for this device.
    private func registerForPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        pushNotificationManager.isAuthorizedForPushNotifications { result in
            if result {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
}

// MARK: Main Content View

extension AppDelegate {

    /// Setting up main application window
    /// Checking if there is user session or login should be executed
    func setApplicationWindow() {
        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? Realm() // Ensure Realm is ready before proceeding so it will not block I/O

            DispatchQueue.main.async {
                let welcomeView = self.setUpWelcomeView()
                self.presentMainView(with: welcomeView)
            }
        }
    }

    /// Method to present a SwiftUI view on top a window
    /// - Parameters:
    ///   - contentView: The main  view that will be presented
    private func presentMainView<T: View>(with view: T) {

        let window = UIWindow(frame: UIScreen.main.bounds).then {
            $0.backgroundColor = .black
        }

        let rootViewController: UIViewController

        if self.preferences.userSessionAuth() != nil {
            let mainViewController = Assembler.resolve(MainViewController.self).then {
                $0.appJustStarted = true
            }
            rootViewController = UINavigationController(rootViewController: mainViewController)
        } else {
            // Wrap the RootView in DeviceTypeProvider
            let rootView = DeviceTypeProvider { view }
            rootViewController = UIHostingController(rootView: rootView)
        }

        window.rootViewController = rootViewController
        window.makeKeyAndVisible()
        self.window = window
    }

    private func setUpWelcomeView() -> any View {
        return Assembler.resolve(WelcomeView.self)
    }
}
