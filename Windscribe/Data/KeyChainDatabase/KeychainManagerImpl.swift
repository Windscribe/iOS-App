//
//  KeychainManagerImpl.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-09-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Security

/// Custom error type for keychain operations
enum KeychainError: Error, LocalizedError {
    case operationNotImplemented
    case invalidParameters
    case userCanceled
    case itemNotAvailable
    case authFailed
    case duplicateItem
    case itemNotFound
    case interactionNotAllowed
    case decodeFailed
    case other(status: OSStatus)
    case unknown(message: String)

    init(status: OSStatus) {
        switch status {
        case errSecUnimplemented: self = .operationNotImplemented
        case errSecParam: self = .invalidParameters
        case errSecUserCanceled: self = .userCanceled
        case errSecNotAvailable: self = .itemNotAvailable
        case errSecAuthFailed: self = .authFailed
        case errSecDuplicateItem: self = .duplicateItem
        case errSecItemNotFound: self = .itemNotFound
        case errSecInteractionNotAllowed: self = .interactionNotAllowed
        case errSecDecode: self = .decodeFailed
        default: self = .other(status: status)
        }
    }

    var errorDescription: String? {
        switch self {
        case .operationNotImplemented:
            return "errSecUnimplemented: A function or operation is not implemented."
        case .invalidParameters:
            return "errSecParam: One or more parameters passed to the function are not valid."
        case .userCanceled:
            return "errSecUserCanceled: User canceled the operation."
        case .itemNotAvailable:
            return "errSecNotAvailable: No trust results are available."
        case .authFailed:
            return "errSecAuthFailed: Authorization and/or authentication failed."
        case .duplicateItem:
            return "errSecDuplicateItem: The item already exists."
        case .itemNotFound:
            return "errSecItemNotFound: The item cannot be found."
        case .interactionNotAllowed:
            return "errSecInteractionNotAllowed: Interaction with the Security Server is not allowed."
        case .decodeFailed:
            return "errSecDecode: Unable to decode the provided data."
        case .other(let status):
            return "Unspecified Keychain error: \(status)."
        case .unknown(let message):
            return "Unknown error: \(message)."
        }
    }
}

/// Keychain manager implementation using Security framework directly
class KeychainManagerImpl: KeychainManager {
    private let logger: FileLogger

    init(logger: FileLogger) {
        self.logger = logger
    }

