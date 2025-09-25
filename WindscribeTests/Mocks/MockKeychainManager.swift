//
//  MockKeychainManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-09-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockKeychainManager: KeychainManager {

    // Mock storage
    private var storage: [String: Data] = [:]

    // Mock behavior flags
    var shouldThrowError = false
    var errorToThrow: KeychainError = .itemNotFound

    func setData(_ data: Data, forKey key: String, service: String, accessGroup: String?) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        let storageKey = buildStorageKey(key: key, service: service, accessGroup: accessGroup)
        storage[storageKey] = data
    }

    func setString(_ string: String, forKey key: String, service: String, accessGroup: String?) throws {
        guard let data = string.data(using: .utf8) else {
            throw KeychainError.unknown(message: "Unable to convert string to data")
        }
        try setData(data, forKey: key, service: service, accessGroup: accessGroup)
    }

    func getData(forKey key: String, service: String, accessGroup: String?) throws -> Data {
        if shouldThrowError {
            throw errorToThrow
        }
        let storageKey = buildStorageKey(key: key, service: service, accessGroup: accessGroup)
        guard let data = storage[storageKey] else {
            throw KeychainError.itemNotFound
        }
        return data
    }

    func getString(forKey key: String, service: String, accessGroup: String?) throws -> String {
        let data = try getData(forKey: key, service: service, accessGroup: accessGroup)
        guard let string = String(data: data, encoding: .utf8) else {
            throw KeychainError.unknown(message: "Unable to convert data to string")
        }
        return string
    }

    func deleteItem(forKey key: String, service: String, accessGroup: String?) throws {
        if shouldThrowError {
            throw errorToThrow
        }
        let storageKey = buildStorageKey(key: key, service: service, accessGroup: accessGroup)
        storage.removeValue(forKey: storageKey)
    }

    func exists(key: String, service: String, accessGroup: String?) -> Bool {
        let storageKey = buildStorageKey(key: key, service: service, accessGroup: accessGroup)
        return storage[storageKey] != nil
    }

    // MARK: - Bundle ID Service Methods

    func setBundleData(_ data: Data, forKey key: String) throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw KeychainError.unknown(message: "Unable to get bundle identifier")
        }

        let accessGroup = "test.bundle.shared.keychain"
        try setData(data, forKey: key, service: bundleId, accessGroup: accessGroup)
    }

    func getBundleData(forKey key: String) throws -> Data? {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw KeychainError.unknown(message: "Unable to get bundle identifier")
        }

        let accessGroup = "test.bundle.shared.keychain"
        do {
            return try getData(forKey: key, service: bundleId, accessGroup: accessGroup)
        } catch KeychainError.itemNotFound {
            return nil
        }
    }

    func deleteBundleItem(forKey key: String) throws {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            throw KeychainError.unknown(message: "Unable to get bundle identifier")
        }

        let accessGroup = "test.bundle.shared.keychain"
        try deleteItem(forKey: key, service: bundleId, accessGroup: accessGroup)
    }

    func bundleExists(key: String) -> Bool {
        guard let bundleId = Bundle.main.bundleIdentifier else {
            return false
        }

        let accessGroup = "test.bundle.shared.keychain"
        return exists(key: key, service: bundleId, accessGroup: accessGroup)
    }

    // Helper methods
    func clearStorage() {
        storage.removeAll()
    }

    func getStorageCount() -> Int {
        return storage.count
    }

    private func buildStorageKey(key: String, service: String, accessGroup: String?) -> String {
        if let accessGroup = accessGroup {
            return "\(service):\(accessGroup):\(key)"
        } else {
            return "\(service):\(key)"
        }
    }
}