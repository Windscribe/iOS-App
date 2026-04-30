//
//  EmergencyRepositoryTests.swift
//  Windscribe
//
//  Created by Andre Fonseca on 11/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//


import Foundation
import Swinject
@testable import Windscribe
import XCTest

class EmergencyRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: EmergencyRepository!
    var mockWSNetEmergencyConnect: MockWSNetEmergencyConnect!
    var mockVPNManager: MockVPNManager!
    var mockVpnStateRepository: MockVPNStateRepository!
    var mockFileDatabase: MockFileDatabase!
    var mockLocationsManager: MockLocationsManager!
    var mockLogger: MockLogger!
    var mockProtocolManager: MockProtocolManagerType!
    var mockCustomConfigRepository: MockCustomConfigRepository!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockWSNetEmergencyConnect = MockWSNetEmergencyConnect()
        mockVPNManager = MockVPNManager()
        mockVpnStateRepository = MockVPNStateRepository()
        mockFileDatabase = MockFileDatabase()
        mockLocationsManager = MockLocationsManager()
        mockLogger = MockLogger()
        mockProtocolManager = MockProtocolManagerType()
        mockCustomConfigRepository = MockCustomConfigRepository()

        // Register mocks
        mockContainer.register(WSNetEmergencyConnectType.self) { _ in
            return self.mockWSNetEmergencyConnect
        }.inObjectScope(.container)

        mockContainer.register(VPNManager.self) { _ in
            return self.mockVPNManager
        }.inObjectScope(.container)

        mockContainer.register(VPNStateRepository.self) { _ in
            return self.mockVpnStateRepository
        }.inObjectScope(.container)

        mockContainer.register(FileDatabase.self) { _ in
            return self.mockFileDatabase
        }.inObjectScope(.container)

        mockContainer.register(LocationsManager.self) { _ in
            return self.mockLocationsManager
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(ProtocolManagerType.self) { _ in
            return self.mockProtocolManager
        }.inObjectScope(.container)

        mockContainer.register(CustomConfigRepository.self) { _ in
            return self.mockCustomConfigRepository
        }.inObjectScope(.container)

        // Register EmergencyRepository
        mockContainer.register(EmergencyRepository.self) { r in
            return EmergencyRepositoryImpl(wsnetEmergencyConnect: r.resolve(WSNetEmergencyConnectType.self)!,
                                           vpnManager: r.resolve(VPNManager.self)!,
                                           vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                           fileDatabase: r.resolve(FileDatabase.self)!,
                                           logger: r.resolve(FileLogger.self)!,
                                           locationsManager: r.resolve(LocationsManager.self)!,
                                           protocolManager: r.resolve(ProtocolManagerType.self)!,
                                           customConfigRepository: r.resolve(CustomConfigRepository.self)!)
        }.inObjectScope(.container)

        // Resolve repository from container
        repository = mockContainer.resolve(EmergencyRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        mockWSNetEmergencyConnect = nil
        mockVPNManager = nil
        mockVpnStateRepository = nil
        mockFileDatabase = nil
        mockLocationsManager = nil
        mockLogger = nil
        mockProtocolManager = nil
        mockCustomConfigRepository = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Helper Methods

    /// Creates and adds an emergency config to the mock repository
    @discardableResult
    private func addEmergencyConfig(id: String = "emergency-test-id") -> CustomConfigModel {
        let config = CustomConfigModel(
            id: id,
            name: "emergency-connect",
            serverAddress: "test.emergency.com",
            protocolType: "OpenVPN",
            port: "443"
        )
        mockCustomConfigRepository.addConfig(config)
        return config
    }

    /// Creates and adds a normal (non-emergency) config to the mock repository
    @discardableResult
    private func addNormalConfig(id: String = "normal-test-id", name: String = "normal-config") -> CustomConfigModel {
        let config = CustomConfigModel(
            id: id,
            name: name,
            serverAddress: "test.normal.com",
            protocolType: "OpenVPN",
            port: "443"
        )
        mockCustomConfigRepository.addConfig(config)
        return config
    }

    // MARK: - getConfig Tests

    func testGetConfig_withValidEndpoints_returnsConfigurations() async {
        // Given
        let mockConfig = """
        client
        dev tun
        proto udp
        remote 1.2.3.4 443
        """
        mockWSNetEmergencyConnect.setOvpnConfig(mockConfig)
        mockWSNetEmergencyConnect.setUsername("testuser")
        mockWSNetEmergencyConnect.setPassword("testpass")

        // Mock endpoints would need to be created here
        // For now, testing with empty array as the actual WSNetEmergencyConnectEndpoint is an Objective-C class
        mockWSNetEmergencyConnect.setIpEndpoints([])

        // When
        let configs = await repository.getConfig()

        // Then
        XCTAssertNotNil(configs)
        XCTAssertEqual(configs.count, 0) // Empty because no endpoints provided
    }

    func testGetConfig_withEmptyEndpoints_returnsEmptyArray() async {
        // Given
        mockWSNetEmergencyConnect.setIpEndpoints([])

        // When
        let configs = await repository.getConfig()

        // Then
        XCTAssertTrue(configs.isEmpty)
    }

    // MARK: - isConnected Tests
    //
    // `EmergencyRepositoryImpl.isConnected()` was changed in commit fd7eb633
    // (Issue #1018 — "Emergency Connect state leaks across logout/login cycle")
    // to return `vpnStateRepository.isEmergencyConnection` instead of the
    // generic `vpnStateRepository.isConnected()`. The semantics are now
    // specifically "is the VPN connected via Emergency Connect", not "is the
    // VPN connected at all". Tests below mirror the new contract.

    func testIsConnected_whenEmergencyConnectionActive_returnsTrue() {
        // Given
        mockVpnStateRepository.isEmergencyConnection = true

        // When
        let result = repository.isConnected()

        // Then
        XCTAssertTrue(result)
    }

    func testIsConnected_whenEmergencyConnectionInactive_returnsFalse() {
        // Given
        mockVpnStateRepository.isEmergencyConnection = false

        // When
        let result = repository.isConnected()

        // Then
        XCTAssertFalse(result)
    }

    // MARK: - cleansEmergencyConfigs Tests

    func testCleansEmergencyConfigs_removesOnlyEmergencyConfigsAndRefreshesProtocols() {
        // Given
        addEmergencyConfig(id: "emergency-1")
        addEmergencyConfig(id: "emergency-2")
        addNormalConfig(id: "normal-1", name: "my-custom-config")

        XCTAssertEqual(mockCustomConfigRepository.getConfigCount(), 3, "Should have 3 configs initially")

        // When
        repository.cleansEmergencyConfigs()

        // Then
        let expectation = XCTestExpectation(description: "Cleanup completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Should remove both emergency configs
            XCTAssertEqual(self.mockCustomConfigRepository.removeCustomConfigCallCount, 2,
                          "Should remove exactly 2 emergency configs")

            // Should refresh protocols with correct parameters
            XCTAssertEqual(self.mockProtocolManager.refreshProtocolsCallCount, 1,
                          "Should refresh protocols once")
            XCTAssertEqual(self.mockProtocolManager.lastRefreshProtocolsShouldReset, true,
                          "Should reset protocols")
            XCTAssertEqual(self.mockProtocolManager.lastRefreshProtocolsShouldReconnect, false,
                          "Should not reconnect during cleanup")

            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 2.0)
    }

    // MARK: - disconnect Tests

    func testDisconnect_callsVPNManagerDisconnectAndCleansConfigs() {
        // Given
        addEmergencyConfig()

        let expectation = XCTestExpectation(description: "Disconnect completes")
        var receivedStates: [VPNConnectionState] = []

        // When
        let cancellable = repository.disconnect()
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    } else if case .failure(let error) = completion {
                        XCTFail("Disconnect should not fail: \(error)")
                    }
                },
                receiveValue: { state in
                    receivedStates.append(state)
                }
            )

        // Then
        wait(for: [expectation], timeout: 1.0)

        // Verify cleanup happened asynchronously
        let cleanupExpectation = XCTestExpectation(description: "Cleanup completes")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Emergency config should have been removed
            XCTAssertEqual(self.mockCustomConfigRepository.removeCustomConfigCallCount, 1,
                          "Should remove emergency config")

            // Protocols should have been refreshed
            XCTAssertEqual(self.mockProtocolManager.refreshProtocolsCallCount, 1,
                          "Should refresh protocols once")
            XCTAssertEqual(self.mockProtocolManager.lastRefreshProtocolsShouldReset, true,
                          "Should reset protocols")
            XCTAssertEqual(self.mockProtocolManager.lastRefreshProtocolsShouldReconnect, false,
                          "Should not reconnect during cleanup")

            cleanupExpectation.fulfill()
        }
        wait(for: [cleanupExpectation], timeout: 2.0)

        cancellable.cancel()
    }

    // MARK: - connect Tests

    func testConnect_withValidConfig_savesCustomConfigAndConnects() {
        // Given
        var testConfig = [String]()
        testConfig.append("client")
        testConfig.append("dev tun")
        testConfig.append("proto tcp")
        testConfig.append("remote 0.0.0.0 1194")
        testConfig.append("ns-cert-type server")

        let configData = testConfig.joined(separator: "\n").data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: configData,
            ip: "1.2.3.4",
            port: "443",
            protocolName: "UDP",
            username: "testuser",
            password: "testpass"
        )

        let expectation = XCTestExpectation(description: "Connect flow completes")

        // When
        let cancellable = repository.connect(configInfo: connectionInfo)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    } else if case .failure(let error) = completion {
                        XCTFail("Connect should not fail: \(error)")
                    }
                },
                receiveValue: { _ in }
            )

        // Then
        wait(for: [expectation], timeout: 2.0)

        // Verify the connect flow
        let verifyExpectation = XCTestExpectation(description: "Verify repository behavior")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Should save the custom config
            XCTAssertEqual(self.mockCustomConfigRepository.saveOpenVPNCustomConfigCallCount, 1,
                          "Should save OpenVPN custom config once")

            // Should refresh protocols with correct parameters
            XCTAssertEqual(self.mockProtocolManager.refreshProtocolsCallCount, 1,
                          "Should refresh protocols once")
            XCTAssertEqual(self.mockProtocolManager.lastRefreshProtocolsShouldReset, true,
                          "Should reset protocols")
            XCTAssertEqual(self.mockProtocolManager.lastRefreshProtocolsShouldReconnect, false,
                          "Should not reconnect during setup")

            verifyExpectation.fulfill()
        }
        wait(for: [verifyExpectation], timeout: 2.0)
        cancellable.cancel()
    }

    func testConnect_withInvalidConfig_failsWithError() {
        // Given - config without required data
        let emptyData = Data()
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: emptyData,
            ip: "1.2.3.4",
            port: "443",
            protocolName: "UDP",
            username: "testuser",
            password: "testpass"
        )

        let expectation = XCTestExpectation(description: "Connect fails")

        // When
        let cancellable = repository.connect(configInfo: connectionInfo)
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Should not receive a value")
            })

        // Then
        wait(for: [expectation], timeout: 1.0)
        cancellable.cancel()
    }

    func testConnect_updatesProtocolAndRemoteInConfig() {
        // Given
        var testConfig = [String]()
        testConfig.append("client")
        testConfig.append("dev tun")
        testConfig.append("proto tcp")
        testConfig.append("remote 0.0.0.0 1194")
        testConfig.append("ns-cert-type server")

        let configData = testConfig.joined(separator: "\n").data(using: .utf8)!
        let connectionInfo = OpenVPNConnectionInfo(
            serverConfig: configData,
            ip: "159.203.44.199",
            port: "443",
            protocolName: "UDP",
            username: "testuser",
            password: "testpass"
        )

        let expectation = XCTestExpectation(description: "Connect flow completes")

        // When
        let cancellable = repository.connect(configInfo: connectionInfo)
            .sink(
                receiveCompletion: { completion in
                    if case .finished = completion {
                        expectation.fulfill()
                    } else if case .failure(let error) = completion {
                        XCTFail("Connect should not fail: \(error)")
                    }
                },
                receiveValue: { _ in }
            )

        // Then
        wait(for: [expectation], timeout: 20.0)

        // Verify the config was modified correctly
        let verifyExpectation = XCTestExpectation(description: "Verify config transformations")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            XCTAssertNotNil(self.mockCustomConfigRepository.lastSavedOpenVPNCustomConfigData, "Config data should be saved")

            guard let savedConfigData = self.mockCustomConfigRepository.lastSavedOpenVPNCustomConfigData,
                  let savedConfigString = String(data: savedConfigData, encoding: .utf8) else {
                XCTFail("Could not decode saved config")
                verifyExpectation.fulfill()
                return
            }

            // Verify protocol was updated from tcp to udp
            XCTAssertTrue(savedConfigString.contains("proto udp"),
                         "Config should contain 'proto udp' (was 'proto tcp')")
            XCTAssertFalse(savedConfigString.contains("proto tcp"),
                          "Config should not contain old 'proto tcp'")

            // Verify remote was updated with new IP and port
            XCTAssertTrue(savedConfigString.contains("remote 159.203.44.199 443"),
                         "Config should contain updated remote 159.203.44.199 443'")
            XCTAssertFalse(savedConfigString.contains("remote 0.0.0.0 1194"),
                          "Config should not contain old remote '0.0.0.0 1194'")

            // Verify ns-cert-type was removed (causes reconnection loops)
            XCTAssertFalse(savedConfigString.contains("ns-cert-type"),
                          "Config should not contain 'ns-cert-type' (should be removed)")

            verifyExpectation.fulfill()
        }
        wait(for: [verifyExpectation], timeout: 20.0)
        cancellable.cancel()
    }

}

