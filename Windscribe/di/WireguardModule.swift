//
//  ExtensionModules.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
/// Dependencies used by Wireguard network extension.
extension Container {
    convenience init(_: Bool) {
        self.init()
        injectCore()
        register(WgCredentials.self) { r in
            return WgCredentials(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
        register(WireguardAPIManager.self) { r in
            return WireguardAPIManagerImpl(api: r.resolve(WSNetServerAPI.self)!, preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.container)
        register(WireguardConfigRepository.self) { r in
            return WireguardConfigRepositoryImpl(apiCallManager: r.resolve(WireguardAPIManager.self)!, fileDatabase: r.resolve(FileDatabase.self)!, wgCrendentials: r.resolve(WgCredentials.self)!, alertManager: nil, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)
    }
}