    /// Sets data in the keychain
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to store under
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Throws: KeychainError if the operation fails
    func setData(_ data: Data, forKey key: String, service: String, accessGroup: String? = nil) throws {
        let query = buildQuery(key: key, service: service, accessGroup: accessGroup, data: data)

        let addStatus = SecItemAdd(query as CFDictionary, nil)

        if addStatus == errSecDuplicateItem {
            // Item exists, update it
            let updateQuery = buildBaseQuery(key: key, service: service, accessGroup: accessGroup)
            let updateAttributes: [String: Any] = [kSecValueData as String: data]
            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)

            if updateStatus != errSecSuccess {
                let error = KeychainError(status: updateStatus)
                logger.logE("KeychainManager", "Failed to update data for key '\(key)' in service '\(service)': \(error.localizedDescription)")
                throw error
            }
        } else if addStatus != errSecSuccess {
            let error = KeychainError(status: addStatus)
            logger.logE("KeychainManager", "Failed to add data for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }
    }

    /// Sets a string in the keychain
    /// - Parameters:
    ///   - string: The string to store
    ///   - key: The key to store under
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Throws: KeychainError if the operation fails
    func setString(_ string: String, forKey key: String, service: String, accessGroup: String? = nil) throws {
        guard let data = string.data(using: .utf8) else {
            let error = KeychainError.unknown(message: "Unable to convert string to data")
            logger.logE("KeychainManager", "Failed to convert string to data for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }
        try setData(data, forKey: key, service: service, accessGroup: accessGroup)
    }

    /// Retrieves data from the keychain
    /// - Parameters:
    ///   - key: The key to retrieve
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Returns: The data if found
    /// - Throws: KeychainError if the operation fails
    func getData(forKey key: String, service: String, accessGroup: String? = nil) throws -> Data {
        let query = buildRetrievalQuery(key: key, service: service, accessGroup: accessGroup)

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status != errSecSuccess {
            let error = KeychainError(status: status)
            logger.logE("KeychainManager", "Failed to retrieve data for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }

        guard let data = result as? Data else {
            let error = KeychainError.unknown(message: "Unable to cast the retrieved item to a Data value")
            logger.logE("KeychainManager", "Failed to cast retrieved item to Data for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }

        return data
    }

    /// Retrieves a string from the keychain
    /// - Parameters:
    ///   - key: The key to retrieve
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Returns: The string if found
    /// - Throws: KeychainError if the operation fails
    func getString(forKey key: String, service: String, accessGroup: String? = nil) throws -> String {
        let data = try getData(forKey: key, service: service, accessGroup: accessGroup)

        guard let string = String(data: data, encoding: .utf8) else {
            let error = KeychainError.unknown(message: "Unable to convert the retrieved item to a String value")
            logger.logE("KeychainManager", "Failed to convert retrieved data to String for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }

        return string
    }

    /// Deletes an item from the keychain
    /// - Parameters:
    ///   - key: The key to delete
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Throws: KeychainError if the operation fails
    func deleteItem(forKey key: String, service: String, accessGroup: String? = nil) throws {
        let query = buildBaseQuery(key: key, service: service, accessGroup: accessGroup)
        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            let error = KeychainError(status: status)
            logger.logE("KeychainManager", "Failed to delete item for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }
    }

    /// Checks if an item exists in the keychain
    /// - Parameters:
    ///   - key: The key to check
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Returns: True if the item exists, false otherwise
    func exists(key: String, service: String, accessGroup: String? = nil) -> Bool {
        let query = buildBaseQuery(key: key, service: service, accessGroup: accessGroup)
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Bundle ID Service Methods

    func setBundleData(_ data: Data, forKey key: String) throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            let error = KeychainError.unknown(message: "Unable to get bundle identifier")
            logger.logE("KeychainManager", "Failed to get bundle identifier for key '\(key)': \(error.localizedDescription)")
            throw error
        }

        let accessGroup = SharedKeys.sharedKeychainGroup
        try setData(data, forKey: key, service: bundleId, accessGroup: accessGroup)
    }

    func getBundleData(forKey key: String) throws -> Data? {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            let error = KeychainError.unknown(message: "Unable to get bundle identifier")
            logger.logE("KeychainManager", "Failed to get bundle identifier for key '\(key)': \(error.localizedDescription)")
            throw error
        }

        let accessGroup = SharedKeys.sharedKeychainGroup
        do {
            return try getData(forKey: key, service: bundleId, accessGroup: accessGroup)
        } catch KeychainError.itemNotFound {
            return nil
        }
    }

    func deleteBundleItem(forKey key: String) throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            let error = KeychainError.unknown(message: "Unable to get bundle identifier")
            logger.logE("KeychainManager", "Failed to get bundle identifier for key '\(key)': \(error.localizedDescription)")
            throw error
        }

        let accessGroup = SharedKeys.sharedKeychainGroup
        try deleteItem(forKey: key, service: bundleId, accessGroup: accessGroup)
    }

    func bundleExists(key: String) -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return false
        }

        let accessGroup = SharedKeys.sharedKeychainGroup
        return exists(key: key, service: bundleId, accessGroup: accessGroup)
    }

    // MARK: - Private Helper Methods

    private func buildBaseQuery(key: String, service: String, accessGroup: String?) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        return query
    }

    private func buildQuery(key: String, service: String, accessGroup: String?, data: Data) -> [String: Any] {
        var query = buildBaseQuery(key: key, service: service, accessGroup: accessGroup)
        query[kSecValueData as String] = data
        query[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlock
        return query
    }

    private func buildRetrievalQuery(key: String, service: String, accessGroup: String?) -> [String: Any] {
        var query = buildBaseQuery(key: key, service: service, accessGroup: accessGroup)
        query[kSecReturnData as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }

    private func buildPersistentRefQuery(key: String, service: String, accessGroup: String?) -> [String: Any] {
        var query = buildBaseQuery(key: key, service: service, accessGroup: accessGroup)
        query[kSecReturnPersistentRef as String] = kCFBooleanTrue
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        return query
    }

    /// Gets persistent reference for keychain item (for iOS system usage)
    func getPersistentRef(forKey key: String, service: String, accessGroup: String?) throws -> Data {
        let query = buildPersistentRefQuery(key: key, service: service, accessGroup: accessGroup)

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        if status != errSecSuccess {
            let error = KeychainError(status: status)
            logger.logE("KeychainManager", "Failed to retrieve persistent ref for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }

        guard let data = result as? Data else {
            let error = KeychainError.unknown(message: "Unable to cast the retrieved persistent ref to a Data value")
            logger.logE("KeychainManager", "Failed to cast retrieved persistent ref to Data for key '\(key)' in service '\(service)': \(error.localizedDescription)")
            throw error
        }

        return data
    }
}
