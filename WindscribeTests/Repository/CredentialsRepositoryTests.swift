//
//  CredentialsRepositoryTests.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest
import Combine

class CredentialsRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: CredentialsRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockFileDatabase: MockFileDatabase!
    var mockVPNStateRepository: MockVPNStateRepository!
    var mockWifiManager: MockWifiManager!
    var mockPreferences: MockPreferences!
    var mockLogger: MockLogger!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockFileDatabase = MockFileDatabase()
        mockVPNStateRepository = MockVPNStateRepository()
        mockWifiManager = MockWifiManager()
        mockPreferences = MockPreferences()
        mockLogger = MockLogger()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(FileDatabase.self) { _ in
            return self.mockFileDatabase
        }.inObjectScope(.container)

        mockContainer.register(VPNStateRepository.self) { _ in
            return self.mockVPNStateRepository
        }.inObjectScope(.container)

        mockContainer.register(WifiManager.self) { _ in
            return self.mockWifiManager
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        // Register CredentialsRepository
        mockContainer.register(CredentialsRepository.self) { r in
            return CredentialsRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                fileDatabase: r.resolve(FileDatabase.self)!,
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                wifiManager: r.resolve(WifiManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(CredentialsRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockAPIManager.reset()
        mockLocalDatabase.clean()
        mockFileDatabase.reset()
        mockWifiManager.reset()
        mockLogger.reset()
        mockContainer = nil
        repository = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockFileDatabase = nil
        mockVPNStateRepository = nil
        mockWifiManager = nil
        mockPreferences = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    private func createMockOpenVPNCredentials() -> OpenVPNServerCredentials {
        let credentials = OpenVPNServerCredentials()
        credentials.username = "test-openvpn-user"
        credentials.password = "test-openvpn-pass"
        return credentials
    }

    private func createMockIKEv2Credentials() -> IKEv2ServerCredentials {
        let credentials = IKEv2ServerCredentials()
        credentials.username = "test-ikev2-user"
        credentials.password = "test-ikev2-pass"
        return credentials
    }

    private func setupPreferences(connectionMode: String = Fields.Values.auto, selectedProtocol: String = TextsAsset.wireGuard) async {
        mockPreferences.mockConnectionMode.send(connectionMode)
        mockPreferences.mockSelectedProtocol.send(selectedProtocol)
        // Needs to wait for the preferences to propagate the value
        try? await Task.sleep(nanoseconds: 100_000_000)
    }

    // MARK: - getUpdatedOpenVPNCrendentials Tests

    func testGetUpdatedOpenVPNCredentials_success_savesToDatabaseAndUpdatesProperty() async throws {
        // Given
        let mockCredentials = createMockOpenVPNCredentials()
        mockAPIManager.mockOpenVPNCredentials = mockCredentials

        // When
        try await repository.getUpdatedOpenVPNCrendentials()

        // Then
        XCTAssertNotNil(repository.openVPNCrendentials, "OpenVPN credentials should be set")
        XCTAssertEqual(repository.openVPNCrendentials?.username, "test-openvpn-user")
        XCTAssertEqual(repository.openVPNCrendentials?.password, "test-openvpn-pass")
        XCTAssertTrue(mockPreferences.saveOpenVPNCredentialsCalled, "Should save credentials to database")
    }

    func testGetUpdatedOpenVPNCredentials_apiFailure_fallsBackToCachedPreferences() async throws {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: -1)
        let cachedCredentials = ServerCredentialsModel(username: "test-openvpn-user", password: "test-openvpn-pass")
        mockPreferences.mockOpenVPNCredentials = cachedCredentials

        // When
        try await repository.getUpdatedOpenVPNCrendentials()

        // Then
        XCTAssertNotNil(repository.openVPNCrendentials, "Should use cached credentials on API failure")
        XCTAssertEqual(repository.openVPNCrendentials?.username, "test-openvpn-user")
    }

    func testGetUpdatedOpenVPNCredentials_apiFailureWithNoCachedCredentials_throwsError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: -1)
        mockPreferences.mockOpenVPNCredentials = nil

        // When/Then
        do {
            try await repository.getUpdatedOpenVPNCrendentials()
            XCTFail("Should throw error when both API and local database fail")
        } catch {
            XCTAssertNotNil(error, "Error should be thrown")
        }
    }

    // MARK: - getUpdatedIKEv2Crendentials Tests

    func testGetUpdatedIKEv2Credentials_success_savesToDatabaseAndUpdatesProperty() async throws {
        // Given
        let mockCredentials = createMockIKEv2Credentials()
        mockAPIManager.mockIKEv2Credentials = mockCredentials

        // When
        try await repository.getUpdatedIKEv2Crendentials()

        // Then
        XCTAssertNotNil(repository.ikev2Crendentials, "IKEv2 credentials should be set")
        XCTAssertEqual(repository.ikev2Crendentials?.username, "test-ikev2-user")
        XCTAssertEqual(repository.ikev2Crendentials?.password, "test-ikev2-pass")
        XCTAssertTrue(mockPreferences.saveIKEv2CredentialsCalled, "Should save credentials to database")
    }

    func testGetUpdatedIKEv2Credentials_apiFailure_fallsBackToCachedPreferences() async throws {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: -1)
        let cachedCredentials = ServerCredentialsModel(username: "test-ikev2-user", password: "test-ikev2-pass")
        mockPreferences.mockIKEv2Credentials = cachedCredentials

        // When
        try await repository.getUpdatedIKEv2Crendentials()

        // Then
        XCTAssertNotNil(repository.ikev2Crendentials, "Should use cached credentials on API failure")
        XCTAssertEqual(repository.ikev2Crendentials?.username, "test-ikev2-user")
    }

    func testGetUpdatedIKEv2Credentials_apiFailureWithNoCachedCredentials_throwsError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: -1)
        mockPreferences.mockIKEv2Credentials = nil

        // When/Then
        do {
            try await repository.getUpdatedIKEv2Crendentials()
            XCTFail("Should throw error when both API and local database fail")
        } catch {
            XCTAssertNotNil(error, "Error should be thrown")
        }
    }

    // MARK: - getUpdatedServerConfig Tests

    func testGetUpdatedServerConfig_success_savesConfigToFileDatabase() async throws {
        // Given
        let mockConfig = "client\ndev tun\nproto udp\nremote 1.2.3.4 443"
        let base64Config = mockConfig.data(using: .utf8)!.base64EncodedString()
        mockAPIManager.mockOpenVPNServerConfig = base64Config

        // When
        try await repository.getUpdatedServerConfig()

        // Then
        XCTAssertTrue(mockFileDatabase.saveFileCalled, "Should save config file")
        XCTAssertEqual(mockFileDatabase.lastSavedFilePath, FilePaths.openVPN)
        XCTAssertNotNil(mockFileDatabase.lastSavedFileData)
    }

    func testGetUpdatedServerConfig_apiFailure_usesExistingFileFromDatabase() async throws {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: -1)
        let existingConfig = "existing config data".data(using: .utf8)!
        mockFileDatabase.mockFileContent = existingConfig

        // When
        try await repository.getUpdatedServerConfig()

        // Then
        XCTAssertTrue(mockFileDatabase.readFileCalled, "Should attempt to read existing file")
        XCTAssertEqual(mockFileDatabase.lastReadFilePath, FilePaths.openVPN)
    }

    func testGetUpdatedServerConfig_apiFailureWithNoLocalFile_throwsError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: -1)
        mockFileDatabase.mockFileContent = nil

        // When/Then
        do {
            try await repository.getUpdatedServerConfig()
            XCTFail("Should throw error when both API and local file fail")
        } catch {
            XCTAssertNotNil(error, "Error should be thrown")
        }
    }

    func testGetUpdatedServerConfig_removesOldFileBeforeSaving() async throws {
        // Given
        let mockConfig = "client\ndev tun"
        let base64Config = mockConfig.data(using: .utf8)!.base64EncodedString()
        mockAPIManager.mockOpenVPNServerConfig = base64Config

        // When
        try await repository.getUpdatedServerConfig()

        // Then
        XCTAssertTrue(mockFileDatabase.removeFileCalled, "Should remove old file before saving")
        XCTAssertEqual(mockFileDatabase.lastRemovedFilePath, FilePaths.openVPN)
    }

    // MARK: - selectedServerCredentialsType Tests

    func testSelectedServerCredentialsType_withNoWifiConnection_returnsOpenVPN() {
        // Given
        mockWifiManager.mockConnectedNetwork = nil

        // When
        let credentialsType = repository.selectedServerCredentialsType()

        // Then
        XCTAssertTrue(credentialsType == OpenVPNServerCredentials.self)
    }

    func testSelectedServerCredentialsType_withPreferredProtocolEnabled_returnsPreferredType() {
        // Given
        let network = createMockWifiNetwork(
            preferredProtocolStatus: true,
            preferredProtocol: TextsAsset.iKEv2
        )
        mockWifiManager.mockConnectedNetwork = network
        mockVPNStateRepository.isFromProtocolFailover = false
        mockVPNStateRepository.isFromProtocolChange = false

        // When
        let credentialsType = repository.selectedServerCredentialsType()

        // Then
        XCTAssertTrue(credentialsType == IKEv2ServerCredentials.self)
    }

    func testSelectedServerCredentialsType_withPreferredProtocolEnabledOpenVPN_returnsOpenVPN() {
        // Given
        let network = createMockWifiNetwork(
            preferredProtocolStatus: true,
            preferredProtocol: TextsAsset.wireGuard
        )
        mockWifiManager.mockConnectedNetwork = network
        mockVPNStateRepository.isFromProtocolFailover = false
        mockVPNStateRepository.isFromProtocolChange = false

        // When
        let credentialsType = repository.selectedServerCredentialsType()

        // Then
        XCTAssertTrue(credentialsType == OpenVPNServerCredentials.self)
    }

    func testSelectedServerCredentialsType_withProtocolFailover_usesConnectionMode() async {
        // Given
        let network = createMockWifiNetwork(
            preferredProtocolStatus: true,
            preferredProtocol: TextsAsset.iKEv2
        )
        mockWifiManager.mockConnectedNetwork = network
        mockVPNStateRepository.isFromProtocolFailover = true
        await setupPreferences(connectionMode: Fields.Values.manual, selectedProtocol: TextsAsset.iKEv2)

        // When
        let credentialsType = repository.selectedServerCredentialsType()

        // Then
        XCTAssertTrue(credentialsType == IKEv2ServerCredentials.self)
    }

    func testSelectedServerCredentialsType_withManualConnectionAndIKEv2_returnsIKEv2() async {
        // Given
        let network = createMockWifiNetwork(
            preferredProtocolStatus: false,
            preferredProtocol: nil
        )
        mockWifiManager.mockConnectedNetwork = network
        await setupPreferences(connectionMode: Fields.Values.manual, selectedProtocol: TextsAsset.iKEv2)

        // When
        let credentialsType = repository.selectedServerCredentialsType()

        // Then
        XCTAssertTrue(credentialsType == IKEv2ServerCredentials.self)
    }

    func testSelectedServerCredentialsType_withAutoConnectionAndNetworkProtocol_returnsNetworkProtocol() async {
        // Given
        let network = createMockWifiNetwork(
            preferredProtocolStatus: false,
            preferredProtocol: nil,
            protocolType: TextsAsset.iKEv2
        )
        mockWifiManager.mockConnectedNetwork = network
        await setupPreferences(connectionMode: Fields.Values.auto, selectedProtocol: TextsAsset.wireGuard)

        // When
        let credentialsType = repository.selectedServerCredentialsType()

        // Then
        XCTAssertTrue(credentialsType == IKEv2ServerCredentials.self)
    }

    // MARK: - updateServerConfig Tests

    func testUpdateServerConfig_withValidSession_updatesCredentialsAndConfig() async {
        // Given
        mockPreferences.sessionAuthToReturn = "valid-session-auth"
        let mockOpenVPNCredentials = createMockOpenVPNCredentials()
        let mockConfig = "client\ndev tun"
        let base64Config = mockConfig.data(using: .utf8)!.base64EncodedString()

        mockAPIManager.mockOpenVPNCredentials = mockOpenVPNCredentials
        mockAPIManager.mockOpenVPNServerConfig = base64Config

        // When
        repository.updateServerConfig()

        // Wait for async Task to complete
        let expectation = XCTestExpectation(description: "Update completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then
            XCTAssertNotNil(self.repository.openVPNCrendentials, "Should update OpenVPN credentials")
            XCTAssertTrue(self.mockPreferences.saveOpenVPNCredentialsCalled, "Should save credentials")
            XCTAssertTrue(self.mockFileDatabase.saveFileCalled, "Should save config file")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testUpdateServerConfig_withNoSession_doesNothing() {
        // Given
        mockPreferences.sessionAuthToReturn = nil

        // When
        repository.updateServerConfig()

        // Then - verify no operations were performed
        let expectation = XCTestExpectation(description: "Wait for potential execution")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            XCTAssertFalse(self.mockPreferences.saveOpenVPNCredentialsCalled, "Should not save credentials without session")
            XCTAssertFalse(self.mockFileDatabase.saveFileCalled, "Should not save config without session")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 0.5)
    }

    func testUpdateServerConfig_withAPIFailure_logsError() async {
        // Given
        mockPreferences.sessionAuthToReturn = "valid-session-auth"
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: -1)
        mockLocalDatabase.mockOpenVPNCredentials = nil

        // When
        repository.updateServerConfig()

        // Wait for async Task to complete
        let expectation = XCTestExpectation(description: "Error logged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Then
            XCTAssertTrue(self.mockLogger.logECalled, "Should log error on failure")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Integration Tests

    func testCredentialsLifecycle_loadInitialDataThenUpdate() async throws {
        // Given - Set up initial cached data in Preferences (Keychain)
        let initialOpenVPNCredentials = ServerCredentialsModel(username: "test-openvpn-user", password: "test-openvpn-pass")
        let initialIKEv2Credentials = ServerCredentialsModel(username: "test-ikev2-user", password: "test-ikev2-pass")
        mockPreferences.mockOpenVPNCredentials = initialOpenVPNCredentials
        mockPreferences.mockIKEv2Credentials = initialIKEv2Credentials

        // Create a new repository instance to trigger loadData()
        let newRepository = CredentialsRepositoryImpl(
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase,
            fileDatabase: mockFileDatabase,
            vpnStateRepository: mockVPNStateRepository,
            wifiManager: mockWifiManager,
            preferences: mockPreferences,
            logger: mockLogger
        )

        // Wait for publishers to emit initial values
        let loadExpectation = XCTestExpectation(description: "Initial data loads")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            // Then - Verify initial credentials are loaded
            XCTAssertNotNil(newRepository.openVPNCrendentials, "Should load OpenVPN credentials on init")
            XCTAssertNotNil(newRepository.ikev2Crendentials, "Should load IKEv2 credentials on init")
            loadExpectation.fulfill()
        }
        await fulfillment(of: [loadExpectation], timeout: 0.5)

        // When - Update credentials from API
        let updatedOpenVPNCredentials = OpenVPNServerCredentials()
        updatedOpenVPNCredentials.username = "updated-openvpn-user"
        updatedOpenVPNCredentials.password = "updated-openvpn-pass"
        mockAPIManager.mockOpenVPNCredentials = updatedOpenVPNCredentials
        try await newRepository.getUpdatedOpenVPNCrendentials()

        // Then - Verify updated credentials
        XCTAssertEqual(newRepository.openVPNCrendentials?.username, "updated-openvpn-user")
    }

    // MARK: - Private Helper Methods

    private func createMockWifiNetwork(
        preferredProtocolStatus: Bool = false,
        preferredProtocol: String? = nil,
        protocolType: String = TextsAsset.wireGuard
    ) -> WifiNetworkModel {
        let network = WifiNetwork()
        network.SSID = "TestNetwork"
        network.protocolType = protocolType
        network.port = "443"
        network.preferredProtocol = preferredProtocol ?? "Wireguard"
        network.preferredProtocolStatus = preferredProtocolStatus
        return WifiNetworkModel(from: network)
    }
}
