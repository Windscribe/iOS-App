//
//  UserDataProviding.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/06/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

protocol UserDataProviding: Sendable {
    func prepareUserData() async throws
}

/// Adapter wrapping the legacy `UserDataRepository`.
final class LegacyUserDataProvider: UserDataProviding, Sendable {
    private let legacy: UserDataRepository

    init(legacy: UserDataRepository) {
        self.legacy = legacy
    }

    func prepareUserData() async throws {
        try await legacy.prepareUserData()
    }
}
