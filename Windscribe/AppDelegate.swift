//
//  AppDelegate.swift
//  Windscribe
//
//  Created by Yalcin on 2018-11-29.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import UIKit
import CoreData
import WidgetKit
import RealmSwift
import NetworkExtension
import StoreKit
import Swinject
import RxSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    var shortcutType = ShortcutType.none

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
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        localDatabase.migrate()
        logger.logDeviceInfo()
        languageManager.setAppLanguage()
        vpnManager.setup { [self] in
            recordInstallIfFirstLoad()
            registerForPushNotifications()
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
     Prepares application window and launches first view controller
     */
    func setApplicationWindow() {
        self.window = UIWindow(frame: UIScreen.main.bounds)
        guard let window = self.window else { return }
        window.backgroundColor = UIColor.black
        // Authenticated user
        if preferences.userSessionAuth() != nil {
            let mainViewController = Assembler.resolve(MainViewController.self)
            mainViewController.appJustStarted = true
            let viewController = UINavigationController(rootViewController: mainViewController)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.window?.rootViewController = viewController
            }, completion: nil)
        } else {
            let firstViewController = Assembler.resolve(WelcomeViewController.self)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                self.window?.rootViewController = UINavigationController(rootViewController: firstViewController)
            }, completion: nil)
        }
        self.window?.makeKeyAndVisible()
    }

    /**
     Records app install.
     */
    private func recordInstallIfFirstLoad() {
        if preferences.getFirstInstall() != nil {
            preferences.saveFirstInstall(bool: true)
            apiManager.recordInstall(platform: "ios").subscribe(onSuccess: { _ in
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
        if vpnManager.connectionStatus() == NEVPNStatus.disconnected {
            preferences.saveCountryOverrride(value: nil)
        }
    }

    // MARK: App actions and urls
    /**
     Called when app receives connect and disconnect vpn events from siri.
     */
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        if preferences.userSessionAuth() != nil {
            if userActivity.activityType == SiriIdentifiers.connect {
                NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
                vpnManager.connectWhenReady = true
            } else if userActivity.activityType == SiriIdentifiers.disconnect {
                NotificationCenter.default.post(Notification(name: Notifications.disconnectVPN))
                vpnManager.disconnectWhenReady = true
            }
        }
        return true
    }

    /**
     Called when url is loaded in to app.
     */
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        if preferences.userSessionAuth() != nil {
            if url.isFileURL && url.pathExtension == "ovpn" {
                logger.logD(self, "Importing OpenVPN .ovpn file" )
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
                    vpnManager.disconnectWhenReady = true
                } else {
                    NotificationCenter.default.post(Notification(name: Notifications.connectToVPN))
                    vpnManager.connectWhenReady = true
                }
            }
        }
        return true
    }

    /**
     Called when app is launched from a shorcut.
     */
    func application(_ application: UIApplication,
                     performActionFor shortcutItem: UIApplicationShortcutItem,
                     completionHandler: @escaping (Bool) -> Void) {
        if preferences.userSessionAuth() != nil {
            if shortcutItem.type.contains("Notifications") {
                shortcutType = .notifications
            } else if shortcutItem.type.contains("NetworkSecurity") {
                shortcutType = .networkSecurity
            }
        }
    }

    // MARK: App life cycle events
    func applicationWillResignActive(_ application: UIApplication) {
        logger.logD(self, "App state changed to WillResignActive.")
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Once user have left the app remove last push notification payload.
        logger.logD(self, "App state changed to EnterBackground.")
        pushNotificationManager.addPushNotification(notificationPayload: nil)
        preferences.saveServerSettings(settings: WSNet.instance().currentPersistentSettings())
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        logger.logD(self, "App state changed to WillEnterForeground.")
        ConnectionManager.shared.resetGoodProtocol()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        logger.logD(self, "App state changed to Active.")
        AutomaticMode.shared.resetFailCounts()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        logger.logD(self,  "App state changed to WillTerminate.")
    }

    // MARK: Push notifications
    /**
     Checks for notification permission . if avaialble register for push notification on each app launch to make sure server has updated device token for this device.
     */
    private func registerForPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        pushNotificationManager.isAuthorizedForPushNotifications { (result) in
            if result {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if #available(iOS 14.0, *) {
#if arch(arm64) || arch(i386) || arch(x86_64)
            WidgetCenter.shared.reloadAllTimelines()
#endif
        }
    }
    /**
     Called when registerForRemoteNotification is successful. Sends device token to the server.
     */
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let token = deviceToken.reduce("", { $0 + String(format: "%02.2hhX", $1) })
        logger.logD(self, "Registered for remote notifications with token: \(token).")
        apiManager.getSession().observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { [self] session in
            logger.logD(self, "Remote notification token registered with server. \(token)")
            localDatabase.saveOldSession()
            localDatabase.saveSession(session: session).disposed(by: disposeBag)
            preferences.saveRegisteredForPushNotifications(bool: true)
        }, onFailure: { [self] error in
            logger.logE(self, "Failed to register remote notification token with server \(error).")
        }).disposed(by: disposeBag)
    }

    /**
     Called when registerForRemoteNotification calls fails. App will retry on next app launch.
     */
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.logE(self, "Fail to register for remote notifications. \(error.localizedDescription)")
    }

    /**
     Called if a new push notification is received while app was in foreground.
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent response: UNNotification,
                                withCompletionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        if let userInfo = response.request.content.userInfo as? [String: AnyObject] {
            logger.logD(self, "Push notification received while app was in background now handling silent actions: \(userInfo)")
            pushNotificationManager.handleSilentPushNotificationActions(payload: PushNotificationPayload(userInfo: userInfo))
        }
        withCompletionHandler([.alert, .sound, .badge])
    }

    /**
     Called when user clicks on push notification. Save its payload in memory for later use.
     */
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler: @escaping () -> Void) {
        if let userInfo = response.notification.request.content.userInfo as? [String: AnyObject] {
            logger.logD(self, "User clicked on push notification: \(userInfo)")
            pushNotificationManager.addPushNotification(notificationPayload: PushNotificationPayload(userInfo: userInfo))
        }
        withCompletionHandler()
    }
}
