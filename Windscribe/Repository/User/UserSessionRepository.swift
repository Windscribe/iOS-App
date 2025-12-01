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

    func update(sessionModel: SessionModel)
    func clearSession()
    func canAccesstoProLocation() -> Bool
}

class UserSessionRepositoryImpl: UserSessionRepository {
    private let preferences: Preferences

    var sessionModel: SessionModel?
    var oldSessionModel: SessionModel?
    var sessionModelSubject = CurrentValueSubject<SessionModel?, Never>(nil)

    var sessionAuth: String? {
        return preferences.userSessionAuth()
    }

    var keepSessionUpdatedTrigger = PassthroughSubject<Void, Never>()

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func update(sessionModel: SessionModel) {
        self.oldSessionModel = self.sessionModel
        self.sessionModel = sessionModel
        sessionModelSubject.send(sessionModel)
        if !sessionModel.sessionAuthHash.isEmpty {
            preferences.saveUserSessionAuth(sessionAuth: sessionModel.sessionAuthHash)
        }
    }

    func clearSession() {
        sessionModel = nil
        oldSessionModel = nil
    }

    func canAccesstoProLocation() -> Bool {
        sessionModel?.isPremium ?? false
    }
}
