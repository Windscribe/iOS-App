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
    func injectCore(ext _: Bool = false) {
        register(FileLogger.self) { _ in
            let logger = FileLoggerImpl()
            return logger
        }.inObjectScope(.container)
        register(FileDatabase.self) { r in
            FileDatabaseImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
        register(Preferences.self) { r in
            PreferencesImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
        register(LocalizationService.self) { r in
            LocalizationServiceImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
        if WSNet.isValid() {
            register(WSNetServerAPI.self) { _ in
                WSNet.instance().serverAPI()
            }.inObjectScope(.container)
            return
        }
        register(WSNetServerAPI.self) { r in
            let preferences = r.resolve(Preferences.self)!
            let logger = r.resolve(FileLogger.self)
            WSNet.setLogger({ message in
                logger?.logWSNet(message.trimmingCharacters(in: .whitespacesAndNewlines))
            }, debugLog: false)
            var language = "en"
            let preferredLanguages = Locale.preferredLanguages
            if let deviceLanguage = preferredLanguages.first {
                language = String(deviceLanguage.prefix(2))
            }
            #if STAGING
                WSNet.initialize("ios", platformName: "ios", appVersion: Bundle.main.releaseVersionNumber ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "", openVpnVersion: APIParameterValues.openVPNVersion, sessionTypeId: "4", isUseStagingDomains: true, language: language, persistentSettings: preferences.getServerSettings())
            #else
                WSNet.initialize("ios", platformName: "ios", appVersion: Bundle.main.releaseVersionNumber ?? "", deviceId: UIDevice.current.identifierForVendor?.uuidString ?? "", openVpnVersion: APIParameterValues.openVPNVersion, sessionTypeId: "4", isUseStagingDomains: false, language: language, persistentSettings: preferences.getServerSettings())
            #endif
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
            return WSNet.instance().serverAPI()
        }.inObjectScope(.container)
        register(DNSSettingsManagerType.self) { _ in
            DNSSettingsManager()
        }.inObjectScope(.container)
        register(KeychainManager.self) { r in
            KeychainManagerImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
    }
}
