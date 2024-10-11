//
//  ContainerResolver.swift
//  Windscribe
//
//  Created by Andre Fonseca on 01/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class ContainerResolver: ContainerResolvertype {
    private lazy var container: Container = {
        self.container = Container(isIntentExt: true)
        container.injectCore()
        return container
    }()

    func getVpnManager() -> IntentVPNManager? {
        return container.resolve(IntentVPNManager.self)
    }

    func getPreferences() -> Preferences {
        return container.resolve(Preferences.self) ?? SharedSecretDefaults()
    }

    func getLogger() -> FileLogger {
        return container.resolve(FileLogger.self) ?? FileLoggerImpl()
    }
}
