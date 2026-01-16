//
//  MigrationRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/01/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

protocol MigrationRepository {
    func runMigrations()
}

class MigrationRepositoryImpl: MigrationRepository {
    private let localDatabase: LocalDatabase

    init(localDatabase: LocalDatabase) {
        self.localDatabase = localDatabase
    }

    func runMigrations() {
        localDatabase.migrate()
    }
}
