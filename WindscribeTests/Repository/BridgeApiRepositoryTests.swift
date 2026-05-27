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

    func testInitialization() async throws {
        XCTAssertNotNil(repository, "Repository should be initialized")
        XCTAssertFalse(repository.isReady, "Should not be ready initially")
        XCTAssertTrue(mockBridgeAPI.setApiAvailableCallbackCalled, "Call back should be set on the BridegeAPIRepository init")
    }

    // MARK: - VPN Connection State Tests

    func testVPNDisconnectedSetsBridgeAPIToDisconnected() async throws {
        // Wait a bit for the initial observation to complete
        try await Task.sleep(nanoseconds: 200_000_000)

        // When
        mockVPNStateRepository.simulateStatusChange(.disconnected)

        // Wait for async observation to propagate
        try await waitUntil(timeout: 5.0) { self.mockBridgeAPI.setConnectedStateCalled }

        // Then
        XCTAssertTrue(mockBridgeAPI.setConnectedStateCalled, "Should call setConnectedState")
        XCTAssertEqual(mockBridgeAPI.lastConnectedState, false, "Should set connected state to false")
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

        // Wait for the async observation to propagate
        try await waitUntil(timeout: 5.0) { self.mockBridgeAPI.setConnectedStateCalled }

        // Then
        XCTAssertTrue(mockBridgeAPI.setCurrentHostCalled, "Should call setCurrentHost")
        XCTAssertEqual(mockBridgeAPI.lastCurrentHost, testHost, "Should set correct host")
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

        // Wait for the async observation to propagate
        try await waitUntil(timeout: 5.0) { self.mockBridgeAPI.setCurrentHostCalled }

        // Then
        XCTAssertTrue(mockBridgeAPI.setCurrentHostCalled, "Should call setCurrentHost")
        XCTAssertEqual(mockBridgeAPI.lastCurrentHost, "", "Should set empty host for non-WireGuard")
    }

    func testVPNDisconnectAfterConnectionResetsState() async throws {
        // Given - First connect
        mockVPNStateRepository.simulateStatusChange(.connected)
        try await waitUntil(timeout: 5.0) { self.mockBridgeAPI.setConnectedStateCalled }

        // Reset tracking
        mockBridgeAPI.setConnectedStateCalled = false
        mockBridgeAPI.setConnectedStateCallCount = 0

        // When - Then disconnect
        mockVPNStateRepository.simulateStatusChange(.disconnected)
        try await waitUntil(timeout: 5.0) { self.mockBridgeAPI.setConnectedStateCalled }

        // Then
        XCTAssertTrue(mockBridgeAPI.setConnectedStateCalled, "Should call setConnectedState on disconnect")
        XCTAssertEqual(mockBridgeAPI.lastConnectedState, false, "Should set connected state to false")
    }

    // MARK: - API Availability Tests

    func testApiAvailableWithProUserAndServerLocation() async throws {
        // Given
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

        updateMockLocation()

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Then — poll for the actual state change instead of relying on
        // XCTestExpectation + Combine publisher timing, which races on loaded
        // CI runners (the publisher chain can take >5s under load).
        try await waitUntil(timeout: 10.0) { self.repository.isReady }
        XCTAssertTrue(repository.isReady, "Repository should be ready")
    }

    func testApiAvailableWithFreeUserAndALCLocation() async throws {
        // Given
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

        updateMockLocation()

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Then — poll for the actual state change instead of relying on
        // XCTestExpectation + Combine publisher timing, which races on loaded
        // CI runners.
        try await waitUntil(timeout: 10.0) { self.repository.isReady }
        XCTAssertTrue(repository.isReady, "Repository should be ready with ALC")
    }

    func testApiNotAvailableWithFreeUserAndNonALCLocation() async throws {
        // Given
        mockUserSessionRepository.sessionModel = SessionModel(
            sessionAuthHash: "test",
            username: "testuser",
            userId: "123",
            isUserPro: false,
            isPremium: false,
            email: "test@test.com",
            emailStatus: true,
            billing: nil,
            alc: [],
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

        updateMockLocation()

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Then — allow async propagation, then verify state settled to not-ready
        // (non-ALC location for free user should be denied).
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(repository.isReady, "Repository should not be ready for non-ALC location")
    }

    func testApiNotAvailableWithoutSessionModel() async throws {
        // Given
        mockUserSessionRepository.sessionModel = nil

        mockLocationsManager.mockLocationUIInfo = LocationUIInfo(
            nickName: "Best Location",
            cityName: "New York",
            countryCode: "US",
            isServer: true
        )

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        // Then — allow propagation, verify not ready (no session).
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(repository.isReady, "Repository should not be ready without session model")
    }

    func testApiNotAvailableWithNonServerLocation() async throws {
        // Given
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

        // Then — allow propagation, verify not ready (non-server location).
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(repository.isReady, "Repository should not be ready for non-server location")
    }

    func testApiNotAvailableWhenBridgeAPIReportsNotReady() async throws {
        // Given
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

        // When — bridge reports NOT available
        mockBridgeAPI.simulateApiAvailable(false)

        // Then — allow propagation, verify not ready.
        try await Task.sleep(nanoseconds: 500_000_000)
        XCTAssertFalse(repository.isReady, "Repository should not be ready when bridge reports not ready")
    }

    // MARK: - Edge Cases

    func testMultipleConnectionStateChanges() async throws {
        // Given
        try await Task.sleep(nanoseconds: 200_000_000)

        // When - Rapid state changes
        mockVPNStateRepository.simulateStatusChange(.connecting)
        try await Task.sleep(nanoseconds: 100_000_000)

        mockVPNStateRepository.simulateStatusChange(.connected)
        try await waitUntil(timeout: 5.0) { self.mockBridgeAPI.setConnectedStateCalled }

        mockVPNStateRepository.simulateStatusChange(.disconnecting)
        try await Task.sleep(nanoseconds: 100_000_000)

        mockVPNStateRepository.simulateStatusChange(.disconnected)
        try await waitUntil(timeout: 5.0) { self.mockBridgeAPI.lastConnectedState == false }

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

        updateMockLocation()

        // When
        mockBridgeAPI.simulateApiAvailable(true)

        try await waitUntil(timeout: 10.0) { self.repository.isReady }
        // Then — checkAndEmitApiAvailability runs synchronously inside the
        // callback, so isReady is updated by the time simulate returns.
        XCTAssertTrue(repository.isReady, "Should be ready after API becomes available")
    }
}

