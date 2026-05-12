//
//  MockWgCredentials.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockWgCredentials: WgCredentials {
    var deleteCalled = false
    private var privateKeyDeleted = false
    private var mockPreferences: MockPreferences?
    private var forceConfigStringNil = false

    init(preferences: MockPreferences? = nil) {
        // Share the test's MockPreferences when provided so reads like
        // getEgressProtocolPreferenceSync() see the same state the test
        // set up. Falls back to a dedicated MockPreferences for callers
        // that don't need cross-mock coordination.
        let mockPreferences = preferences ?? MockPreferences()
        let mockLogger = MockLogger()
        let mockKeychainManager = MockKeychainManager()

        self.mockPreferences = mockPreferences

        super.init(preferences: mockPreferences, logger: mockLogger, keychainManager: mockKeychainManager)

        // Set up default server details for testing
        setNodeToConnect(
            serverEndPoint: "192.0.2.1",
            serverHostName: "test-server.example.com",
            serverPublicKey: "test-server-public-key",
            port: "443",
            ipv6: 0
        )
    }

    override func delete() {
        deleteCalled = true
        super.delete()
    }

    // Method to simulate deleting private key for testing purposes
    func simulateDeletePrivateKey() {
        privateKeyDeleted = true
    }

    // Method to force config string generation to fail
    func simulateInvalidConfigString() {
        forceConfigStringNil = true
    }

    override func asWgCredentialsString() -> String? {
        if forceConfigStringNil {
            return nil
        }
        return super.asWgCredentialsString()
    }

    override func getPrivateKey() -> String? {
        if privateKeyDeleted {
            return nil
        }
        return super.getPrivateKey()
    }

    func reset() {
        deleteCalled = false
        privateKeyDeleted = false
        forceConfigStringNil = false

        // Clear WireGuard configuration
        mockPreferences?.clearWireGuardConfiguration()

        // Reset to defaults
        setNodeToConnect(
            serverEndPoint: "192.0.2.1",
            serverHostName: "test-server.example.com",
            serverPublicKey: "test-server-public-key",
            port: "443",
            ipv6: 0
        )
    }
}
