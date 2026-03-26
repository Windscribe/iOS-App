//
//  AppDelegate.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Swinject
import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    private lazy var apiManager: APIManager = Assembler.resolve(APIManager.self)

    private lazy var preferences: Preferences = Assembler.resolve(Preferences.self)

    private lazy var logger: FileLogger = Assembler.resolve(FileLogger.self)

    private lazy var vpnStateRepository: VPNStateRepository = Assembler.resolve(VPNStateRepository.self)

    private lazy var migrationRepository: MigrationRepository = Assembler.resolve(MigrationRepository.self)

    private lazy var purchaseManager: InAppPurchaseManager = Assembler.resolve(InAppPurchaseManager.self)

    private lazy var lifecycleManager: LifecycleManagerType = Assembler.resolve(LifecycleManagerType.self)

    lazy var languageManager: LanguageManager = Assembler.resolve(LanguageManager.self)

    func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
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
                    _ = try await self.apiManager.recordInstall(platform: "tvos")
                    self.logger.logI("AppDelegate", "Successfully recorded new install.")
                } catch {
                    self.logger.logE("AppDelegate", "Failed to record new install: \(error)")
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
