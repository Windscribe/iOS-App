//
//  KeyChainDatabaseImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-09.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import SimpleKeychain

class KeyChainDatabaseImpl: KeyChainDatabase {
    private let logger: FileLogger
    private let simpleKeychain = SimpleKeychain(accessGroup: SharedKeys.sharedKeychainGroup)

    init(logger: FileLogger) {
        self.logger = logger
    }

    func save(username: String, password: String) {
        logger.logD(self, "Saving credentials to keychain")
        guard let passwordData = password.data(using: String.Encoding.utf8, allowLossyConversion: false),
              let accountData = username.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrGeneric as String: accountData,
                                    kSecAttrService as String: AppConstants.service,
                                    kSecAttrAccount as String: accountData,
                                    kSecValueData as String: passwordData]
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
        logger.logD(self, "Saved credentials to keychain")
    }

    func retrieve(username: String) -> Data? {
        logger.logD(self, "Retrieving credentials from keychain")
        guard let accountData = username.data(using: String.Encoding.utf8, allowLossyConversion: false) else { return nil }
        let query: [String: Any] = [kSecClass as String: kSecClassGenericPassword,
                                    kSecAttrGeneric as String: accountData,
                                    kSecAttrService as String: AppConstants.service,
                                    kSecAttrAccount as String: accountData,
                                    kSecMatchLimit as String: kSecMatchLimitOne,
                                    kSecReturnPersistentRef as String: kCFBooleanTrue as Any]
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecSuccess {
            logger.logD(self, "Retrieved credentials from keychain")
            return result as? Data
        } else {
            logger.logD(self, "Error when retriving data from keychain. \(errSecItemNotFound)")
            return nil
        }
    }

    func isGhostAccountCreated() -> Bool {
        if let value = try? simpleKeychain.data(forKey: KeyChainkeys.ghostAccountCreated) {
            let isGhostAccountCreated = String(data: value, encoding: .utf8).flatMap(Bool.init) ?? false
            return isGhostAccountCreated
        }
        return false
    }

    func setGhostAccountCreated() {
        try? simpleKeychain.set(true.data, forKey: KeyChainkeys.ghostAccountCreated)
    }
}
