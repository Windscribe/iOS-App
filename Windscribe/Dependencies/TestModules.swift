//
//  TestModules.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-26.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Swinject

extension Container {
    func injectLocalDatabase() -> LocalDatabase {
        register(LocalDatabase.self) { _ in
            LocalDatabaseImpl(
                logger: FileLoggerImpl(),
                preferences: PreferencesImpl())
        }
        return resolve(LocalDatabase.self)!
    }

    func injectPreferences() -> Preferences {
        register(Preferences.self) { _ in
            PreferencesImpl()
        }
        return resolve(Preferences.self)!
    }
}
