//
//  TestModules.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-26.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import RealmSwift
extension Container {
    func injectLocalDatabase() -> LocalDatabase {
        register(LocalDatabase.self) { _ in
            return LocalDatabaseImpl(logger: FileLoggerImpl(), preferences: SharedSecretDefaults())
        }
        return resolve(LocalDatabase.self)!
    }
    func injectPreferences() -> Preferences {
        register(Preferences.self) { _ in
            return SharedSecretDefaults()
        }
        return resolve(Preferences.self)!
    }
}
