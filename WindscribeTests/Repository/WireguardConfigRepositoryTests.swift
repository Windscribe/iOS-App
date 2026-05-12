//
//  WireguardConfigRepositoryTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-02-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class WireguardConfigRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: WireguardConfigRepository!
    var mockAPIManager: MockWireguardAPIManager!
    var mockFileDatabase: MockFileDatabase!
    var mockWgCredentials: MockWgCredentials!
    var mockAlertManager: MockAlertManager!
    var mockLogger: MockLogger!
    var mockIPManager: MockWireguardIPManager!
    var mockPreferences: MockPreferences!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockWireguardAPIManager()
        mockFileDatabase = MockFileDatabase()
        mockAlertManager = MockAlertManager()
        mockLogger = MockLogger()
        mockIPManager = MockWireguardIPManager()
        mockPreferences = MockPreferences()
        // Share preferences with WgCredentials so expectsIPv6ForCurrentServer()
        // reads the same egress preference the test sets.
        mockWgCredentials = MockWgCredentials(preferences: mockPreferences)

        // Register mocks
        mockContainer.register(WireguardAPIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(FileDatabase.self) { _ in
            return self.mockFileDatabase
        }.inObjectScope(.container)

        mockContainer.register(WgCredentials.self) { _ in
            return self.mockWgCredentials
        }.inObjectScope(.container)

        mockContainer.register(AlertManager.self) { _ in
            return self.mockAlertManager
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(WireguardIPManager.self) { _ in
            return self.mockIPManager
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        // Register WireguardConfigRepository
        mockContainer.register(WireguardConfigRepository.self) { r in
            return WireguardConfigRepositoryImpl(
                apiCallManager: r.resolve(WireguardAPIManager.self)!,
                fileDatabase: r.resolve(FileDatabase.self)!,
                wgCrendentials: r.resolve(WgCredentials.self)!,
                alertManager: r.resolve(AlertManager.self)!,
                logger: r.resolve(FileLogger.self)!,
                ipManager: r.resolve(WireguardIPManager.self)!,
                preferences: r.resolve(Preferences.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(WireguardConfigRepository.self)!
    }

    override func tearDown() {
        mockFileDatabase.reset()
        mockAPIManager.reset()
        mockWgCredentials.reset()
        mockAlertManager.reset()
        mockIPManager.reset()
        mockContainer = nil
        repository = nil
        mockAPIManager = nil
        mockFileDatabase = nil
        mockWgCredentials = nil
        mockAlertManager = nil
        mockLogger = nil
        mockIPManager = nil
        super.tearDown()
    }

    // MARK: - GetCredentials Success Tests

    func test_getCredentials_firstTime_shouldInitializeSuccessfully() async throws {
        // Given - fresh credentials (not initialized)
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertTrue(mockAPIManager.wgConfigInitCalled, "Should call wgConfigInit")
        XCTAssertFalse(mockAPIManager.lastDeleteOldestKey ?? true, "Should not delete oldest key on first init")
        XCTAssertTrue(mockIPManager.generateIPCalled, "Should generate local IP")
        XCTAssertTrue(mockFileDatabase.fileExists(path: FilePaths.wireGuard), "Should save WireGuard config file")
    }

    func test_getCredentials_alreadyInitialized_shouldSkipInit() async throws {
        // Given - already initialized
        mockWgCredentials.saveInitResponse(config: createMockDynamicWireGuardConfig())
        mockWgCredentials.saveGeneratedIP(ip: "10.64.1.100", dns: "10.255.255.1")

        // Set up for second call
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When - call getCredentials twice
        try await repository.getCredentials()
        mockAPIManager.reset() // Reset to check if second call happens
        try await repository.getCredentials()

        // Then
        XCTAssertFalse(mockAPIManager.wgConfigInitCalled, "Should not call wgConfigInit on second call")
    }

    func test_getCredentials_shouldGenerateIPFromFirstCIDR() async throws {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig(hashedCIDRs: ["10.64.0.0/16", "10.65.0.0/16"])
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertTrue(mockIPManager.generateIPCalled, "Should generate IP")
        XCTAssertEqual(mockIPManager.lastCIDR, "10.64.0.0/16", "Should use first CIDR")
        XCTAssertNotNil(mockIPManager.lastPublicKey, "Should pass public key")
    }

    func test_getCredentials_shouldSaveGeneratedIPAndDNS() async throws {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.150"

        // When
        try await repository.getCredentials()

        // Then
        let savedIP = mockWgCredentials.address
        let savedDNS = mockWgCredentials.dns
        XCTAssertEqual(savedIP, "10.64.1.150", "Should save generated IP")
        XCTAssertEqual(savedDNS, "10.255.255.1", "Should save DNS")
    }

    func test_getCredentials_shouldSaveConfigFile() async throws {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertTrue(mockFileDatabase.fileExists(path: FilePaths.wireGuard), "Should save config file")

        let savedData = try await mockFileDatabase.readFile(path: FilePaths.wireGuard)
        let savedString = String(data: savedData, encoding: .utf8)
        XCTAssertNotNil(savedString, "Should save valid UTF-8 config")
    }

    // MARK: - WG Limit Exceeded Tests

    func test_getCredentials_limitExceeded_withAlertManagerAccept_shouldDeleteOldest() async throws {
        // Given
        mockAPIManager.shouldThrowLimitExceeded = true
        mockAPIManager.wgInitResponseToReturn = createMockDynamicWireGuardConfig()
        mockAlertManager.userResponse = true
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertEqual(mockAPIManager.wgConfigInitCallCount, 2, "Should call wgConfigInit twice")
        XCTAssertTrue(mockAlertManager.askUserCalled, "Should ask user for confirmation")
        XCTAssertTrue(mockAPIManager.lastDeleteOldestKey ?? false, "Should delete oldest key on retry")
    }

    func test_getCredentials_limitExceeded_withAlertManagerReject_shouldThrowHandled() async {
        // Given
        mockAPIManager.shouldThrowLimitExceeded = true
        mockAlertManager.userResponse = false

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw Errors.handled")
        } catch let error as Errors {
            XCTAssertEqual(error, Errors.handled, "Should throw handled error when user rejects")
        } catch {
            XCTFail("Expected Errors.handled but got \(error)")
        }

        XCTAssertTrue(mockAlertManager.askUserCalled, "Should ask user for confirmation")
    }

    func test_getCredentials_limitExceeded_withoutAlertManager_shouldDeleteOldestAutomatically() async throws {
        // Given - create repository without alert manager
        let repositoryWithoutAlert = WireguardConfigRepositoryImpl(
            apiCallManager: mockAPIManager,
            fileDatabase: mockFileDatabase,
            wgCrendentials: mockWgCredentials,
            alertManager: nil,
            logger: mockLogger,
            ipManager: mockIPManager,
            preferences: mockPreferences
        )

        mockAPIManager.shouldThrowLimitExceeded = true
        mockAPIManager.wgInitResponseToReturn = createMockDynamicWireGuardConfig()
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When
        try await repositoryWithoutAlert.getCredentials()

        // Then
        XCTAssertEqual(mockAPIManager.wgConfigInitCallCount, 2, "Should call wgConfigInit twice")
        XCTAssertFalse(mockAlertManager.askUserCalled, "Should not ask user without alert manager")
        XCTAssertTrue(mockAPIManager.lastDeleteOldestKey ?? false, "Should delete oldest key automatically")
    }

    // MARK: - Error Handling Tests

    func test_getCredentials_missingHashedCIDR_shouldThrow() async {
        // Given - init response without hashedCIDR
        let invalidResponse = DynamicWireGuardConfig()
        invalidResponse.presharedKey = "test-preshared-key"
        invalidResponse.allowedIPs = "0.0.0.0/0"
        invalidResponse.hashedCIDR = [] // Empty CIDR array

        mockAPIManager.wgInitResponseToReturn = invalidResponse

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw RepositoryError.missingHashedCIDR")
        } catch let error as RepositoryError {
            if case .missingHashedCIDR = error {
                // Success
            } else {
                XCTFail("Expected RepositoryError.missingHashedCIDR but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError.missingHashedCIDR but got \(error)")
        }
    }

    func test_getCredentials_missingPublicKey_shouldThrow() async {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockWgCredentials.simulateDeletePrivateKey() // Remove private key so public key can't be generated

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw RepositoryError.ipGenerationFailed")
        } catch let error as RepositoryError {
            if case .ipGenerationFailed = error {
                // Success
            } else {
                XCTFail("Expected RepositoryError.ipGenerationFailed but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError.ipGenerationFailed but got \(error)")
        }
    }

    func test_getCredentials_ipGenerationFails_shouldThrow() async {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.shouldThrowError = true

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw RepositoryError.ipGenerationFailed")
        } catch let error as RepositoryError {
            if case .ipGenerationFailed = error {
                // Success
            } else {
                XCTFail("Expected RepositoryError.ipGenerationFailed but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError.ipGenerationFailed but got \(error)")
        }

        XCTAssertTrue(mockIPManager.generateIPCalled, "Should attempt to generate IP")
    }

    func test_getCredentials_apiInitFails_shouldThrow() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.notDefined

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw error")
        } catch {
            XCTAssertNotNil(error, "Should throw error when API fails")
        }
    }

    func test_getCredentials_fileSaveFails_shouldThrow() async {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"
        mockFileDatabase.shouldThrowOnSave = true

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw file save error")
        } catch {
            XCTAssertNotNil(error, "Should throw error when file save fails")
        }
    }

    func test_getCredentials_invalidConfigString_shouldThrow() async {
        // Given - make credentials return invalid config
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // Force config string generation to fail
        mockWgCredentials.simulateInvalidConfigString()

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw RepositoryError.failedToTemplateWgConfig")
        } catch let error as RepositoryError {
            if case .failedToTemplateWgConfig = error {
                // Success
            } else {
                XCTFail("Expected RepositoryError.failedToTemplateWgConfig but got \(error)")
            }
        } catch {
            XCTFail("Expected RepositoryError.failedToTemplateWgConfig but got \(error)")
        }
    }

    // MARK: - Integration Tests

    func test_fullFlow_firstTimeInitialization() async throws {
        // Given - completely fresh state
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.200"

        // When
        try await repository.getCredentials()

        // Then - verify complete flow
        XCTAssertTrue(mockAPIManager.wgConfigInitCalled, "Should initialize WG config")
        XCTAssertTrue(mockIPManager.generateIPCalled, "Should generate local IP")
        XCTAssertTrue(mockFileDatabase.fileExists(path: FilePaths.wireGuard), "Should save config file")

        let savedData = try await mockFileDatabase.readFile(path: FilePaths.wireGuard)
        let configString = String(data: savedData, encoding: .utf8)
        XCTAssertNotNil(configString, "Should have valid config string")
        XCTAssertTrue(configString?.contains("10.64.1.200") ?? false, "Config should contain generated IP")
    }

    func test_multipleGetCredentialsCalls_shouldNotReinitialize() async throws {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When - call multiple times
        try await repository.getCredentials()
        let firstCallCount = mockAPIManager.wgConfigInitCallCount

        try await repository.getCredentials()
        let secondCallCount = mockAPIManager.wgConfigInitCallCount

        try await repository.getCredentials()
        let thirdCallCount = mockAPIManager.wgConfigInitCallCount

        // Then - should only initialize once
        XCTAssertEqual(firstCallCount, 1, "First call should initialize")
        XCTAssertEqual(secondCallCount, 1, "Second call should skip initialization")
        XCTAssertEqual(thirdCallCount, 1, "Third call should skip initialization")
    }

    func test_getCredentials_differentEndpoint_shouldReinitialize() async throws {
        // Given - first connection to endpoint A
        mockWgCredentials.setNodeToConnect(
            serverEndPoint: "192.0.2.1",
            serverHostName: "server-a.example.com",
            serverPublicKey: "test-server-public-key",
            port: "443",
            ipv6: 1
        )
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        try await repository.getCredentials()
        XCTAssertEqual(mockAPIManager.wgConfigInitCallCount, 1, "First endpoint should initialize")

        // When - switch to endpoint B and call again
        mockWgCredentials.setNodeToConnect(
            serverEndPoint: "192.0.2.2",
            serverHostName: "server-b.example.com",
            serverPublicKey: "test-server-public-key",
            port: "443",
            ipv6: 0
        )

        try await repository.getCredentials()

        // Then - should re-initialize for the new endpoint
        XCTAssertEqual(mockAPIManager.wgConfigInitCallCount, 2, "Should reinitialize when endpoint changes")
    }

    func test_getCredentials_withDifferentCIDRFormats_shouldWork() async throws {
        // Test that the repository correctly uses the first CIDR from the response
        // This test verifies with the default CIDR

        // Given
        let cidr = "192.168.1.0/24"
        let mockInitResponse = createMockDynamicWireGuardConfig(hashedCIDRs: [cidr, "10.65.0.0/16"])
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "192.168.1.100"

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertEqual(mockIPManager.lastCIDR, cidr, "Should use first CIDR from list")
        XCTAssertTrue(mockIPManager.generateIPCalled, "Should generate IP")
    }

    // MARK: - Edge Cases

    func test_getCredentials_emptyPublicKey_shouldThrow() async {
        // Given
        let mockInitResponse = createMockDynamicWireGuardConfig()
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockWgCredentials.simulateDeletePrivateKey()

        // When/Then
        do {
            try await repository.getCredentials()
            XCTFail("Expected to throw error for missing public key")
        } catch {
            XCTAssertNotNil(error, "Should throw error")
        }
    }

    func test_getCredentials_multipleCIDRs_shouldUseFirst() async throws {
        // Given
        let cidrList = ["10.64.0.0/16", "10.65.0.0/16", "10.66.0.0/16"]
        let mockInitResponse = createMockDynamicWireGuardConfig(hashedCIDRs: cidrList)
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertEqual(mockIPManager.lastCIDR, cidrList[0], "Should use first CIDR from list")
    }

    // MARK: - IPv6 Tests

    func test_getCredentials_withIPv6Support_shouldGenerateIPv6() async throws {
        // Given - server supports IPv6, egress is Auto, and v6 CIDR is present
        let mockInitResponse = createMockDynamicWireGuardConfig(
            hashedCIDRs: ["10.64.0.0/16"],
            hashedCIDRsV6: ["fd54:0004::/64"],
            allowedIPsV6: "::/0"
        )
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"
        mockIPManager.generatedIPv6ToReturn = "fd54:4::abcd:ef01"
        mockWgCredentials.setNodeToConnect(
            serverEndPoint: "192.0.2.1",
            serverHostName: "test-server.example.com",
            serverPublicKey: "test-server-public-key",
            port: "443",
            ipv6: 1
        )
        mockPreferences.saveEgressProtocolPreference(value: "Auto")

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertTrue(mockIPManager.generateIPCalled, "Should generate IPv4 IP")
        XCTAssertTrue(mockIPManager.generateIPv6Called, "Should generate IPv6 IP")
        XCTAssertEqual(mockWgCredentials.addressV6, "fd54:4::abcd:ef01", "Should save generated IPv6 address")

        let savedData = try await mockFileDatabase.readFile(path: FilePaths.wireGuard)
        let configString = String(data: savedData, encoding: .utf8)!
        XCTAssertTrue(configString.contains("fd54:4::abcd:ef01"), "Config should contain IPv6 address")
        XCTAssertTrue(configString.contains("::/0"), "Config should contain IPv6 allowed IPs")
    }

    func test_getCredentials_withIPv6Support_egressIPv4Only_shouldNotGenerateIPv6() async throws {
        // Given - server supports IPv6 but egress is IPv4 Only
        let mockInitResponse = createMockDynamicWireGuardConfig(
            hashedCIDRs: ["10.64.0.0/16"],
            hashedCIDRsV6: ["fd54:0004::/64"],
            allowedIPsV6: "::/0"
        )
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"
        mockWgCredentials.setNodeToConnect(
            serverEndPoint: "192.0.2.1",
            serverHostName: "test-server.example.com",
            serverPublicKey: "test-server-public-key",
            port: "443",
            ipv6: 1
        )
        mockPreferences.saveEgressProtocolPreference(value: DefaultValues.ipv4Only)

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertTrue(mockIPManager.generateIPCalled, "Should generate IPv4 IP")
        XCTAssertFalse(mockIPManager.generateIPv6Called, "Should not generate IPv6 IP when egress is IPv4 Only")
        XCTAssertNil(mockWgCredentials.addressV6, "Should not have IPv6 address")
    }

    func test_getCredentials_withoutServerIPv6Support_shouldNotGenerateIPv6() async throws {
        // Given - server does not support IPv6 even though egress is Auto and v6 CIDR present
        let mockInitResponse = createMockDynamicWireGuardConfig(
            hashedCIDRs: ["10.64.0.0/16"],
            hashedCIDRsV6: ["fd54:0004::/64"],
            allowedIPsV6: "::/0"
        )
        mockAPIManager.wgInitResponseToReturn = mockInitResponse
        mockIPManager.generatedIPToReturn = "10.64.1.100"
        mockWgCredentials.setNodeToConnect(
            serverEndPoint: "192.0.2.1",
            serverHostName: "test-server.example.com",
            serverPublicKey: "test-server-public-key",
            port: "443",
            ipv6: 0
        )
        mockPreferences.saveEgressProtocolPreference(value: "Auto")

        // When
        try await repository.getCredentials()

        // Then
        XCTAssertTrue(mockIPManager.generateIPCalled, "Should generate IPv4 IP")
        XCTAssertFalse(mockIPManager.generateIPv6Called, "Should not generate IPv6 IP when server doesn't support it")
        XCTAssertNil(mockWgCredentials.addressV6, "Should not have IPv6 address")
    }

    // MARK: - Helper Methods

    private func createMockDynamicWireGuardConfig(
        hashedCIDRs: [String] = ["10.64.0.0/16"],
        hashedCIDRsV6: [String]? = nil,
        allowedIPsV6: String? = nil
    ) -> DynamicWireGuardConfig {
        let response = DynamicWireGuardConfig()
        response.presharedKey = "test-preshared-key"
        response.allowedIPs = "0.0.0.0/0"
        response.allowedIPsV6 = allowedIPsV6
        response.hashedCIDR = hashedCIDRs
        response.hashedCIDRv6 = hashedCIDRsV6
        return response
    }
}
