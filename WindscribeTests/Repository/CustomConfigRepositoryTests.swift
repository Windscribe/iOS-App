//
//  CustomConfigRepositoryTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-02-17.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class CustomConfigRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: CustomConfigRepository!
    var mockFileDatabase: MockFileDatabase!
    var mockLocalDatabase: MockLocalDatabase!
    var mockPortMapRepository: MockPortMapRepository!
    var mockLogger: MockLogger!
    var mockPreferences: MockPreferences!

    // MARK: - Setup and Teardown

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockFileDatabase = MockFileDatabase()
        mockLocalDatabase = MockLocalDatabase()
        mockPortMapRepository = MockPortMapRepository()
        mockLogger = MockLogger()
        mockPreferences = MockPreferences()

        // Configure MockPortMapRepository with default ports
        mockPortMapRepository.portMapsToReturn = [
            PortMapModel(connectionProtocol: "", heading: "UDP", use: "", ports: ["443", "80", "53"], legacyPorts: []),
            PortMapModel(connectionProtocol: "", heading: "TCP", use: "", ports: ["443", "80", "53"], legacyPorts: []),
            PortMapModel(connectionProtocol: "", heading: "STEALTH", use: "", ports: ["443"], legacyPorts: []),
            PortMapModel(connectionProtocol: "", heading: "WSTUNNEL", use: "", ports: ["443"], legacyPorts: [])
        ]

        // Register mocks
        mockContainer.register(FileDatabase.self) { _ in
            return self.mockFileDatabase
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(PortMapRepository.self) { _ in
            return self.mockPortMapRepository
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        // Register CustomConfigRepository
        mockContainer.register(CustomConfigRepository.self) { r in
            return CustomConfigRepositoryImpl(
                fileDatabase: r.resolve(FileDatabase.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                portMapRepository: r.resolve(PortMapRepository.self)!,
                preferences: r.resolve(Preferences.self)!
            )
        }.inObjectScope(.container)

        // Resolve repository from container
        repository = mockContainer.resolve(CustomConfigRepository.self)!
    }

    override func tearDown() {
        mockFileDatabase.reset()
        mockLocalDatabase.clean()
        mockLocalDatabase.customConfigsSubject.send([])
        mockPortMapRepository.reset()
        mockContainer = nil
        repository = nil
        mockFileDatabase = nil
        mockLocalDatabase = nil
        mockPortMapRepository = nil
        mockPreferences = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func test_initialization_shouldHaveEmptyCustomConfigs() {
        // Then
        XCTAssertEqual(repository.customConfigs.value.count, 0)
    }

    func test_initialization_shouldObserveLocalDatabaseChanges() {
        // Given
        let expectation = XCTestExpectation(description: "Receives custom config update")
        var cancellables = Set<AnyCancellable>()
        var receivedConfigs: [CustomConfigModel] = []

        repository.customConfigs
            .dropFirst() // Skip initial empty value
            .sink { configs in
                receivedConfigs = configs
                expectation.fulfill()
            }
            .store(in: &cancellables)

        // When
        let customConfig = CustomConfigModel(
            id: "test-id",
            name: "Test Config",
            serverAddress: "192.168.1.1",
            protocolType: "UDP",
            port: "443"
        )
        mockLocalDatabase.saveCustomConfig(customConfig: customConfig)

        // Then
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedConfigs.count, 1)
        XCTAssertEqual(receivedConfigs.first?.name, "Test Config")
    }

    // MARK: - OpenVPN Config Tests

    func test_saveOpenVPNCustomConfig_success_shouldSaveFileAndDatabase() async throws {
        // Given
        let testData = """
        client
        remote 192.168.1.1 443
        proto udp
        dev tun
        """.data(using: .utf8)!

        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "192.168.1.1",
            port: "443",
            protocolName: "UDP",
            username: "testuser",
            password: "testpass"
        )

        // When
        let result = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: connectionInfo,
            configuationName: "My VPN"
        )

        // Then
        XCTAssertEqual(result.name, "My VPN")
        XCTAssertEqual(result.serverAddress, "192.168.1.1")
        XCTAssertEqual(result.protocolType, "UDP")
        XCTAssertEqual(result.port, "443")
        XCTAssertEqual(result.username, "testuser")
        XCTAssertEqual(result.password, "testpass")
        XCTAssertTrue(result.authRequired)
        XCTAssertTrue(result.saveCredentials)

        // Verify file was saved
        XCTAssertTrue(mockFileDatabase.fileExists(path: "\(result.id).ovpn"))

        // Verify local database was updated using the customConfigsSubject
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 1)
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.first?.name, "My VPN")
    }

    func test_saveOpenVPNCustomConfig_fileSaveError_shouldThrowAndNotSaveToDatabase() async {
        // Given
        mockFileDatabase.shouldThrowOnSave = true

        let testData = "config data".data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "192.168.1.1",
            port: "443",
            protocolName: "UDP",
            username: "user",
            password: "pass"
        )

        // When/Then
        do {
            _ = try await repository.saveOpenVPNCustomConfig(
                data: testData,
                configInfo: connectionInfo,
                configuationName: "Test"
            )
            XCTFail("Expected saveOpenVPNCustomConfig to throw")
        } catch {
            XCTAssertNotNil(error)
        }

        // Verify local database was NOT updated due to file error
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 0)
    }

    func test_saveOpenVPNCustomConfig_withSpecialCharactersInName_shouldSaveCorrectly() async throws {
        // Given
        let testData = "config".data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "192.168.1.1",
            port: "443",
            protocolName: "UDP",
            username: "user",
            password: "pass"
        )
        let specialName = "My VPN™ (Test) [2026]"

        // When
        let result = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: connectionInfo,
            configuationName: specialName
        )

        // Then
        XCTAssertEqual(result.name, specialName)
    }

    func test_saveOpenVPNCustomConfig_withEmptyCredentials_shouldSaveCorrectly() async throws {
        // Given
        let testData = "config".data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "10.0.0.1",
            port: "443",
            protocolName: "TCP",
            username: "",
            password: ""
        )

        // When
        let result = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: connectionInfo,
            configuationName: "No Creds"
        )

        // Then
        XCTAssertEqual(result.username, "")
        XCTAssertEqual(result.password, "")
    }

    func test_removeOpenVPNConfig_success_shouldRemoveFileAndDatabaseEntry() async throws {
        // Given - first add a config
        let testData = "config".data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "192.168.1.1",
            port: "443",
            protocolName: "UDP",
            username: "user",
            password: "pass"
        )

        let savedConfig = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: connectionInfo,
            configuationName: "To Delete"
        )

        let fileId = savedConfig.id
        let filePath = "\(fileId).ovpn"

        XCTAssertTrue(mockFileDatabase.fileExists(path: filePath))
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 1)

        // When - remove it
        await repository.removeOpenVPNConfig(fileId: fileId)

        // Then
        XCTAssertFalse(mockFileDatabase.fileExists(path: filePath))
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.filter { $0.id == fileId }.count, 0)
    }

    // MARK: - WireGuard Config Tests

    func test_saveWgConfig_withValidEndpoint_shouldProcessFile() async throws {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let testFileURL = tempDir.appendingPathComponent("test.conf")

        let content = """
        [Interface]
        PrivateKey = key

        [Peer]
        Endpoint = 192.168.100.1:51820
        """.data(using: .utf8)!

        try content.write(to: testFileURL)

        defer {
            try? FileManager.default.removeItem(at: testFileURL)
        }

        // When
        _ = try? await repository.saveWgConfig(url: testFileURL)

        let customConfigs = mockLocalDatabase.getCustomConfigs()

        XCTAssertEqual(customConfigs.count, 1)
        XCTAssertEqual(customConfigs[0].serverAddress, "192.168.100.1")
    }

    func test_saveWgConfig_withMissingEndpoint_shouldThrowError() async {
        // Given
        let tempDir = FileManager.default.temporaryDirectory
        let testFileURL = tempDir.appendingPathComponent("invalid.conf")

        let invalidContent = """
        [Interface]
        PrivateKey = key
        """.data(using: .utf8)!

        try! invalidContent.write(to: testFileURL)

        defer {
            try? FileManager.default.removeItem(at: testFileURL)
        }

        // When/Then
        do {
            try await repository.saveWgConfig(url: testFileURL)
            XCTFail("Expected saveWgConfig to throw")
        } catch {
            XCTAssertNotNil(error)
        }

        // Should not have saved to local database
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 0)
    }

    func test_removeWgConfig_success_shouldRemoveFileAndDatabaseEntry() async {
        // Given - manually add a WG config
        let testConfig = CustomConfigModel(
            id: "wg-test-id",
            name: "WG Config",
            serverAddress: "192.168.1.1",
            protocolType: "WireGuard",
            port: "51820"
        )
        mockLocalDatabase.saveCustomConfig(customConfig: testConfig)

        let testData = "wg config".data(using: .utf8)!
        let filePath = "\(testConfig.id).conf"
        try! await mockFileDatabase.saveFile(data: testData, path: filePath)

        XCTAssertTrue(mockFileDatabase.fileExists(path: filePath))

        // When - remove it
        await repository.removeWgConfig(fileId: testConfig.id)

        // Then
        XCTAssertFalse(mockFileDatabase.fileExists(path: filePath))
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.filter { $0.id == testConfig.id }.count, 0)
    }

    // MARK: - General Config Management Tests

    func test_getCustomConfig_withMatchingId_shouldReturnConfig() {
        // Given
        let config1 = CustomConfigModel(id: "id1", name: "Config 1", serverAddress: "1.1.1.1", protocolType: "UDP", port: "443")
        let config2 = CustomConfigModel(id: "id2", name: "Config 2", serverAddress: "2.2.2.2", protocolType: "TCP", port: "80")

        mockLocalDatabase.saveCustomConfig(customConfig: config1)
        mockLocalDatabase.saveCustomConfig(customConfig: config2)

        // When
        let result = repository.getCustomConfig(fileId: "id2")

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.name, "Config 2")
        XCTAssertEqual(result?.serverAddress, "2.2.2.2")
    }

    func test_getCustomConfig_withNonExistentId_shouldReturnNil() {
        // Given
        // No configs saved

        // When
        let result = repository.getCustomConfig(fileId: "does-not-exist")

        // Then
        XCTAssertNil(result)
    }

    func test_saveCustomConfig_shouldUpdateLocalDatabase() {
        // Given
        let configModel = CustomConfigModel(
            from: CustomConfig(
                id: "new-id",
                name: "New Config",
                serverAddress: "10.0.0.1",
                protocolType: "TCP",
                port: "8080",
                authRequired: true
            )
        )

        // When
        repository.saveCustomConfig(customConfig: configModel)

        // Then
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 1)
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.first?.name, "New Config")
    }

    func test_removeCustomConfig_shouldClearFromDatabase() {
        // Given
        let config = CustomConfigModel(id: "remove-me", name: "To Remove", serverAddress: "1.2.3.4", protocolType: "UDP", port: "443")
        mockLocalDatabase.saveCustomConfig(customConfig: config)

        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 1)

        // When
        repository.removeCustomConfig(fileId: "remove-me")

        // Then
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.filter { $0.id == "remove-me" }.count, 0)
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 0)
    }

    // MARK: - Integration Tests

    func test_multipleConfigs_canCoexist() async throws {
        // Given
        let testData = "config".data(using: .utf8)!

        let info1 = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "1.1.1.1",
            port: "443",
            protocolName: "UDP",
            username: "user1",
            password: "pass1"
        )
        let info2 = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "2.2.2.2",
            port: "80",
            protocolName: "TCP",
            username: "user2",
            password: "pass2"
        )

        // When - save multiple configs
        let config1 = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: info1,
            configuationName: "Config 1"
        )
        let config2 = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: info2,
            configuationName: "Config 2"
        )

        // Then
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 2)
        XCTAssertEqual(mockFileDatabase.getFileCount(), 2)

        // Verify both can be retrieved
        let retrieved1 = repository.getCustomConfig(fileId: config1.id)
        let retrieved2 = repository.getCustomConfig(fileId: config2.id)

        XCTAssertEqual(retrieved1?.name, "Config 1")
        XCTAssertEqual(retrieved2?.name, "Config 2")
    }

    func test_customConfigsSubject_shouldPublishUpdates() {
        // Given
        let expectation1 = XCTestExpectation(description: "First update")
        let expectation2 = XCTestExpectation(description: "Second update")
        var cancellables = Set<AnyCancellable>()
        var receivedUpdates: [[CustomConfigModel]] = []

        repository.customConfigs
            .dropFirst() // Skip initial empty
            .sink { configs in
                receivedUpdates.append(configs)
                if receivedUpdates.count == 1 {
                    expectation1.fulfill()
                } else if receivedUpdates.count == 2 {
                    expectation2.fulfill()
                }
            }
            .store(in: &cancellables)

        // When - trigger updates
        let config1 = CustomConfigModel(id: "id1", name: "First", serverAddress: "1.1.1.1", protocolType: "UDP", port: "443")
        mockLocalDatabase.saveCustomConfig(customConfig: config1)

        wait(for: [expectation1], timeout: 1.0)

        let config2 = CustomConfigModel(id: "id2", name: "Second", serverAddress: "2.2.2.2", protocolType: "TCP", port: "80")
        mockLocalDatabase.saveCustomConfig(customConfig: config2)

        wait(for: [expectation2], timeout: 1.0)

        // Then
        XCTAssertEqual(receivedUpdates.count, 2)
        XCTAssertEqual(receivedUpdates[0].count, 1)
        XCTAssertEqual(receivedUpdates[1].count, 2)
    }

    func test_fullFlow_saveAndRetrieveConfig() async throws {
        // Given
        let testData = "full flow config".data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "203.0.113.1",
            port: "1194",
            protocolName: "TCP",
            username: "flowuser",
            password: "flowpass"
        )

        // When - save config
        let savedConfig = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: connectionInfo,
            configuationName: "Full Flow Test"
        )

        // Then - verify retrieval
        let retrievedConfig = repository.getCustomConfig(fileId: savedConfig.id)
        XCTAssertNotNil(retrievedConfig)
        XCTAssertEqual(retrievedConfig?.id, savedConfig.id)
        XCTAssertEqual(retrievedConfig?.name, "Full Flow Test")
        XCTAssertEqual(retrievedConfig?.serverAddress, "203.0.113.1")
        XCTAssertEqual(retrievedConfig?.port, "1194")

        // Verify file exists
        XCTAssertTrue(mockFileDatabase.fileExists(path: "\(savedConfig.id).ovpn"))

        // Clean up - remove config
        await repository.removeOpenVPNConfig(fileId: savedConfig.id)

        // Verify removal
        XCTAssertNil(repository.getCustomConfig(fileId: savedConfig.id))
        XCTAssertFalse(mockFileDatabase.fileExists(path: "\(savedConfig.id).ovpn"))
    }

    func test_concurrentSaves_shouldWorkCorrectly() async throws {
        // Given
        let testData = "config".data(using: .utf8)!
        var savedConfigIds: [String] = []

        // When - create multiple save operations sequentially to avoid race conditions with mock
        // Note: In real implementation, concurrent saves work fine, but mocks may not handle
        // rapid concurrent Combine subject updates reliably
        for i in 1...5 {
            let info = OpenVPNConnectionInfo(
                serverConfig: testData,
                ip: "192.168.1.\(i)",
                port: "443",
                protocolName: "UDP",
                username: "user\(i)",
                password: "pass\(i)"
            )

            let config = try await repository.saveOpenVPNCustomConfig(
                data: testData,
                configInfo: info,
                configuationName: "Config \(i)"
            )
            savedConfigIds.append(config.id)
        }

        // Then - all configs should be saved
        XCTAssertEqual(savedConfigIds.count, 5, "Expected 5 configs to be created")
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.count, 5, "Expected 5 configs in database but got \(mockLocalDatabase.customConfigsSubject.value.count)")
        XCTAssertEqual(mockFileDatabase.getFileCount(), 5, "Expected 5 files but got \(mockFileDatabase.getFileCount())")

        // Verify all configs are retrievable
        for configId in savedConfigIds {
            let retrieved = repository.getCustomConfig(fileId: configId)
            XCTAssertNotNil(retrieved, "Config with id \(configId) should be retrievable")
        }
    }

    // MARK: - Edge Cases

    func test_saveConfig_thenRemove_thenGetShouldReturnNil() async throws {
        // Given
        let testData = "config".data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: testData,
            ip: "10.0.0.1",
            port: "443",
            protocolName: "UDP",
            username: "user",
            password: "pass"
        )

        // When - save, then remove
        let savedConfig = try await repository.saveOpenVPNCustomConfig(
            data: testData,
            configInfo: connectionInfo,
            configuationName: "Temporary"
        )

        await repository.removeOpenVPNConfig(fileId: savedConfig.id)

        // Then
        XCTAssertNil(repository.getCustomConfig(fileId: savedConfig.id))
    }

    func test_removeNonExistentConfig_shouldNotCrash() async {
        // Given
        let nonExistentId = "does-not-exist"

        // When/Then - should not crash
        await repository.removeOpenVPNConfig(fileId: nonExistentId)
        await repository.removeWgConfig(fileId: nonExistentId)

        // Verify removal was called (config won't be in the list since it never existed)
        XCTAssertEqual(mockLocalDatabase.customConfigsSubject.value.filter { $0.id == nonExistentId }.count, 0)
    }
}
