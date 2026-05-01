//
//  SessionKeychainStore.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/04/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//


/// Protocol for session persistence via Keychain.
protocol SessionKeychainStore {
    func save(session: SessionModel)
    func load() -> SessionModel?
    func clear()
}

/// Persists SessionModel as JSON in the iOS Keychain via Preferences.
class SessionKeychainStoreImpl: SessionKeychainStore {
    private let preferences: Preferences
    private let logger: FileLogger

    init(preferences: Preferences, logger: FileLogger) {
        self.preferences = preferences
        self.logger = logger
    }

    func save(session: SessionModel) {
        do {
            let data = try JSONEncoder().encode(session)
            try preferences.saveStoredSession(data)
        } catch {
            logger.logE("SessionKeychainStore", "Failed to encode session: \(error.localizedDescription)")
        }
    }

    func load() -> SessionModel? {
        do {
            guard let data = try preferences.getStoredSession() else {
                return nil
            }
            let session = try JSONDecoder().decode(SessionModel.self, from: data)
            return session
        } catch {
            logger.logE("SessionKeychainStore", "Failed to decode session: \(error.localizedDescription)")
            return nil
        }
    }

    func clear() {
        preferences.deleteStoredSession()
    }
}
