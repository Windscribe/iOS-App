//
//  PreferencesImpl+Keychain.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/04/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

// MARK: - Keychain-backed Access

extension PreferencesImpl {

    // MARK: - Generic Keychain Helpers

    private func saveCredentials(_ credentials: ServerCredentialsModel, forKey key: String) {
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        do {
            try keychainManager.setBundleData(data, forKey: key)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to save credentials for key '\(key)': \(error)")
        }
    }

    private func getCredentials(forKey key: String) -> ServerCredentialsModel? {
        let data: Data?
        do {
            data = try keychainManager.getBundleData(forKey: key)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to load credentials for key '\(key)': \(error)")
            return nil
        }
        guard let data else { return nil }
        return try? JSONDecoder().decode(ServerCredentialsModel.self, from: data)
    }

    private func deleteCredentials(forKey key: String) {
        do {
            try keychainManager.deleteBundleItem(forKey: key)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to delete credentials for key '\(key)': \(error)")
        }
    }

    // MARK: - Session Auth

    func clearUserDefaultsSessionAuth() {
        sharedDefault?.removeObject(forKey: SharedKeys.activeSessionAuthHash)
    }

    func clearSessionAuth() {
        do {
            try keychainManager.deleteBundleItem(forKey: SharedKeys.activeSessionAuthHash)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to clear session auth: \(error)")
        }
    }

    func getUserDefaultsSessionAuth() -> String? {
        return getString(forKey: SharedKeys.activeSessionAuthHash)
    }

    func saveSessionAuthHash(sessionAuth: String) {
        guard let data = sessionAuth.data(using: .utf8) else { return }
        do {
            try keychainManager.setBundleData(data, forKey: SharedKeys.activeSessionAuthHash)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to save session auth hash: \(error)")
        }
    }

    func getSessionAuthHash() -> String? {
        let data: Data?
        do {
            data = try keychainManager.getBundleData(forKey: SharedKeys.activeSessionAuthHash)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to load session auth hash: \(error)")
            return nil
        }
        return data.flatMap { String(data: $0, encoding: .utf8) }
    }

    // MARK: - Session Persistence

    func saveStoredSession(_ data: Data) throws {
        try keychainManager.setBundleData(data, forKey: SharedKeys.keychainStoredSession)
    }

    func getStoredSession() throws -> Data? {
        return try keychainManager.getBundleData(forKey: SharedKeys.keychainStoredSession)
    }

    func deleteStoredSession() {
        do {
            try keychainManager.deleteBundleItem(forKey: SharedKeys.keychainStoredSession)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to delete stored session: \(error)")
        }
    }

    // MARK: - OpenVPN Server Credentials

    func saveOpenVPNCredentials(_ credentials: ServerCredentialsModel) {
        saveCredentials(credentials, forKey: SharedKeys.keychainOpenVPNCred)
    }

    func getOpenVPNCredentials() -> ServerCredentialsModel? {
        return getCredentials(forKey: SharedKeys.keychainOpenVPNCred)
    }

    func deleteOpenVPNCredentials() {
        deleteCredentials(forKey: SharedKeys.keychainOpenVPNCred)
    }

    // MARK: - IKEv2 Server Credentials

    func saveIKEv2Credentials(_ credentials: ServerCredentialsModel) {
        saveCredentials(credentials, forKey: SharedKeys.keychainIKEv2Cred)
    }

    func getIKEv2Credentials() -> ServerCredentialsModel? {
        return getCredentials(forKey: SharedKeys.keychainIKEv2Cred)
    }

    func deleteIKEv2Credentials() {
        deleteCredentials(forKey: SharedKeys.keychainIKEv2Cred)
    }

    // MARK: - Custom Config Credentials (single dictionary entry)

    private func loadAllCustomConfigCredentials() -> [String: ServerCredentialsModel] {
        let data: Data?
        do {
            data = try keychainManager.getBundleData(forKey: SharedKeys.keychainCustomConfigCreds)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to load custom config credentials: \(error)")
            return [:]
        }
        guard let data else { return [:] }
        return (try? JSONDecoder().decode([String: ServerCredentialsModel].self, from: data)) ?? [:]
    }

    func saveAllCustomConfigCredentials(_ dict: [String: ServerCredentialsModel]) {
        guard let data = try? JSONEncoder().encode(dict) else { return }
        do {
            try keychainManager.setBundleData(data, forKey: SharedKeys.keychainCustomConfigCreds)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to save custom config credentials: \(error)")
        }
    }

    func saveCustomConfigCredentials(configId: String, credentials: ServerCredentialsModel) {
        var dict = loadAllCustomConfigCredentials()
        dict[configId] = credentials
        saveAllCustomConfigCredentials(dict)
    }

    func getCustomConfigCredentials(configId: String) -> ServerCredentialsModel? {
        return loadAllCustomConfigCredentials()[configId]
    }

    func getAllCustomConfigCredentials() -> [String: ServerCredentialsModel] {
        return loadAllCustomConfigCredentials()
    }

    func deleteCustomConfigCredentials(configId: String) {
        var dict = loadAllCustomConfigCredentials()
        dict.removeValue(forKey: configId)
        saveAllCustomConfigCredentials(dict)
    }

    func deleteAllCustomConfigCredentials() {
        do {
            try keychainManager.deleteBundleItem(forKey: SharedKeys.keychainCustomConfigCreds)
        } catch {
            logger.logE("PreferencesImpl+Keychain", "Failed to delete all custom config credentials: \(error)")
        }
    }
}
