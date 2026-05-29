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

protocol UserSessionRepository: Sendable {
    var sessionAuth: String? { get }
    var sessionModel: SessionModel? { get }
    var oldSessionModel: SessionModel? { get }
    var sessionModelSubject: CurrentValueSubject<SessionModel?, Never> { get }

    func update(session: SessionModel) async
    func updateSessionAuth(with sessionAuthHash: String?)
    func clearSession()
    func canAccesstoProLocation(location: LocationModel) -> Bool
    func canAccesstoProLocation(locationId: Int) -> Bool
    func syncSession() async -> Bool

    func clean()
}

class UserSessionRepositoryImpl: UserSessionRepository {
    private let preferences: Preferences
    private let localDatabase: LocalDatabase
    private let sessionStore: SessionKeychainStore
    private let locationListRepository: LocationListRepository
    private let antiCensorshipRepository: AntiCensorshipRepository

    var sessionModel: SessionModel?
    var oldSessionModel: SessionModel?
    var sessionModelSubject = CurrentValueSubject<SessionModel?, Never>(nil)

    // Cache session auth hash to avoid repeated keychain access which can cause
    // crashes when accessed concurrently from multiple threads (build 3343 crash).
    private var _sessionAuth: String?
    private let authCacheLock = NSLock()

    var sessionAuth: String? {
        authCacheLock.lock()
        defer { authCacheLock.unlock() }
        return _sessionAuth
    }

    var keepSessionUpdatedTrigger = PassthroughSubject<Void, Never>()

    init(preferences: Preferences,
         localDatabase: LocalDatabase,
         sessionStore: SessionKeychainStore,
         locationListRepository: LocationListRepository,
         antiCensorshipRepository: AntiCensorshipRepository) {
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.sessionStore = sessionStore
        self.locationListRepository = locationListRepository
        self.antiCensorshipRepository = antiCensorshipRepository

        updateSessionAuth(with: preferences.getSessionAuthHash())
    }

    func updateSessionAuth(with sessionAuthHash: String?) {
        if let sessionAuthHash = sessionAuthHash {
            preferences.saveSessionAuthHash(sessionAuth: sessionAuthHash)
        } else {
            preferences.clearSessionAuth()
        }
        authCacheLock.lock()
        _sessionAuth = sessionAuthHash
        authCacheLock.unlock()
    }

    func update(session: SessionModel) async {
        sessionStore.save(session: session)
        antiCensorshipRepository.setSessionWgParameter(withId: session.inventory?.amneziawgConfigId ?? "")

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
                updateSessionAuth(with: session.sessionAuthHash)
            }
        }
    }

    func clearSession() {
        sessionModel = nil
        oldSessionModel = nil
        updateSessionAuth(with: nil)
    }

    func canAccesstoProLocation(location: LocationModel) -> Bool {
        let isLocationALC = sessionModel?.alc.contains(location.shortName) ?? false
        let isUserPro = sessionModel?.isPremium ?? false
        return isLocationALC || isUserPro
    }

    func canAccesstoProLocation(locationId: Int) -> Bool {
        guard let location = locationListRepository.getLocation(by: locationId) else {
            return false
        }
        return canAccesstoProLocation(location: location)
    }

    func syncSession() async -> Bool {
        guard let currentSession = sessionStore.load() else {
            return false
        }

        if sessionModel == nil {
            await update(session: currentSession)
        }

        return true
    }

    func clean() {
        sessionStore.clear()
        localDatabase.clean()
    }
}