extension BridgeApiRepositoryTests {
    // MARK: - Helpers

    /// Polls a condition at 10ms intervals until it becomes true or the timeout
    /// elapses. Replaces fixed `Task.sleep` waits that are too short on loaded
    /// CI runners — the poll resolves as soon as the async side-effect lands,
    /// so it's both faster on idle machines and safer under load.
    func waitUntil(
        timeout: TimeInterval = 5.0,
        condition: @escaping () -> Bool
    ) async throws {
        let deadline = Date().addingTimeInterval(timeout)
        while !condition(), Date() < deadline {
            try await Task.sleep(nanoseconds: 10_000_000) // 10ms
        }
        XCTAssertTrue(condition(), "Condition was not met within \(timeout)s")
    }

    func updateMockLocation() {
        let server = ServerMachineModel(
            id: 1,
            hostname: "pro-location-001.windscribe.com",
            ip: "192.0.2.1",
            ip2: "192.0.2.2",
            ip3: "192.0.2.3",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 10,
            sclass: 1
        )

        var datacenter = DatacenterModel(
            id: 101,
            city: "Toronto",
            nick: "Pro",
            iata: "YYZ",
            status: 1,
            gps: "43.6532,-79.3832",
            tz: "America/Toronto",
            p2p: 1,
            isPremium: 1,
            wgPubkey: "test-wg-key",
            wgEndpoint: "pro-location.windscribe.com:443",
            ovpnX509: "test-x509",
            linkSpeed: 1000
        )
        datacenter.locationId = 1
        datacenter.servers = [server]

        let location = LocationModel(
            id: 1,
            name: "Canada",
            countryCode: "CA",
            shortName: "CA",
            sortOrder: 1,
            continent: "North America",
            datacenters: [datacenter]
        )

        mockLocationsManager.mockConnectionTargetType = .server
        mockLocationsManager.mockLocation = (location, datacenter)
    }
}
