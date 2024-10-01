//
//  IntentModule.swift
//  SiriIntents
//
//  Created by Andre Fonseca on 25/09/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

extension Container {
    convenience init(isExt: Bool) {
        self.init()
        injectCore(ext: isExt)
        register(VPNManager.self) { r in
            return VPNManager(logger: r.resolve(FileLogger.self)!,
                              kcDb: r.resolve(KeyChainDatabase.self)!)
        }.inObjectScope(.container)
        register(KeyChainDatabase.self) { r in
            return KeyChainDatabaseImpl(logger: r.resolve(FileLogger.self)!)
        }
    }
}
