//
//  UserSessionRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import Combine

protocol UserSessionRepository {
    var sessionAuth: String? { get }
    var sessionModel: SessionModel? { get }
    var oldSessionModel: SessionModel? { get }
    var sessionModelSubject: CurrentValueSubject<SessionModel?, Never> { get }

    func update(session: Session) async
    func clearSession()
    func canAccesstoProLocation() -> Bool
    func syncSession() async -> Bool

    func clean()
}

class UserSessionRepositoryImpl: UserSessionRepository {
    private let preferences: Preferences
    private let localDatabase: LocalDatabase

    var sessionModel: SessionModel?
    var oldSessionModel: SessionModel?
    var sessionModelSubject = CurrentValueSubject<SessionModel?, Never>(nil)

    var sessionAuth: String? {
        return preferences.userSessionAuth()
    }

    var keepSessionUpdatedTrigger = PassthroughSubject<Void, Never>()

    init(preferences: Preferences,
         localDatabase: LocalDatabase) {
        self.preferences = preferences
        self.localDatabase = localDatabase
    }

    func update(session: Session) async {
        localDatabase.saveOldSession()
        localDatabase.saveSession(session: session)
        let model = session.getModel()
        await MainActor.run {
            [weak self] in
               guard let self = self else { return }
               self.oldSessionModel = self.sessionModel
               self.sessionModel = model
               sessionModelSubject.send(model)
               if !model.sessionAuthHash.isEmpty {
                   preferences.saveUserSessionAuth(sessionAuth: model.sessionAuthHash)
               }
        }
    }

    func clearSession() {
        sessionModel = nil
        oldSessionModel = nil
    }

    func canAccesstoProLocation() -> Bool {
        sessionModel?.isPremium ?? false
    }

    func syncSession() async -> Bool {
        guard let currentSession = localDatabase.getSession() else {
            return false
        }

        if sessionModel == nil {
            await update(session: currentSession)
        }

        localDatabase.saveOldSession()
        return true
    }

    func clean() {
        localDatabase.clean()
    }
}
