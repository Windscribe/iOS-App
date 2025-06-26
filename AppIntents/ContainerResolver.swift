//
//  ContainerResolver.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class ContainerResolver: ContainerResolvertype {
    private lazy var container: Container = {
        self.container = Container()
        container.injectCore()
        return container
    }()

    func getPreferences() -> Preferences {
        return container.resolve(Preferences.self)!
    }

    func getLogger() -> FileLogger {
        return container.resolve(FileLogger.self)!
    }

    func getApi() -> WSNetServerAPI {
        return container.resolve(WSNetServerAPI.self)!
    }

    func getLocalizationService() -> LocalizationService {
        return container.resolve(LocalizationService.self)!
    }
}
