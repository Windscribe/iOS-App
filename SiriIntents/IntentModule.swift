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
    convenience init(isIntentExt: Bool) {
        self.init()
        injectCore(ext: isIntentExt)
        register(IntentVPNManager.self) { r in
            return IntentVPNManager(logger: r.resolve(FileLogger.self)!,
                              kcDb: r.resolve(KeyChainDatabase.self)!, api: r.resolve(WSNetServerAPI.self)!)
        }.inObjectScope(.container)
        register(KeyChainDatabase.self) { r in
            return KeyChainDatabaseImpl(logger: r.resolve(FileLogger.self)!)
        }
    }
}
