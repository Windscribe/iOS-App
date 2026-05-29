//
//  MigrationRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/01/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

protocol MigrationRepository {
    func runMigrations()
}

class MigrationRepositoryImpl: MigrationRepository {
    private let preferences: Preferences
    private let keychainManager: KeychainManager
    private let userSessionRepository: UserSessionRepository
    private let logger: FileLogger

    init(preferences: Preferences,
         keychainManager: KeychainManager,
         userSessionRepository: UserSessionRepository,
         logger: FileLogger) {
        self.preferences = preferences
        self.keychainManager = keychainManager
        self.userSessionRepository = userSessionRepository
        self.logger = logger
    }

    func runMigrations() {
        // Realm-dependent ports (Session, OpenVPN/IKEv2 creds, custom config
        // creds) run inside the LocalDatabase factory before the GRDB swap —
        // see RealmKeychainPortMigration. By the time we get here, those are
        // already done.
        migrateKeychainAccessibility()
        migrateSessionAuthToKeychain()
    }

    private static let keychainAccessibilityMigrationKey = "keychain-accessibility-migrated-v1"

    /// Ensures all known keychain items use `kSecAttrAccessibleAfterFirstUnlock` and the
    /// shared access group so they are readable during device sleep/lock by all extensions.
    /// Runs once and sets a UserDefaults flag so it never runs again.
    private func migrateKeychainAccessibility() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: Self.keychainAccessibilityMigrationKey) else { return }

        let sharedGroup = SharedKeys.sharedKeychainGroup
        let keysToMigrate: [(key: String, service: String)] = [
            (SharedKeys.privateKey, "WireguardService"),
            (SharedKeys.activeSessionAuthHash, Bundle.main.bundleIdentifier ?? ""),
            (SharedKeys.keychainStoredSession, Bundle.main.bundleIdentifier ?? ""),
            (SharedKeys.keychainOpenVPNCred, Bundle.main.bundleIdentifier ?? ""),
            (SharedKeys.keychainIKEv2Cred, Bundle.main.bundleIdentifier ?? ""),
            (SharedKeys.keychainCustomConfigCreds, Bundle.main.bundleIdentifier ?? ""),
            (KeyChainkeys.ghostAccountCreated, Bundle.main.bundleIdentifier ?? "")
        ]

        for item in keysToMigrate {
            do {
                try keychainManager.migrateItemAccessibility(
                    forKey: item.key,
                    service: item.service,
                    accessGroup: sharedGroup
                )
            } catch {
                logger.logE("MigrationRepository", "Failed to migrate keychain accessibility for '\(item.key)': \(error)")
            }
        }

        defaults.set(true, forKey: Self.keychainAccessibilityMigrationKey)
        logger.logD("MigrationRepository", "Keychain accessibility migration completed")
    }

    /// Migrates session auth hash from UserDefaults to Keychain.
    ///
    /// Handles two scenarios:
    /// 1. **Existing user update**: Auth hash exists in UserDefaults → copy to Keychain, remove from UserDefaults
    /// 2. **Fresh install / reinstall**: Keychain survives reinstall but UserDefaults resets.
    ///    If `firstInstall` is false (fresh install), clear any stale Keychain auth entries.
    private func migrateSessionAuthToKeychain() {
        // Fresh install detection: UserDefaults resets on reinstall, Keychain doesn't.
        if preferences.getFirstInstall() == false {
            preferences.clearSessionAuth()
            return
        }

        // Check if value exists in old UserDefaults location
        guard let oldAuthHash = preferences.getUserDefaultsSessionAuth(), !oldAuthHash.isEmpty else {
            return
        }

        // Migrate via Preferences (which writes to Keychain)
        userSessionRepository.updateSessionAuth(with: oldAuthHash)
        preferences.clearUserDefaultsSessionAuth()
        logger.logD("MigrationRepository", "Successfully migrated session auth hash to Keychain")
    }
}
