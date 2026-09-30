//
//  CoreModule.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

/// Core dependencies used by all targets.
extension Container {
    func injectCore(process: LogProcess) {
        register(FileLogger.self) { _ in
            let logger = FileLoggerImpl(process: process)
            return logger
        }.inObjectScope(.container)
        register(KeychainManager.self) { r in
            KeychainManagerImpl(
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)
        register(FileDatabase.self) { r in
            FileDatabaseImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
        register(Preferences.self) { r in
            PreferencesImpl(
                logger: r.resolve(FileLogger.self)!,
                keychainManager: r.resolve(KeychainManager.self)!
            )
        }.inObjectScope(.container)
        register(LocalizationService.self) { r in
            LocalizationServiceImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
        if !WSNet.isValid() {
            initializeWSNet(r: self)
        }
        register(WSNetServerAPIType.self) { _ in
            WSNet.instance().serverAPI()
        }.inObjectScope(.container)
        register(WSNetBridgeAPIType.self) { _ in
            WSNet.instance().bridgeAPI()
        }.inObjectScope(.container)
        register(WSNetPingManagerType.self) { _ in
            WSNet.instance().pingManager()
        }.inObjectScope(.container)
        register(APIUtilService.self) { _ in
            APIUtilServiceImpl()
        }.inObjectScope(.container)

        register(DNSSettingsManagerType.self) { _ in
            DNSSettingsManager()
        }.inObjectScope(.container)
    }

    private func initializeWSNet(r: Container) {
        let preferences = r.resolve(Preferences.self)!
        let logger = r.resolve(FileLogger.self)
        var language = "en"
        let preferredLanguages = Locale.preferredLanguages
        if let deviceLanguage = preferredLanguages.first {
            language = String(deviceLanguage.prefix(2))
        }

        let platform = Env.isTVOS ? "appletv" : "ios"

        WSNet.initialize(
            platform,
            platformName: platform,
            appVersion: Bundle.main.releaseVersionNumber ?? "",
            deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "",
            openVpnVersion: APIParameterValues.openVPNVersion,
            sessionTypeId: "4",
            isUseStagingDomains: Env.isStaging,
            language: language,
            persistentSettings: preferences.getServerSettings(),
            loggerFunction: { message in
                logger?.logWSNet(message.trimmingCharacters(in: .whitespacesAndNewlines))
            },
            debugLog: Env.isDebug,
            amneziawgVersion: APIParameterValues.unlockWGVersion)

        WSNet.instance().dnsResolver().setDnsServers(["1.1.1.1", "9.9.9.9"])
        WSNet.instance().setConnectivityState(true)
        WSNet.instance().setIsConnectedToVpnState(false)
        WSNet.instance().advancedParameters().setAPIExtraTLSPadding(preferences.isCircumventCensorshipEnabled())
        if let countryOverride = preferences.getAdvanceParams().splitToArray(separator: "\n").first(where: { keyValue in
            let pair = keyValue.splitToArray(separator: "=")
            return pair.count == 2 && pair[0] == wsServerOverrride
        })?.splitToArray(separator: "=")
            .dropFirst()
            .joined(separator: "=") {
            WSNet.instance().advancedParameters().setCountryOverrideValue(countryOverride)
        }
    }
}
