//
//  BridgeApiRepositoryTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import NetworkExtension
@testable import Windscribe
import XCTest

class BridgeApiRepositoryTests: XCTestCase {
    var mockBridgeAPI: MockWSNetBridgeAPI!
    var mockLocationsManager: MockLocationsManager!
    var mockUserSessionRepository: MockUserSessionRepository!
    var mockVPNStateRepository: MockVPNStateRepository!
    var mockLogger: MockLogger!
    var mockProtocolManager: MockProtocolManager!
    var mockPreferences: MockPreferences!
    var repository: BridgeApiRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockBridgeAPI = MockWSNetBridgeAPI()
        mockLocationsManager = MockLocationsManager()
        mockUserSessionRepository = MockUserSessionRepository()
        mockVPNStateRepository = MockVPNStateRepository()
        mockLogger = MockLogger()
        mockProtocolManager = MockProtocolManager()
        mockPreferences = MockPreferences()
        cancellables = Set<AnyCancellable>()

        repository = BridgeApiRepositoryImpl(
            bridgeAPI: mockBridgeAPI,
            locationManager: mockLocationsManager,
            userSessionRepository: mockUserSessionRepository,
            vpnStateRepository: mockVPNStateRepository,
            logger: mockLogger,
            protocolManager: mockProtocolManager,
            preferences: mockPreferences
        )
    }

    override func tearDown() {
        cancellables = nil
        repository = nil
        mockBridgeAPI = nil
        mockLocationsManager = nil
        mockUserSessionRepository = nil
        mockVPNStateRepository = nil
        mockLogger = nil
        mockProtocolManager = nil
        mockPreferences = nil
        super.tearDown()
    }

    // MARK: - Initialization Tests

    func testInitialization() {
        XCTAssertNotNil(repository, "Repository should be initialized")
        XCTAssertFalse(repository.isReady, "Should not be ready initially")
        XCTAssertTrue(mockBridgeAPI.setApiAvailableCallbackCalled, "Should set API available callback")
    }

    // MARK: - VPN Connection State Tests

    func testVPNDisconnectedSetsBridgeAPIToDisconnected() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bridge API should be set to disconnected")

        // Wait a bit for the initial observation to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // When
        mockVPNStateRepository.simulateStatusChange(.disconnected)

        // Give time for the async observation to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertTrue(mockBridgeAPI.setConnectedStateCalled, "Should call setConnectedState")
        XCTAssertEqual(mockBridgeAPI.lastConnectedState, false, "Should set connected state to false")

        expectation.fulfill()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testVPNConnectedWithWireGuardSetsCurrentHost() async throws {
        // Given
        let testHost = "192.168.1.1"
        mockPreferences.mockLastNodeIP = testHost
        let vpnInfo = VPNConnectionInfo(selectedProtocol: "WireGuard",
                                        selectedPort: "443",
                                        status: .disconnected,
                                        server: testHost,
                                        killSwitch: false,
                                        onDemand: false)
        mockVPNStateRepository.vpnInfo.send(vpnInfo)

        // When - Simulate initial connection
        mockVPNStateRepository.simulateStatusChange(.connected)

        // Give time for the async observation to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertTrue(mockBridgeAPI.setCurrentHostCalled, "Should call setCurrentHost")
        XCTAssertEqual(mockBridgeAPI.lastCurrentHost, testHost, "Should set correct host")
        XCTAssertTrue(mockBridgeAPI.setIgnoreSslErrorsCalled, "Should call setIgnoreSslErrors")
        XCTAssertEqual(mockBridgeAPI.lastIgnoreSslErrors, true, "Should set ignoreSslErrors to true")
        XCTAssertTrue(mockBridgeAPI.setConnectedStateCalled, "Should call setConnectedState")
        XCTAssertEqual(mockBridgeAPI.lastConnectedState, true, "Should set connected state to true")
    }

    func testVPNConnectedWithNonWireGuardSetsEmptyHost() async throws {
        // Given
        let testHost = "192.168.1.1"
        mockPreferences.mockLastNodeIP = testHost
        let vpnInfo = VPNConnectionInfo(selectedProtocol: "OpenVPN",
                                        selectedPort: "443",
                                        status: .disconnected,
                                        server: testHost,
                                        killSwitch: false,
                                        onDemand: false)
        mockVPNStateRepository.vpnInfo.send(vpnInfo)

        // When - Simulate initial connection
        mockVPNStateRepository.simulateStatusChange(.connected)

        // Give time for the async observation to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertTrue(mockBridgeAPI.setCurrentHostCalled, "Should call setCurrentHost")
        XCTAssertEqual(mockBridgeAPI.lastCurrentHost, "", "Should set empty host for non-WireGuard")
    }

    func testVPNDisconnectAfterConnectionResetsState() async throws {
        // Given - First connect
        mockVPNStateRepository.simulateStatusChange(.connected)
        try await Task.sleep(nanoseconds: 300_000_000)

        // Reset tracking
        mockBridgeAPI.setConnectedStateCalled = false
        mockBridgeAPI.setConnectedStateCallCount = 0

        // When - Then disconnect
        mockVPNStateRepository.simulateStatusChange(.disconnected)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertTrue(mockBridgeAPI.setConnectedStateCalled, "Should call setConnectedState on disconnect")
        XCTAssertEqual(mockBridgeAPI.lastConnectedState, false, "Should set connected state to false")
    }

    // MARK: - API Availability Tests

    func testApiAvailableWithProUserAndServerLocation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bridge API should be available")

        mockUserSessionRepository.sessionModel = SessionModel(
            sessionAuthHash: "test",
            username: "testuser",
            userId: "123",
            isUserPro: true,
            isPremium: true,
            email: "test@test.com",
            emailStatus: true,
            billing: nil,
            alc: [],
            rebill: 0,
            billingPlanId: 1,
            trafficUsed: 0,
            trafficMax: 0,
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: nil,
            regDate: "2024-01-01",
            deviceId: "device123",
            sipCount: 0,
            loc: "",
            locHash: "",
            revisionHash: "",
            amneziawgConfigId: ""
        )

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Best Location",
            cityName: "New York",
            countryCode: "US",
            isServer: true
        )

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Wait for observation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        repository.bridgeIsAvailable
            .sink { isAvailable in
                if isAvailable {
                    XCTAssertTrue(isAvailable, "Bridge API should be available for pro user")
                    XCTAssertTrue(self.repository.isReady, "Repository should be ready")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testApiAvailableWithFreeUserAndALCLocation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bridge API should be available with ALC")

        mockUserSessionRepository.sessionModel = SessionModel(
            sessionAuthHash: "test",
            username: "testuser",
            userId: "123",
            isUserPro: false,
            isPremium: false,
            email: "test@test.com",
            emailStatus: true,
            billing: nil,
            alc: ["US", "GB"],
            rebill: 0,
            billingPlanId: 0,
            trafficUsed: 0,
            trafficMax: 0,
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: nil,
            regDate: "2024-01-01",
            deviceId: "device123",
            sipCount: 0,
            loc: "",
            locHash: "",
            revisionHash: "",
            amneziawgConfigId: ""
        )
        // The ALC check now lives inside UserSessionRepository (tested separately
        // in UserSessionRepositoryTests). BridgeApiRepository delegates via
        // canAccesstoProLocation(locationId:), so we tell the mock the result.
        mockUserSessionRepository.mockCanAccessProLocation = true

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Best Location",
            cityName: "New York",
            countryCode: "US",
            isServer: true
        )

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Wait for observation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        repository.bridgeIsAvailable
            .sink { isAvailable in
                if isAvailable {
                    XCTAssertTrue(isAvailable, "Bridge API should be available for ALC location")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testApiNotAvailableWithFreeUserAndNonALCLocation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bridge API should not be available")

        mockUserSessionRepository.sessionModel = SessionModel(
            sessionAuthHash: "test",
            username: "testuser",
            userId: "123",
            isUserPro: false,
            isPremium: false,
            email: "test@test.com",
            emailStatus: true,
            billing: nil,
            alc: ["GB", "CA"],
            rebill: 0,
            billingPlanId: 0,
            trafficUsed: 0,
            trafficMax: 0,
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: nil,
            regDate: "2024-01-01",
            deviceId: "device123",
            sipCount: 0,
            loc: "",
            locHash: "",
            revisionHash: "",
            amneziawgConfigId: ""
        )

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Best Location",
            cityName: "New York",
            countryCode: "US",
            isServer: true
        )

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Wait for observation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        repository.bridgeIsAvailable
            .sink { isAvailable in
                if !isAvailable {
                    XCTAssertFalse(isAvailable, "Bridge API should not be available for non-ALC location")
                    XCTAssertFalse(self.repository.isReady, "Repository should not be ready")
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testApiNotAvailableWithoutSessionModel() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bridge API should not be available without session")

        mockUserSessionRepository.sessionModel = nil

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Best Location",
            cityName: "New York",
            countryCode: "US",
            isServer: true
        )

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Wait for observation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        repository.bridgeIsAvailable
            .sink { isAvailable in
                XCTAssertFalse(isAvailable, "Bridge API should not be available without session model")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 0.5)
    }

    func testApiNotAvailableWithNonServerLocation() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bridge API should not be available for non-server")

        mockUserSessionRepository.sessionModel = SessionModel(
            sessionAuthHash: "test",
            username: "testuser",
            userId: "123",
            isUserPro: true,
            isPremium: true,
            email: "test@test.com",
            emailStatus: true,
            billing: nil,
            alc: [],
            rebill: 0,
            billingPlanId: 1,
            trafficUsed: 0,
            trafficMax: 0,
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: nil,
            regDate: "2024-01-01",
            deviceId: "device123",
            sipCount: 0,
            loc: "",
            locHash: "",
            revisionHash: "",
            amneziawgConfigId: ""
        )

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Custom Config",
            cityName: "",
            countryCode: "",
            isServer: false
        )

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Wait for observation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        repository.bridgeIsAvailable
            .sink { isAvailable in
                XCTAssertFalse(isAvailable, "Bridge API should not be available for non-server location")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 0.5)
    }

    func testApiNotAvailableWhenBridgeAPIReportsNotReady() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Bridge API should not be available when not ready")

        mockUserSessionRepository.sessionModel = SessionModel(
            sessionAuthHash: "test",
            username: "testuser",
            userId: "123",
            isUserPro: true,
            isPremium: true,
            email: "test@test.com",
            emailStatus: true,
            billing: nil,
            alc: [],
            rebill: 0,
            billingPlanId: 1,
            trafficUsed: 0,
            trafficMax: 0,
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: nil,
            regDate: "2024-01-01",
            deviceId: "device123",
            sipCount: 0,
            loc: "",
            locHash: "",
            revisionHash: "",
            amneziawgConfigId: ""
        )

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Best Location",
            cityName: "New York",
            countryCode: "US",
            isServer: true
        )

        // When
        mockBridgeAPI.simulateApiAvailable(false)

        // Wait for observation
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        repository.bridgeIsAvailable
            .sink { isAvailable in
                XCTAssertFalse(isAvailable, "Bridge API should not be available when bridge reports not ready")
                expectation.fulfill()
            }
            .store(in: &cancellables)

        await fulfillment(of: [expectation], timeout: 0.5)
    }

    // MARK: - Edge Cases

    func testMultipleConnectionStateChanges() async throws {
        // Given
        try await Task.sleep(nanoseconds: 100_000_000)

        // When - Rapid state changes
        mockVPNStateRepository.simulateStatusChange(.connecting)
        try await Task.sleep(nanoseconds: 50_000_000)

        mockVPNStateRepository.simulateStatusChange(.connected)
        try await Task.sleep(nanoseconds: 300_000_000)

        mockVPNStateRepository.simulateStatusChange(.disconnecting)
        try await Task.sleep(nanoseconds: 50_000_000)

        mockVPNStateRepository.simulateStatusChange(.disconnected)
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then - Should handle all state changes
        XCTAssertTrue(mockBridgeAPI.setConnectedStateCallCount >= 2, "Should handle multiple state changes")
        XCTAssertEqual(mockBridgeAPI.lastConnectedState, false, "Final state should be disconnected")
    }

    func testIsReadyPropertyReflectsBridgeAvailability() async throws {
        // Given
        XCTAssertFalse(repository.isReady, "Should not be ready initially")

        mockUserSessionRepository.sessionModel = SessionModel(
            sessionAuthHash: "test",
            username: "testuser",
            userId: "123",
            isUserPro: true,
            isPremium: true,
            email: "test@test.com",
            emailStatus: true,
            billing: nil,
            alc: [],
            rebill: 0,
            billingPlanId: 1,
            trafficUsed: 0,
            trafficMax: 0,
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: nil,
            regDate: "2024-01-01",
            deviceId: "device123",
            sipCount: 0,
            loc: "",
            locHash: "",
            revisionHash: "",
            amneziawgConfigId: ""
        )

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Best Location",
            cityName: "New York",
            countryCode: "US",
            isServer: true
        )

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Wait for state to update
        try await Task.sleep(nanoseconds: 200_000_000)

        // Then
        XCTAssertTrue(repository.isReady, "Should be ready after API becomes available")
    }
}
