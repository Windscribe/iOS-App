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
    var mockUserSessionRepository: MockUserSessionRepository!
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
        mockUserSessionRepository = MockUserSessionRepository()

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

        mockContainer.register(UserSessionRepository.self) { _ in
            return self.mockUserSessionRepository
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
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
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

    private func createMockOpenVPNCredentials() -> ServerCredentialsModel {
        ServerCredentialsModel(username: "test-openvpn-user", password: "test-openvpn-pass")
    }

    private func createMockIKEv2Credentials() -> ServerCredentialsModel {
        ServerCredentialsModel(username: "test-ikev2-user", password: "test-ikev2-pass")
    }

    private func createMockAPIOpenVPNCredentials() -> OpenVPNServerCredentials {
        let credentials = OpenVPNServerCredentials()
        credentials.username = "test-openvpn-user"
        credentials.password = "test-openvpn-pass"
        return credentials
    }

    private func createMockAPIIKEv2Credentials() -> IKEv2ServerCredentials {
        let credentials = IKEv2ServerCredentials()
        credentials.username = "test-ikev2-user"
        credentials.password = "test-ikev2-pass"
        return credentials
    }

    private func setupPreferences(connectionMode: String = Fields.Values.auto, selectedProtocol: String = VPNProtocolType.wireGuard.identifier) async {
        // Preferences propagate through: Combine → .receive(on: DispatchQueue.main) → Task → actor method.
        // The actor's loadData() subscribes to the mock subjects in setUp; CurrentValueSubject
        // delivers its seeded value to the new subscriber, queueing an actor Task. If the test
        // sends new values before that initial Task runs, both Tasks land on the actor's
        // executor with no FIFO guarantee — the older value can win and clobber the test setup.
        // Drain the initial-subscription Tasks first, then send.
        await drainPropagation(iterations: 5)

        mockPreferences.mockConnectionMode.send(connectionMode)
        mockPreferences.mockSelectedProtocol.send(selectedProtocol)
        await drainPropagation(iterations: 10)
    }

    private func drainPropagation(iterations: Int) async {
        for _ in 0..<iterations {
            await MainActor.run {
                RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
            }
            try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
        }
    }

    // MARK: - getUpdatedOpenVPNCrendentials Tests

    func testGetUpdatedOpenVPNCredentials_success_savesToDatabaseAndUpdatesProperty() async throws {
        // Given
        mockAPIManager.mockOpenVPNCredentials = createMockAPIOpenVPNCredentials()

        // When
        try await repository.getUpdatedOpenVPNCrendentials()

        // Then
        let credentials = await repository.openVPNCrendentials
        XCTAssertNotNil(credentials, "OpenVPN credentials should be set")
        XCTAssertEqual(credentials?.username, "test-openvpn-user")
        XCTAssertEqual(credentials?.password, "test-openvpn-pass")
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
        let credentials = await repository.openVPNCrendentials
        XCTAssertNotNil(credentials, "Should use cached credentials on API failure")
        XCTAssertEqual(credentials?.username, "test-openvpn-user")
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
        mockAPIManager.mockIKEv2Credentials = createMockAPIIKEv2Credentials()

        // When
        try await repository.getUpdatedIKEv2Crendentials()

        // Then
        let credentials = await repository.ikev2Crendentials
        XCTAssertNotNil(credentials, "IKEv2 credentials should be set")
        XCTAssertEqual(credentials?.username, "test-ikev2-user")
        XCTAssertEqual(credentials?.password, "test-ikev2-pass")
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
        let credentials = await repository.ikev2Crendentials
        XCTAssertNotNil(credentials, "Should use cached credentials on API failure")
        XCTAssertEqual(credentials?.username, "test-ikev2-user")
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
            preferredProtocol: VPNProtocolType.iKEv2.identifier
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
            preferredProtocol: VPNProtocolType.wireGuard.identifier
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
            preferredProtocol: VPNProtocolType.iKEv2.identifier
        )
        mockWifiManager.mockConnectedNetwork = network
        mockVPNStateRepository.isFromProtocolFailover = true
        await setupPreferences(connectionMode: Fields.Values.manual, selectedProtocol: VPNProtocolType.iKEv2.identifier)

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
        await setupPreferences(connectionMode: Fields.Values.manual, selectedProtocol: VPNProtocolType.iKEv2.identifier)

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
            protocolType: VPNProtocolType.iKEv2.identifier
        )
        mockWifiManager.mockConnectedNetwork = network
        await setupPreferences(connectionMode: Fields.Values.auto, selectedProtocol: VPNProtocolType.wireGuard.identifier)

        // When
        let credentialsType = repository.selectedServerCredentialsType()

        // Then
        XCTAssertTrue(credentialsType == IKEv2ServerCredentials.self)
    }

    // MARK: - updateServerConfig Tests

    func testUpdateServerConfig_withValidSession_updatesCredentialsAndConfig() async {
        // Given
        mockPreferences.sessionAuthToReturn = "valid-session-auth"
        let mockConfig = "client\ndev tun"
        let base64Config = mockConfig.data(using: .utf8)!.base64EncodedString()

        mockAPIManager.mockOpenVPNCredentials = createMockAPIOpenVPNCredentials()
        mockAPIManager.mockIKEv2Credentials = createMockAPIIKEv2Credentials()
        mockAPIManager.mockOpenVPNServerConfig = base64Config

        // When
        await repository.updateServerConfig()

        // Wait for async Task to complete
        let expectation = XCTestExpectation(description: "Update completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            Task {
                // Then
                let openVPNCredentials = await self.repository.openVPNCrendentials
                let ikev2Credentials = await self.repository.ikev2Crendentials
                XCTAssertNotNil(openVPNCredentials, "Should update OpenVPN credentials")
                XCTAssertNotNil(ikev2Credentials, "Should update IKEv2 credentials")
                XCTAssertTrue(self.mockPreferences.saveOpenVPNCredentialsCalled, "Should save OpenVPN credentials")
                XCTAssertTrue(self.mockPreferences.saveIKEv2CredentialsCalled, "Should save IKEv2 credentials")
                XCTAssertTrue(self.mockFileDatabase.saveFileCalled, "Should save config file")
                expectation.fulfill()
            }
        }
        await fulfillment(of: [expectation], timeout: 5.0)
    }

    func testUpdateServerConfig_withNoSession_doesNothing() {
        // Given
        mockPreferences.sessionAuthToReturn = nil

        // When
        repository.updateServerConfig()

        // Then - verify no operations were performed
        let expectation = XCTestExpectation(description: "Wait for potential execution")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            XCTAssertFalse(self.mockPreferences.saveOpenVPNCredentialsCalled, "Should not save credentials without session")
            XCTAssertFalse(self.mockFileDatabase.saveFileCalled, "Should not save config without session")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 5.0)
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Then
            XCTAssertTrue(self.mockLogger.logECalled, "Should log error on failure")
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 5.0)
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
            userSessionRepository: mockUserSessionRepository,
            logger: mockLogger
        )

        // Wait for publishers to emit initial values
        let loadExpectation = XCTestExpectation(description: "Initial data loads")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            Task {
                // Then - Verify initial credentials are loaded
                let openVPNCredentials = await newRepository.openVPNCrendentials
                let ikev2Credentials = await newRepository.ikev2Crendentials
                XCTAssertNotNil(openVPNCredentials, "Should load OpenVPN credentials on init")
                XCTAssertNotNil(ikev2Credentials, "Should load IKEv2 credentials on init")
                loadExpectation.fulfill()
            }
        }
        await fulfillment(of: [loadExpectation], timeout: 5.0)

        // When - Update credentials from API
        let updatedOpenVPNCredentials = OpenVPNServerCredentials()
        updatedOpenVPNCredentials.username = "updated-openvpn-user"
        updatedOpenVPNCredentials.password = "updated-openvpn-pass"
        mockAPIManager.mockOpenVPNCredentials = updatedOpenVPNCredentials
        try await newRepository.getUpdatedOpenVPNCrendentials()

        // Then - Verify updated credentials
        let finalCredentials = await newRepository.openVPNCrendentials
        XCTAssertEqual(finalCredentials?.username, "updated-openvpn-user")
    }

    // MARK: - Concurrency Regression Tests (Issue #1060 crash fixes)

    /// RED without fix: CredentialsRepositoryImpl was a class with no synchronization.
    /// Concurrent reads and writes to openVPNCrendentials from multiple threads could
    /// cause data races and crashes.
    /// GREEN with fix: Actor isolation serializes all access — concurrent operations
    /// complete safely without data races.
    func testCredentials_concurrentReadWriteAccess_noDataRace() async throws {
        // Given
        let mockCredentials = createMockAPIOpenVPNCredentials()
        mockAPIManager.mockOpenVPNCredentials = mockCredentials

        // When - fire concurrent credential updates and reads simultaneously
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await self.repository.getUpdatedOpenVPNCrendentials()
                }
                group.addTask {
                    _ = await self.repository.openVPNCrendentials
                }
            }
        }

        // Then - should complete without crash; final state should be valid
        let credentials = await repository.openVPNCrendentials
        XCTAssertNotNil(credentials, "Credentials should be set after concurrent access")
        XCTAssertEqual(credentials?.username, "test-openvpn-user")
    }

    /// RED without fix: Concurrent reads and writes to ikev2Crendentials had the
    /// same class-level data race as openVPNCrendentials.
    /// GREEN with fix: Actor serializes IKEv2 credential access too.
    func testIKEv2Credentials_concurrentReadWriteAccess_noDataRace() async throws {
        // Given
        let mockCredentials = createMockAPIIKEv2Credentials()
        mockAPIManager.mockIKEv2Credentials = mockCredentials

        // When - fire concurrent IKEv2 credential updates and reads
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    try? await self.repository.getUpdatedIKEv2Crendentials()
                }
                group.addTask {
                    _ = await self.repository.ikev2Crendentials
                }
            }
        }

        // Then
        let credentials = await repository.ikev2Crendentials
        XCTAssertNotNil(credentials, "IKEv2 credentials should be set after concurrent access")
        XCTAssertEqual(credentials?.username, "test-ikev2-user")
    }

    /// RED without fix: Multiple rapid updateServerConfig() calls would each spawn
    /// independent Tasks that all ran to completion, racing on shared mutable state.
    /// GREEN with fix: updateTask cancellation pattern ensures only the most recent
    /// call runs to completion; earlier calls are cancelled.
    func testUpdateServerConfig_rapidConsecutiveCalls_doesNotCrash() async {
        // Given
        mockPreferences.sessionAuthToReturn = "valid-session-auth"
        let mockCredentials = createMockAPIOpenVPNCredentials()
        let mockIKEv2Credentials = createMockAPIIKEv2Credentials()
        mockAPIManager.mockOpenVPNCredentials = mockCredentials
        mockAPIManager.mockIKEv2Credentials = mockIKEv2Credentials
        let base64Config = "client\ndev tun".data(using: .utf8)!.base64EncodedString()
        mockAPIManager.mockOpenVPNServerConfig = base64Config

        // When - fire multiple rapid consecutive calls
        for _ in 0..<5 {
            await repository.updateServerConfig()
        }

        // Wait for the debounced task to complete
        let expectation = XCTestExpectation(description: "Final update completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        // Then - should not crash; credentials should be in a valid state
        let credentials = await repository.openVPNCrendentials
        // The last call should have completed successfully
        XCTAssertNotNil(credentials, "Final updateServerConfig call should set credentials")
    }

    /// RED without fix: Concurrent updateServerConfig calls from different threads
    /// would create multiple overlapping Tasks mutating shared state simultaneously.
    /// GREEN with fix: Actor isolation + task cancellation prevents concurrent execution.
    func testUpdateServerConfig_concurrentCalls_doesNotRace() async {
        // Given
        mockPreferences.sessionAuthToReturn = "valid-session-auth"
        let mockCredentials = createMockAPIOpenVPNCredentials()
        let mockIKEv2Credentials = createMockAPIIKEv2Credentials()
        mockAPIManager.mockOpenVPNCredentials = mockCredentials
        mockAPIManager.mockIKEv2Credentials = mockIKEv2Credentials
        let base64Config = "client\ndev tun".data(using: .utf8)!.base64EncodedString()
        mockAPIManager.mockOpenVPNServerConfig = base64Config

        // When - fire concurrent updateServerConfig calls from multiple tasks
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await self.repository.updateServerConfig()
                }
            }
        }

        // Wait for any remaining async work
        let expectation = XCTestExpectation(description: "All updates settle")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            expectation.fulfill()
        }
        await fulfillment(of: [expectation], timeout: 2.0)

        // Then - should complete without crash
        // The actor ensures only one task runs at a time, previous ones are cancelled
        let credentials = await repository.openVPNCrendentials
        XCTAssertNotNil(credentials, "Credentials should be set after concurrent updates")
    }

    /// RED without fix: Combine sinks used [self] (strong capture) which could keep
    /// CredentialsRepositoryImpl alive after its consumer released it, leading to
    /// use-after-free style crashes when the captured self was in an inconsistent state.
    /// GREEN with fix: [weak self] capture + Task dispatch prevents retain cycles.
    func testRepository_doesNotRetainCycleWithPublishers() async {
        // Given - create repository and let publishers emit
        var repo: CredentialsRepository? = CredentialsRepositoryImpl(
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase,
            fileDatabase: mockFileDatabase,
            vpnStateRepository: mockVPNStateRepository,
            wifiManager: mockWifiManager,
            preferences: mockPreferences,
            userSessionRepository: mockUserSessionRepository,
            logger: mockLogger
        )
        weak var weakRepo = repo as AnyObject?

        // When - let publishers fire, then release the strong reference
        mockPreferences.mockConnectionMode.send("manual")
        mockPreferences.mockSelectedProtocol.send(VPNProtocolType.wireGuard.identifier)

        // Wait for publisher dispatch
        let setupExpectation = XCTestExpectation(description: "Publishers emit")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            setupExpectation.fulfill()
        }
        await fulfillment(of: [setupExpectation], timeout: 5.0)

        repo = nil

        // Wait for deallocation
        let deallocExpectation = XCTestExpectation(description: "Deallocation")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            deallocExpectation.fulfill()
        }
        await fulfillment(of: [deallocExpectation], timeout: 5.0)

        // Then - repository should be deallocated (no retain cycle)
        XCTAssertNil(weakRepo, "Repository should be deallocated — no retain cycle from publishers")
    }

    // MARK: - Private Helper Methods

    private func createMockWifiNetwork(
        preferredProtocolStatus: Bool = false,
        preferredProtocol: String? = nil,
        protocolType: String = VPNProtocolType.wireGuard.identifier
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
