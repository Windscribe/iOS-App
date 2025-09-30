//
//  KeyChainDatabaseImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-09.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class KeyChainDatabaseImpl: KeyChainDatabase {
    private let logger: FileLogger
    private let keychainManager: KeychainManager

    init(logger: FileLogger, keychainManager: KeychainManager) {
        self.logger = logger
        self.keychainManager = keychainManager
    }

    func save(username: String, password: String) {
        logger.logD("KeyChainDatabase", "Saving credentials to keychain")
        do {
            try keychainManager.setString(password, forKey: username, service: AppConstants.service, accessGroup: nil)
            logger.logI("KeyChainDatabase", "Saved credentials to keychain")
        } catch {
            logger.logE("KeyChainDatabase", "Failed to save credentials to keychain: \(error.localizedDescription)")
        }
    }

    func retrieve(username: String) -> Data? {
        logger.logD("KeyChainDatabase", "Retrieving credentials from keychain")
        do {
            let persistentRef = try keychainManager.getPersistentRef(forKey: username, service: AppConstants.service, accessGroup: nil)
            logger.logI("KeyChainDatabase", "Retrieved credentials from keychain")
            return persistentRef
        } catch {
            logger.logE("KeyChainDatabase", "Error when retrieving data from keychain: \(error.localizedDescription)")
            return nil
        }
    }

    func isGhostAccountCreated() -> Bool {
        if let value = try? keychainManager.getBundleData(forKey: KeyChainkeys.ghostAccountCreated) {
            let isGhostAccountCreated = String(data: value, encoding: .utf8).flatMap(Bool.init) ?? false
            return isGhostAccountCreated
        }
        return false
    }

    func setGhostAccountCreated() {
        if let data = "true".data(using: .utf8) {
            try? keychainManager.setBundleData(data, forKey: KeyChainkeys.ghostAccountCreated)
        }
    }
}
