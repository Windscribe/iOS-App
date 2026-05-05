// RealmKeychainPortMigration.swift
// Windscribe
//
// Ports the four Realm-resident legacy entities — Session, OpenVPN/IKEv2
// server credentials, and per-custom-config credentials — into the Keychain
// before the Realm→GRDB swap. Must run on the Realm impl directly: the GRDB
// impl returns nil for these reads (no schema), and the swap happens during
// the LocalDatabase factory closure, before MigrationRepository can run.
//
// Idempotent. Safe on fresh installs (clears stale Keychain entries).
//
// Copyright © 2026 Windscribe. All rights reserved.

import Foundation

enum RealmKeychainPortMigration {
    static func run(
        realm: LocalDatabase,
        preferences: Preferences,
        sessionStore: SessionKeychainStore,
        logger: FileLogger
    ) {
        portSession(realm: realm, preferences: preferences, sessionStore: sessionStore, logger: logger)
        portServerCredentials(realm: realm, preferences: preferences, logger: logger)
        portCustomConfigCredentials(realm: realm, preferences: preferences, logger: logger)
    }

    private static func portSession(
        realm: LocalDatabase,
        preferences: Preferences,
        sessionStore: SessionKeychainStore,
        logger: FileLogger
    ) {
        if preferences.getFirstInstall() == false {
            sessionStore.clear()
            return
        }
        guard sessionStore.load() == nil else { return }
        guard let sessionModel = realm.getSession() else { return }
        sessionStore.save(session: sessionModel)
        realm.clearSessionFromRealm()
        logger.logD("RealmKeychainPort", "Migrated Session from Realm to Keychain")
    }

    private static func portServerCredentials(
        realm: LocalDatabase,
        preferences: Preferences,
        logger: FileLogger
    ) {
        if preferences.getFirstInstall() == false {
            preferences.deleteIKEv2Credentials()
            preferences.deleteOpenVPNCredentials()
            return
        }

        if preferences.getOpenVPNCredentials() == nil,
           let realmCreds = realm.getOpenVPNServerCredentials() {
            let model = realmCreds.getModel()
            if !model.username.isEmpty || !model.password.isEmpty {
                preferences.saveOpenVPNCredentials(model)
                realm.clearOpenVPNServerCredentials()
                logger.logD("RealmKeychainPort", "Migrated OpenVPN server credentials to Keychain")
            }
        }

        if preferences.getIKEv2Credentials() == nil,
           let realmCreds = realm.getIKEv2ServerCredentials() {
            let model = realmCreds.getModel()
            if !model.username.isEmpty || !model.password.isEmpty {
                preferences.saveIKEv2Credentials(model)
                realm.clearIKEv2ServerCredentials()
                logger.logD("RealmKeychainPort", "Migrated IKEv2 server credentials to Keychain")
            }
        }
    }

    private static func portCustomConfigCredentials(
        realm: LocalDatabase,
        preferences: Preferences,
        logger: FileLogger
    ) {
        if preferences.getFirstInstall() == false {
            preferences.deleteAllCustomConfigCredentials()
            return
        }

        let customConfigs = realm.getCustomConfigs()
        var existingCredentials = preferences.getAllCustomConfigCredentials()
        var clearedConfigs = [CustomConfigModel]()
        var didMigrate = false

        for config in customConfigs {
            guard !(config.username.isEmpty && config.password.isEmpty) else { continue }
            if existingCredentials[config.id] != nil { continue }

            existingCredentials[config.id] = ServerCredentialsModel(username: config.username, password: config.password)

            var cleared = config
            cleared.username = ""
            cleared.password = ""
            clearedConfigs.append(cleared)
            didMigrate = true
        }

        if didMigrate {
            preferences.saveAllCustomConfigCredentials(existingCredentials)
            for config in clearedConfigs {
                realm.saveCustomConfig(customConfig: config)
            }
            logger.logD("RealmKeychainPort", "Migrated \(clearedConfigs.count) custom config credentials to Keychain")
        }
    }
}
