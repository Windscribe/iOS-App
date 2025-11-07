//
//  UserSessionRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject

protocol UserSessionRepository {
    var sessionAuth: String? { get }
    var user: User? { get }
    func getUpdatedUser() async throws -> User
    func login(session: Session) async
    func update(session: Session) async
}

class UserSessionRepositoryImpl: UserSessionRepository {
    private let preferences: Preferences
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let wgCredentials: WgCredentials
    private let logger: FileLogger

    var user: User?
    var sessionAuth: String? {
        return preferences.userSessionAuth()
    }

    init(preferences: Preferences, apiManager: APIManager, localDatabase: LocalDatabase,  wgCredentials: WgCredentials, logger: FileLogger) {
        self.preferences = preferences
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.wgCredentials = wgCredentials
        self.logger = logger

        // Initialize user from database synchronously
        if let session = localDatabase.getSessionSync() {
            self.user = User(session: session)
        }
    }

    @MainActor
    func getUpdatedUser() async throws -> User {
        let session = try await apiManager.getSession(nil)
        localDatabase.saveOldSession()
        await localDatabase.saveSession(session: session)
        let user = User(session: session)
        self.user = user
        return user
    }

    @MainActor
    func login(session: Session) async {
        wgCredentials.delete()
        preferences.saveUserSessionAuth(sessionAuth: session.sessionAuthHash)
        localDatabase.saveOldSession()
        await localDatabase.saveSession(session: session)
        self.user = User(session: session)
    }

    @MainActor
    func update(session: Session) async {
        await localDatabase.saveSession(session: session)
        self.user = User(session: session)
    }
}
