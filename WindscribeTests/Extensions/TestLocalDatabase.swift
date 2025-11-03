//
//  TestLocalDatabaseImpl.swift
//  Windscribe
//
//  Created by Andre Fonseca on 06/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

@testable import Windscribe
import RealmSwift

// MARK: Test LocalDatabase Implementation (inherits from the real one)

class TestLocalDatabaseImpl: LocalDatabaseImpl {
    private var testRealmConfiguration: Realm.Configuration

    override init(logger: FileLogger, preferences: Preferences) {
        // Set up test-specific Realm configuration
        testRealmConfiguration = Realm.Configuration()
        testRealmConfiguration.inMemoryIdentifier = "test-realm-\(UUID().uuidString)"

        super.init(logger: logger, preferences: preferences)

        // Override the default Realm configuration for testing
        Realm.Configuration.defaultConfiguration = testRealmConfiguration
    }
}
