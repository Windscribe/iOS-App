//
//  KeyChainDatabaseTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-09-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class KeyChainDatabaseTests: XCTestCase {

    var mockContainer: Container!
    var keyChainDatabase: KeyChainDatabase!

    // Test constants
    private let testUsername = "testuser@example.com"
    private let testPassword = "testPassword123"
    private let testUsername2 = "testuser2@example.com"
    private let testPassword2 = "testPassword456"

    override func setUp() {
        super.setUp()
        mockContainer = Container()

        // Register KeychainManager with real implementation for integration testing
        mockContainer.register(KeychainManager.self) { _ in
            return KeychainManagerImpl(logger: MockLogger())
        }.inObjectScope(.container)

        // Register KeyChainDatabase with real implementation
        mockContainer.register(KeyChainDatabase.self) { r in
            return KeyChainDatabaseImpl(logger: MockLogger(), keychainManager: r.resolve(KeychainManager.self)!)
        }.inObjectScope(.container)

        keyChainDatabase = mockContainer.resolve(KeyChainDatabase.self)!
    }

    override func tearDown() {
        // Clean up test data
        cleanupTestData()
        mockContainer = nil
        keyChainDatabase = nil
        super.tearDown()
    }

    private func cleanupTestData() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Clean up VPN credentials
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)
        try? keychainManager.deleteItem(forKey: testUsername2, service: AppConstants.service, accessGroup: nil)

        // Clean up ghost account flag
        try? keychainManager.deleteBundleItem(forKey: KeyChainkeys.ghostAccountCreated)
    }

    // MARK: - VPN Credentials Tests

    func test_saveAndRetrieveCredentials_shouldStoreAndRetrievePassword() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)

        // Save credentials
        keyChainDatabase.save(username: testUsername, password: testPassword)

        // Retrieve credentials
        let retrievedData = keyChainDatabase.retrieve(username: testUsername)
        XCTAssertNotNil(retrievedData, "Retrieved data should not be nil")

        if let data = retrievedData,
           let retrievedPassword = String(data: data, encoding: .utf8) {
            XCTAssertEqual(retrievedPassword, testPassword, "Retrieved password should match saved password")
        } else {
            XCTFail("Failed to convert retrieved data to string")
        }
    }

    func test_saveCredentials_existingUsername_shouldUpdatePassword() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)

        // Save initial credentials
        keyChainDatabase.save(username: testUsername, password: testPassword)

        // Verify initial save
        let initialData = keyChainDatabase.retrieve(username: testUsername)
        XCTAssertNotNil(initialData)
        XCTAssertEqual(String(data: initialData!, encoding: .utf8), testPassword)

        // Update with new password
        let newPassword = "newPassword789"
        keyChainDatabase.save(username: testUsername, password: newPassword)

        // Verify update
        let updatedData = keyChainDatabase.retrieve(username: testUsername)
        XCTAssertNotNil(updatedData)
        XCTAssertEqual(String(data: updatedData!, encoding: .utf8), newPassword)
    }

    func test_retrieveCredentials_nonExistentUsername_shouldReturnNil() {
        // Ensure username doesn't exist
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: "nonexistent@example.com", service: AppConstants.service, accessGroup: nil)

        // Attempt to retrieve non-existent credentials
        let retrievedData = keyChainDatabase.retrieve(username: "nonexistent@example.com")
        XCTAssertNil(retrievedData, "Retrieving non-existent credentials should return nil")
    }

    func test_saveMultipleCredentials_shouldIsolateByUsername() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)
        try? keychainManager.deleteItem(forKey: testUsername2, service: AppConstants.service, accessGroup: nil)

        // Save different credentials for different usernames
        keyChainDatabase.save(username: testUsername, password: testPassword)
        keyChainDatabase.save(username: testUsername2, password: testPassword2)

        // Retrieve and verify both
        let data1 = keyChainDatabase.retrieve(username: testUsername)
        let data2 = keyChainDatabase.retrieve(username: testUsername2)

        XCTAssertNotNil(data1)
        XCTAssertNotNil(data2)
        XCTAssertEqual(String(data: data1!, encoding: .utf8), testPassword)
        XCTAssertEqual(String(data: data2!, encoding: .utf8), testPassword2)
        XCTAssertNotEqual(String(data: data1!, encoding: .utf8), String(data: data2!, encoding: .utf8))
    }

    // MARK: - Ghost Account Tests

    func test_ghostAccount_initiallyNotCreated() {
        // Clean up first
        try? mockContainer.resolve(KeychainManager.self)!.deleteBundleItem(forKey: KeyChainkeys.ghostAccountCreated)

        // Initially should not be created
        XCTAssertFalse(keyChainDatabase.isGhostAccountCreated(), "Ghost account should initially not be created")
    }

    func test_setGhostAccountCreated_shouldSetFlagToTrue() {
        // Clean up first
        try? mockContainer.resolve(KeychainManager.self)!.deleteBundleItem(forKey: KeyChainkeys.ghostAccountCreated)

        // Initially false
        XCTAssertFalse(keyChainDatabase.isGhostAccountCreated())

        // Set ghost account created
        keyChainDatabase.setGhostAccountCreated()

        // Should now be true
        XCTAssertTrue(keyChainDatabase.isGhostAccountCreated(), "Ghost account should be marked as created")
    }

    func test_ghostAccount_persistsAcrossInstances() {
        // Clean up first
        try? mockContainer.resolve(KeychainManager.self)!.deleteBundleItem(forKey: KeyChainkeys.ghostAccountCreated)

        // Set ghost account created
        keyChainDatabase.setGhostAccountCreated()

        // Create new instance to verify persistence
        let newKeyChainDatabase = KeyChainDatabaseImpl(
            logger: MockLogger(),
            keychainManager: mockContainer.resolve(KeychainManager.self)!
        )

        // Should still be true
        XCTAssertTrue(newKeyChainDatabase.isGhostAccountCreated(), "Ghost account flag should persist across instances")
    }

    // MARK: - Data Isolation Tests

    func test_vpnCredentialsAndGhostAccount_shouldBeIsolated() {
        // Clean up first
        cleanupTestData()

        // Save VPN credentials
        keyChainDatabase.save(username: testUsername, password: testPassword)

        // Set ghost account
        keyChainDatabase.setGhostAccountCreated()

        // Verify both work independently
        let retrievedData = keyChainDatabase.retrieve(username: testUsername)
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(String(data: retrievedData!, encoding: .utf8), testPassword)
        XCTAssertTrue(keyChainDatabase.isGhostAccountCreated())

        // Delete VPN credentials, ghost account should remain
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)

        XCTAssertNil(keyChainDatabase.retrieve(username: testUsername))
        XCTAssertTrue(keyChainDatabase.isGhostAccountCreated(), "Ghost account should remain after VPN credential deletion")
    }

    // MARK: - Edge Cases

    func test_saveCredentials_emptyPassword_shouldStore() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)

        let emptyPassword = ""
        keyChainDatabase.save(username: testUsername, password: emptyPassword)

        let retrievedData = keyChainDatabase.retrieve(username: testUsername)
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(String(data: retrievedData!, encoding: .utf8), emptyPassword)
    }

    func test_saveCredentials_specialCharacters_shouldStore() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)

        let specialPassword = "!@#$%^&*()_+-={}[]|\\:;\"'<>?,./"
        keyChainDatabase.save(username: testUsername, password: specialPassword)

        let retrievedData = keyChainDatabase.retrieve(username: testUsername)
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(String(data: retrievedData!, encoding: .utf8), specialPassword)
    }

    func test_saveCredentials_longPassword_shouldStore() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: testUsername, service: AppConstants.service, accessGroup: nil)

        let longPassword = String(repeating: "SecurePassword123!", count: 50)
        keyChainDatabase.save(username: testUsername, password: longPassword)

        let retrievedData = keyChainDatabase.retrieve(username: testUsername)
        XCTAssertNotNil(retrievedData)
        XCTAssertEqual(String(data: retrievedData!, encoding: .utf8), longPassword)
    }
}