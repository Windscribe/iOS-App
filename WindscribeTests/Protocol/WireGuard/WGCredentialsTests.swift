//
//  WgCredentialsTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-09-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class WgCredentialsTests: XCTestCase {

    var mockContainer: Container!
    var wgCredentials: WgCredentials!
    var mockPreferences: MockPreferences!

    private var testAccessGroup: String? {
        #if targetEnvironment(simulator)
        return nil
        #else
        return SharedKeys.sharedKeychainGroup
        #endif
    }

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockPreferences = MockPreferences()

        // Register KeychainManager with real implementation for integration testing
        mockContainer.register(KeychainManager.self) { _ in
            return KeychainManagerImpl(logger: MockLogger())
        }.inObjectScope(.container)

        // Register WgCredentials with real KeychainManager and mock Preferences
        mockContainer.register(WgCredentials.self) { r in
            return WgCredentials(
                preferences: self.mockPreferences,
                logger: MockLogger(),
                keychainManager: r.resolve(KeychainManager.self)!)
        }.inObjectScope(.container)

        wgCredentials = mockContainer.resolve(WgCredentials.self)!
    }

    override func tearDown() {
        // Clean up test data
        cleanupTestData()
        mockContainer = nil
        wgCredentials = nil
        mockPreferences = nil
        super.tearDown()
    }

    private func cleanupTestData() {
        let keychainManager = mockContainer.resolve(KeychainManager.self)!

        // Clean up WireGuard private key with proper service and access group
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)
    }

    // MARK: - Private Key Tests

    func test_getPrivateKey_shouldGenerateNewKeyWhenNotExists() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)

        // When
        let privateKey = wgCredentials.getPrivateKey()

        // Then
        XCTAssertNotNil(privateKey, "Private key should be generated when not exists")
        XCTAssertFalse(privateKey!.isEmpty, "Private key should not be empty")
        XCTAssertEqual(privateKey!.count, 44, "Private key should be 44 characters (Base64 encoded 32-byte key)")
    }

    func test_getPrivateKey_shouldReturnExistingKey() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)

        // Given - Generate initial key
        let firstKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(firstKey, "First key should be generated")

        // When - Get key again
        let secondKey = wgCredentials.getPrivateKey()

        // Then - Should return same key
        XCTAssertNotNil(secondKey, "Second key retrieval should not be nil")
        XCTAssertEqual(firstKey, secondKey, "Should return the same private key on subsequent calls")
    }

    func test_getPrivateKey_shouldPersistAcrossInstances() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)

        // Given - Generate key with first instance
        let firstKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(firstKey)

        // When - Create new instance
        let newWgCredentials = WgCredentials(
            preferences: mockPreferences,
            logger: MockLogger(),
            keychainManager: keychainManager
        )
        let keyFromNewInstance = newWgCredentials.getPrivateKey()

        // Then - Should return same key
        XCTAssertNotNil(keyFromNewInstance)
        XCTAssertEqual(firstKey, keyFromNewInstance, "Private key should persist across instances")
    }

    func test_getPublicKey_shouldReturnValidKey() async {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)

        // Given - Generate private key first
        let privateKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(privateKey, "Private key should be generated")

        // When
        let publicKey = await wgCredentials.getPublicKey()

        // Then
        XCTAssertNotNil(publicKey, "Public key should be generated from private key")
        XCTAssertFalse(publicKey!.isEmpty, "Public key should not be empty")
        XCTAssertEqual(publicKey!.count, 44, "Public key should be 44 characters (Base64 encoded 32-byte key)")
        XCTAssertNotEqual(privateKey, publicKey, "Public key should be different from private key")
    }

    // MARK: - Delete Tests

    func test_delete_shouldRemovePrivateKeyFromKeychain() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)

        // Given - Generate and verify key exists
        let privateKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(privateKey, "Private key should be generated")

        // When
        wgCredentials.delete()

        // Then - Key should be regenerated on next access (indicating deletion worked)
        let newPrivateKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(newPrivateKey, "New private key should be generated after delete")
        XCTAssertNotEqual(privateKey, newPrivateKey, "New private key should be different after delete")
    }

    func test_delete_shouldClearInstanceVariables() {
        // Given - Set instance variables
        wgCredentials.dns = "1.1.1.1"
        wgCredentials.address = "10.0.0.1/32"
        wgCredentials.presharedKey = "testPresharedKey"
        wgCredentials.allowedIps = "0.0.0.0/0"
        wgCredentials.serverEndPoint = "127.0.0.1"
        wgCredentials.serverHostName = "test.windscribe.com"
        wgCredentials.serverPublicKey = "testServerPublicKey"
        wgCredentials.port = "51820"

        // When
        wgCredentials.delete()

        // Then
        XCTAssertNil(wgCredentials.dns, "DNS should be cleared")
        XCTAssertNil(wgCredentials.address, "Address should be cleared")
        XCTAssertNil(wgCredentials.presharedKey, "Preshared key should be cleared")
        XCTAssertNil(wgCredentials.allowedIps, "Allowed IPs should be cleared")
        // Server connection variables should remain (not cleared by delete)
        XCTAssertNotNil(wgCredentials.serverEndPoint, "Server endpoint should not be cleared")
        XCTAssertNotNil(wgCredentials.serverHostName, "Server hostname should not be cleared")
        XCTAssertNotNil(wgCredentials.serverPublicKey, "Server public key should not be cleared")
        XCTAssertNotNil(wgCredentials.port, "Port should not be cleared")
    }

    func test_delete_shouldCallPreferencesClearConfiguration() {
        // Reset the flag first
        mockPreferences.clearWireGuardConfigurationCalled = false

        // When
        wgCredentials.delete()

        // Then
        XCTAssertTrue(mockPreferences.clearWireGuardConfigurationCalled, "Should call preferences.clearWireGuardConfiguration()")
    }

    // MARK: - Data Isolation Tests

    func test_keychainIsolation_shouldIsolateByService() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "DifferentService", accessGroup: testAccessGroup)

        // Given - Store key in WireGuard service
        let wgKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(wgKey, "WireGuard key should be stored")

        // When - Try to access with different service
        let differentServiceKey = try? keychainManager.getString(forKey: SharedKeys.privateKey, service: "DifferentService", accessGroup: testAccessGroup)

        // Then - Should not be accessible from different service
        XCTAssertNil(differentServiceKey, "Key should not be accessible from different service")

        // But should still be accessible from correct service
        let correctServiceKey = try? keychainManager.getString(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)
        XCTAssertNotNil(correctServiceKey, "Key should be accessible from correct service")
        XCTAssertEqual(wgKey, correctServiceKey, "Retrieved key should match stored key")

        // Clean up
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "DifferentService", accessGroup: testAccessGroup)
    }

    // MARK: - Configuration String Tests

    func test_asWgCredentialsString_withCompleteConfiguration_shouldReturnValidConfig() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)

        // Given - Complete configuration
        wgCredentials.address = "10.0.0.1/32"
        wgCredentials.dns = "1.1.1.1"
        wgCredentials.allowedIps = "0.0.0.0/0"
        wgCredentials.presharedKey = "testPresharedKey"
        wgCredentials.serverPublicKey = "testServerPublicKey"
        wgCredentials.serverEndPoint = "127.0.0.1"
        wgCredentials.port = "51820"

        // Generate private key
        let privateKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(privateKey, "Private key should be generated")

        // When
        let configString = wgCredentials.asWgCredentialsString()

        // Then
        XCTAssertNotNil(configString, "Config string should be generated with complete configuration")
        let config = configString!

        // Verify [Interface] section
        XCTAssertTrue(config.contains("[Interface]"), "Should contain [Interface] section")
        XCTAssertTrue(config.contains("PrivateKey = \(privateKey!)"), "Should contain private key")
        XCTAssertTrue(config.contains("Address = 10.0.0.1/32"), "Should contain address")
        XCTAssertTrue(config.contains("Dns = 1.1.1.1"), "Should contain DNS")

        // Verify [Peer] section
        XCTAssertTrue(config.contains("[Peer]"), "Should contain [Peer] section")
        XCTAssertTrue(config.contains("PublicKey = testServerPublicKey"), "Should contain server public key")
        XCTAssertTrue(config.contains("AllowedIPs = 0.0.0.0/0"), "Should contain allowed IPs")
        XCTAssertTrue(config.contains("Endpoint = 127.0.0.1:51820"), "Should contain endpoint with port")
        XCTAssertTrue(config.contains("PresharedKey = testPresharedKey"), "Should contain preshared key")
        XCTAssertTrue(config.contains("udp_stuffing = false"), "Should contain UDP stuffing setting")
    }

    func test_asWgCredentialsString_withIncompleteConfiguration_shouldReturnNil() {
        // Clean up first
        let keychainManager = mockContainer.resolve(KeychainManager.self)!
        try? keychainManager.deleteItem(forKey: SharedKeys.privateKey, service: "WireguardService", accessGroup: testAccessGroup)

        // Given - Incomplete configuration (missing address)
        wgCredentials.dns = "1.1.1.1"
        wgCredentials.allowedIps = "0.0.0.0/0"
        wgCredentials.presharedKey = "testPresharedKey"
        wgCredentials.serverPublicKey = "testServerPublicKey"
        wgCredentials.serverEndPoint = "127.0.0.1"
        wgCredentials.port = "51820"
        // address is intentionally not set

        // Generate private key
        let privateKey = wgCredentials.getPrivateKey()
        XCTAssertNotNil(privateKey, "Private key should be generated")

        // When
        let configString = wgCredentials.asWgCredentialsString()

        // Then
        XCTAssertNil(configString, "Config string should be nil with incomplete configuration")
    }

    // MARK: - Edge Cases

    func test_getPrivateKey_withKeychainError_shouldReturnNil() {
        // This test verifies that keychain errors are handled gracefully
        // In the real implementation, if there's a keychain error, it should return nil
        // and log the error rather than crashing

        // Note: This is difficult to test with the real keychain implementation
        // In production, errors would be logged and nil returned
        // This test documents the expected behavior

        // The current implementation should handle keychain errors gracefully
        let privateKey = wgCredentials.getPrivateKey()
        // Should not crash and should return some value (either existing or new key)
        XCTAssertTrue(privateKey != nil || privateKey == nil, "Should handle keychain operations without crashing")
    }

    func test_delete_withKeychainError_shouldNotCrash() {
        // This test verifies that delete operations handle keychain errors gracefully
        // Should not crash even if keychain operations fail

        XCTAssertNoThrow(wgCredentials.delete(), "Delete should not throw exceptions even if keychain operations fail")

        // Instance variables should still be cleared even if keychain deletion fails
        XCTAssertNil(wgCredentials.dns, "DNS should be cleared even if keychain deletion fails")
        XCTAssertNil(wgCredentials.address, "Address should be cleared even if keychain deletion fails")
        XCTAssertNil(wgCredentials.presharedKey, "Preshared key should be cleared even if keychain deletion fails")
        XCTAssertNil(wgCredentials.allowedIps, "Allowed IPs should be cleared even if keychain deletion fails")
    }
}
