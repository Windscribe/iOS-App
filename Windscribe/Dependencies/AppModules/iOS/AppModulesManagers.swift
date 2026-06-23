//
//  AppModulesManagers.swift
//  Windscribe
//
//  Created by Anthony on 2026-03-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Swinject

class IOSManagers: Assembly {
    func assemble(container: Container) {
        container.register(HashAuthManager.self) { r in
            HashAuthManagerImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register(WindowSetupService.self) { _ in
            WindowSetupServiceImpl()
        }.inObjectScope(.container)

        container.register(SceneActionHandler.self) { r in
            SceneActionHandlerImpl(
                logger: r.resolve(FileLogger.self)!,
                windowProvider: r.resolve(WindowProvider.self)!)
        }.inObjectScope(.container)
    }
}
