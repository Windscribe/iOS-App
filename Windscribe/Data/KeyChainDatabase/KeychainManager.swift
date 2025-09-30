//
//  KeychainManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-09-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

/// Keychain manager protocol for secure storage operations
protocol KeychainManager {
    /// Sets data in the keychain
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to store under
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Throws: KeychainError if the operation fails
    func setData(_ data: Data, forKey key: String, service: String, accessGroup: String?) throws

    /// Sets a string in the keychain
    /// - Parameters:
    ///   - string: The string to store
    ///   - key: The key to store under
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Throws: KeychainError if the operation fails
    func setString(_ string: String, forKey key: String, service: String, accessGroup: String?) throws

    /// Retrieves data from the keychain
    /// - Parameters:
    ///   - key: The key to retrieve
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Returns: The data if found
    /// - Throws: KeychainError if the operation fails
    func getData(forKey key: String, service: String, accessGroup: String?) throws -> Data

    /// Retrieves a string from the keychain
    /// - Parameters:
    ///   - key: The key to retrieve
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Returns: The string if found
    /// - Throws: KeychainError if the operation fails
    func getString(forKey key: String, service: String, accessGroup: String?) throws -> String

    /// Deletes an item from the keychain
    /// - Parameters:
    ///   - key: The key to delete
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Throws: KeychainError if the operation fails
    func deleteItem(forKey key: String, service: String, accessGroup: String?) throws

    /// Checks if an item exists in the keychain
    /// - Parameters:
    ///   - key: The key to check
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Returns: True if the item exists, false otherwise
    func exists(key: String, service: String, accessGroup: String?) -> Bool

    // MARK: - Bundle ID Service Methods

    /// Set data using Bundle ID as service with access group
    /// - Parameters:
    ///   - data: The data to store
    ///   - key: The key to store under
    /// - Throws: KeychainError if the operation fails
    func setBundleData(_ data: Data, forKey key: String) throws

    /// Get data using Bundle ID as service with access group
    /// - Parameter key: The key to retrieve
    /// - Returns: The data if found, nil if not found
    /// - Throws: KeychainError if the operation fails (except for itemNotFound)
    func getBundleData(forKey key: String) throws -> Data?

    /// Delete item using Bundle ID as service with access group
    /// - Parameter key: The key to delete
    /// - Throws: KeychainError if the operation fails
    func deleteBundleItem(forKey key: String) throws

    /// Get persistent reference for keychain item (for iOS system usage)
    /// - Parameters:
    ///   - key: The key to retrieve
    ///   - service: The service name
    ///   - accessGroup: Optional access group for sharing between apps
    /// - Returns: The persistent reference data if found
    /// - Throws: KeychainError if the operation fails
    func getPersistentRef(forKey key: String, service: String, accessGroup: String?) throws -> Data

    /// Check if item exists using Bundle ID as service with access group
    /// - Parameter key: The key to check
    /// - Returns: True if the item exists, false otherwise
    func bundleExists(key: String) -> Bool
}
