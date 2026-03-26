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
        container.register(WindowSetupService.self) { r in
            WindowSetupServiceImpl(
                preferences: r.resolve(Preferences.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.container)

        container.register(SceneActionHandler.self) { r in
            SceneActionHandlerImpl(
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!,
                customConfigRepository: r.resolve(CustomConfigRepository.self)!,
                alertManager: r.resolve(AlertManager.self)!,
                windowProvider: r.resolve(WindowProvider.self)!)
        }.inObjectScope(.container)
    }
}
