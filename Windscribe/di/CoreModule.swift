//
//  SharedDependencies.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import CocoaLumberjack
/// Core dependencies used by all targets.
extension Container {
    func injectCore() {
        register(FileLogger.self) { _ in
            let logger = FileLoggerImpl()
            return logger
        }.inObjectScope(.container)
        register(FileDatabase.self) { r in
            return FileDatabaseImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
        register(Preferences.self) { _ in
            SharedSecretDefaults.shared
        }.inObjectScope(.container)
        register(WSNetServerAPI.self) { r in
            let preferences = r.resolve(Preferences.self)!
            let logger = r.resolve(FileLogger.self)
            WSNet.setLogger({ message in
                let msg = message.split(separator: "]").last?.trimmingCharacters(in: .whitespaces) ?? ""
                logger?.logD(self, msg)
            }, debugLog: false)
            #if STAGING
            WSNet.initialize("ios", appVersion: Bundle.main.releaseVersionNumber ?? "", isUseStagingDomains: true, serverApiSettings: preferences.getServerSettings())
            #else
            WSNet.initialize("ios", appVersion: Bundle.main.releaseVersionNumber ?? "", isUseStagingDomains: false, serverApiSettings: preferences.getServerSettings())
            #endif
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
    }
}
