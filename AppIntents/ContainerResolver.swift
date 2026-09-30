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
    private let process: LogProcess

    private lazy var container: Container = {
        self.container = Container()
        container.injectCore(process: process)
        container.register(APIUtilService.self) { _ in
            APIUtilServiceImpl()
        }.inObjectScope(.container)
        return container
    }()

    init(process: LogProcess) {
        self.process = process
    }

    func getPreferences() -> Preferences {
        return container.resolve(Preferences.self)!
    }

    func getLogger() -> FileLogger {
        return container.resolve(FileLogger.self)!
    }

    func getApi() -> WSNetServerAPIType {
        return container.resolve(WSNetServerAPIType.self)!
    }

    func getBridgeApi() -> WSNetBridgeAPIType {
        return container.resolve(WSNetBridgeAPIType.self)!
    }

    func getLocalizationService() -> LocalizationService {
        return container.resolve(LocalizationService.self)!
    }

    func getApiUtil() -> APIUtilService {
        return container.resolve(APIUtilService.self)!
    }
}
