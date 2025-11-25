//
//  AppModulesRouters.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-11-13.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import RxSwift
import Swinject

// MARK: Routers

class Routers: Assembly {
    func assemble(container: Container) {
        container.register(AuthenticationNavigationRouter.self) { _ in
            AuthenticationNavigationRouter()
        }.inObjectScope(.transient)
        container.register(PreferencesNavigationRouter.self) { _ in
            PreferencesNavigationRouter()
        }.inObjectScope(.transient)

        container.register(ScreenTestNavigationRouter.self) { _ in
            ScreenTestNavigationRouter()
        }.inObjectScope(.transient)

        container.register(ConnectionsNavigationRouter.self) { _ in
            ConnectionsNavigationRouter()
        }.inObjectScope(.transient)
        container.register(ShakeForDataNavigationRouter.self) { _ in
            ShakeForDataNavigationRouter()
        }.inObjectScope(.transient)
        container.register(HelpNavigationRouter.self) { _ in
            HelpNavigationRouter()
        }.inObjectScope(.transient)
        container.register(HomeRouter.self) { _ in
            HomeRouter()
        }.inObjectScope(.transient)
        container.register(AccountRouter.self) { _ in
            AccountRouter()
        }.inObjectScope(.transient)
        container.register(UpgradeRouter.self) { _ in
            UpgradeRouter()
        }.inObjectScope(.transient)
        container.register(PopupRouter.self) { _ in
            PopupRouter()
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchRouter.self) { _ in
            ProtocolSwitchRouter()
        }.inObjectScope(.transient)
    }
}
