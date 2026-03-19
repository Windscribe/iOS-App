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

    func update(session: SessionModel) async
    func clearSession()
    func canAccesstoProLocation() -> Bool
    func syncSession() async -> Bool

    func clean()
}

class UserSessionRepositoryImpl: UserSessionRepository {
    private let preferences: Preferences
    private let localDatabase: LocalDatabase
    private let locationListRepository: LocationListRepository

    var sessionModel: SessionModel?
    var oldSessionModel: SessionModel?
    var sessionModelSubject = CurrentValueSubject<SessionModel?, Never>(nil)

    var sessionAuth: String? {
        return preferences.userSessionAuth()
    }

    var keepSessionUpdatedTrigger = PassthroughSubject<Void, Never>()

    init(preferences: Preferences,
         localDatabase: LocalDatabase,
         locationListRepository: LocationListRepository) {
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.locationListRepository = locationListRepository
    }

    func update(session: SessionModel) async {
        localDatabase.saveOldSession()
        localDatabase.saveSession(session: Session(sessionModel: session))

        try? await locationListRepository.updateAllIfEmpty()

        if let inventory = session.inventory {
            locationListRepository.updateInventory(with: inventory)
        }

        await MainActor.run { [weak self] in
               guard let self = self else { return }

               self.oldSessionModel = self.sessionModel
               self.sessionModel = session
               sessionModelSubject.send(session)
               if !session.sessionAuthHash.isEmpty {
                   preferences.saveUserSessionAuth(sessionAuth: session.sessionAuthHash)
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
            await update(session: SessionModel(from: currentSession))
        }

        localDatabase.saveOldSession()
        return true
    }

    func clean() {
        localDatabase.clean()
    }
}
