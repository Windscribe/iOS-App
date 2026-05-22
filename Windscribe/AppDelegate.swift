//
//  AppDelegate.swift
//  Windscribe
//
//  Created by Yalcin on 2018-11-29.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import BackgroundTasks
import CoreData
import NetworkExtension
import StoreKit
import Swinject
import UIKit
import WidgetKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var apiManager: APIManager = Assembler.resolve(APIManager.self)
    private lazy var sessionManager: SessionManager = Assembler.resolve(SessionManager.self)

    private lazy var preferences: Preferences = Assembler.resolve(Preferences.self)

    private lazy var logger: FileLogger = Assembler.resolve(FileLogger.self)

    private lazy var vpnStateRepository: VPNStateRepository = Assembler.resolve(VPNStateRepository.self)

    private lazy var migrationRepository: MigrationRepository = Assembler.resolve(MigrationRepository.self)

    private lazy var purchaseManager: InAppPurchaseManager = Assembler.resolve(InAppPurchaseManager.self)

    private lazy var pushNotificationManager: PushNotificationManager = Assembler.resolve(PushNotificationManager.self)

    private lazy var lifecycleManager: LifecycleManagerType = Assembler.resolve(LifecycleManagerType.self)

    private lazy var languageManager: LanguageManager = Assembler.resolve(LanguageManager.self)

    func application(_: UIApplication,
                     didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        migrationRepository.runMigrations()
        logger.logDeviceInfo()
        languageManager.setAppLanguage()
        lifecycleManager.onAppStart()
        recordInstallIfFirstLoad()
        resetCountryOverrideForServerList()
        purchaseManager.verifyPendingTransaction()

        return true
    }

    /// Records app install.
    private func recordInstallIfFirstLoad() {
        if preferences.getFirstInstall() == false {
            preferences.saveFirstInstall(bool: true)
            Task { [weak self] in
                guard let self = self else { return }

                do {
                    _ = try await self.apiManager.recordInstall(platform: "ios")
                    self.logger.logI("AppDelegate", "RecordInstall was successfully recorded new install.")
                } catch {
                    self.logger.logE("AppDelegate", "RecordInstall failed to record new install: \(error)")
                }
            }
        }
    }

    /// If vpn state is disconnected on app launch reset country override for the server list.
    private func resetCountryOverrideForServerList() {
        if vpnStateRepository.isDisconnected() {
            preferences.saveCountryOverrride(value: nil)
        }
    }
}

// MARK: - Scene Configuration

extension AppDelegate {

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Default Configuration",
                                           sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

// MARK: - Push notifications

extension AppDelegate {

    func application(_: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler _: @escaping (UIBackgroundFetchResult) -> Void) {
        logger.logD("AppDelegate", "Push notification received [didReceiveRemoteNotification].")
        if let userInfo = userInfo as? [String: AnyObject] {
            logger.logD("AppDelegate", "Push notification received while app was in background now handling silent actions: \(userInfo)")
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
        logger.logI("AppDelegate", "Sending notifcation token to server.")
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                try await sessionManager.updateSession(token)
                self.logger.logI("AppDelegate", "Remote notification token registered with server. \(token.redacted)")
                self.preferences.saveRegisteredForPushNotifications(bool: true)
            } catch {
                await MainActor.run {
                    self.logger.logE("AppDelegate", "Failed to register remote notification token with server \(error).")
                }
            }
        }
    }

    /// Called when registerForRemoteNotification calls fails. App will retry on next app launch.
    func application(_: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        logger.logE("app", "Fail to register for remote notifications. \(error.localizedDescription)")
    }
}
