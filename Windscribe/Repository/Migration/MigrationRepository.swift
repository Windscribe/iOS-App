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
    private let localDatabase: LocalDatabase
    private let preferences: Preferences
    private let sessionStore: SessionKeychainStore
    private let keychainManager: KeychainManager
    private let logger: FileLogger

    init(localDatabase: LocalDatabase,
         preferences: Preferences,
         sessionStore: SessionKeychainStore,
         keychainManager: KeychainManager,
         logger: FileLogger) {
        self.localDatabase = localDatabase
        self.preferences = preferences
        self.sessionStore = sessionStore
        self.keychainManager = keychainManager
        self.logger = logger
    }

    func runMigrations() {
        localDatabase.migrate()
        migrateKeychainAccessibility()
        migrateSessionAuthToKeychain()
        migrateSessionFromRealmToKeychain()
        migrateCustomConfigCredentialsToKeychain()
        migrateServerCredentialsToKeychain()
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

    /// Migrates custom config credentials from Realm to Keychain.
    /// After migration, credentials are stored keyed by config ID and cleared from Realm.
    private func migrateCustomConfigCredentialsToKeychain() {
        // Skip on fresh install — nothing to migrate
        if preferences.getFirstInstall() == false {
            preferences.deleteAllCustomConfigCredentials()
            return
        }

        let customConfigs = localDatabase.getCustomConfigs()
        var existingCredentials = preferences.getAllCustomConfigCredentials()
        var clearedConfigs = [CustomConfig]()
        var didMigrate = false

        for config in customConfigs {
            guard !(config.username.isEmpty && config.password.isEmpty) else { continue }

            // Skip if already migrated
            if existingCredentials[config.id] != nil {
                continue
            }

            // Add to dictionary
            existingCredentials[config.id] = ServerCredentialsModel(username: config.username, password: config.password)

            // Clear from Realm
            let cleared = CustomConfig(
                id: config.id,
                name: config.name,
                serverAddress: config.serverAddress,
                protocolType: config.protocolType,
                port: config.port,
                username: "",
                password: "",
                authRequired: config.authRequired,
                saveCredentials: config.saveCredentials
            )
            clearedConfigs.append(cleared)
            logger.logD("MigrationRepository", "Migrated credentials for custom config \(config.id) to Keychain")
            didMigrate = true
        }

        // Save all credentials to Keychain in one go
        if didMigrate {
            preferences.saveAllCustomConfigCredentials(existingCredentials)
            clearedConfigs.forEach {
                localDatabase.saveCustomConfig(customConfig: $0)
            }
        }
    }

    /// Migrates OpenVPN and IKEv2 server credentials from Realm to Keychain.
    private func migrateServerCredentialsToKeychain() {
        // Skip on fresh install — nothing to migrate
        if preferences.getFirstInstall() == false {
            preferences.deleteIKEv2Credentials()
            preferences.deleteOpenVPNCredentials()
            return
        }

        // Migrate OpenVPN credentials
        if preferences.getOpenVPNCredentials() == nil,
           let realmCreds = localDatabase.getOpenVPNServerCredentials() {
            let model = realmCreds.getModel()
            if !model.username.isEmpty || !model.password.isEmpty {
                preferences.saveOpenVPNCredentials(model)
                localDatabase.clearOpenVPNServerCredentials()
                logger.logD("MigrationRepository", "Migrated OpenVPN server credentials to Keychain")
            }
        }

        // Migrate IKEv2 credentials
        if preferences.getIKEv2Credentials() == nil,
           let realmCreds = localDatabase.getIKEv2ServerCredentials() {
            let model = realmCreds.getModel()
            if !model.username.isEmpty || !model.password.isEmpty {
                preferences.saveIKEv2Credentials(model)
                localDatabase.clearIKEv2ServerCredentials()
                logger.logD("MigrationRepository", "Migrated IKEv2 server credentials to Keychain")
            }
        }
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
        preferences.saveSessionAuthHash(sessionAuth: oldAuthHash)
        preferences.clearUserDefaultsSessionAuth()
        logger.logD("MigrationRepository", "Successfully migrated session auth hash to Keychain")
    }

    /// Migrates the full Session object from Realm to Keychain.
    /// After migration, the Session Realm object is no longer used.
    private func migrateSessionFromRealmToKeychain() {
        // Skip on fresh install — nothing to migrate
        if preferences.getFirstInstall() == false {
            // Clear any stale session from Keychain (survives reinstall)
            sessionStore.clear()
            return
        }

        guard sessionStore.load() == nil else { return }

        // Try to read from Realm
        guard let realmSession = localDatabase.getSession() else {
            return // No session to migrate
        }

        // Convert Realm Session → SessionModel → Keychain
        let sessionModel = SessionModel(from: realmSession)
        sessionStore.save(session: sessionModel)
        localDatabase.clearSessionFromRealm()
        logger.logD("MigrationRepository", "Successfully migrated Session from Realm to Keychain")
    }
}
