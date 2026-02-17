//
//  LatencyRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-02-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class LatencyRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: LatencyRepository!
    var mockPingManager: MockLocalPingManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockVPNStateRepository: MockVPNStateRepository!
    var mockLogger: MockLogger!
    var mockLocationsManager: MockLocationsManager!
    var mockPreferences: MockPreferences!
    var mockAdvanceRepository: MockAdvanceRepository!
    var mockServerRepository: MockServerRepository!
    var mockUserSessionRepository: MockUserSessionRepository!
    var mockStaticIpRepository: MockStaticIpRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockPingManager = MockLocalPingManager()
        mockLocalDatabase = MockLocalDatabase()
        mockVPNStateRepository = MockVPNStateRepository()
        mockLogger = MockLogger()
        mockLocationsManager = MockLocationsManager()
        mockPreferences = MockPreferences()
        mockAdvanceRepository = MockAdvanceRepository()
        mockServerRepository = MockServerRepository()
        mockUserSessionRepository = MockUserSessionRepository()
        mockStaticIpRepository = MockStaticIpRepository()

        // Register mocks
        mockContainer.register(LocalPingManager.self) { _ in
            return self.mockPingManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(VPNStateRepository.self) { _ in
            return self.mockVPNStateRepository
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(LocationsManager.self) { _ in
            return self.mockLocationsManager
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        mockContainer.register(AdvanceRepository.self) { _ in
            return self.mockAdvanceRepository
        }.inObjectScope(.container)

        mockContainer.register(ServerRepository.self) { _ in
            return self.mockServerRepository
        }.inObjectScope(.container)

        mockContainer.register(UserSessionRepository.self) { _ in
            return self.mockUserSessionRepository
        }.inObjectScope(.container)

        mockContainer.register(StaticIpRepository.self) { _ in
            return self.mockStaticIpRepository
        }.inObjectScope(.container)

        // Register LatencyRepository
        mockContainer.register(LatencyRepository.self) { r in
            return LatencyRepositoryImpl(
                pingManager: r.resolve(LocalPingManager.self)!,
                database: r.resolve(LocalDatabase.self)!,
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                logger: r.resolve(FileLogger.self)!,
                locationsManager: r.resolve(LocationsManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                advanceRepository: r.resolve(AdvanceRepository.self)!,
                serverRepository: r.resolve(ServerRepository.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                staticIpRepository: r.resolve(StaticIpRepository.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(LatencyRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockPingManager.reset()
        mockServerRepository.reset()
        mockStaticIpRepository.reset()
        mockAdvanceRepository.reset()
        mockLocationsManager.reset()
        mockLocalDatabase.clean()
        mockContainer = nil
        repository = nil
        mockPingManager = nil
        mockLocalDatabase = nil
        mockVPNStateRepository = nil
        mockLogger = nil
        mockLocationsManager = nil
        mockPreferences = nil
        mockAdvanceRepository = nil
        mockServerRepository = nil
        mockUserSessionRepository = nil
        mockStaticIpRepository = nil
        super.tearDown()
    }

    // MARK: GetPingData Tests

    func testGetPingDataWithExistingIP() {
        let pingData1 = PingData(ip: "1.2.3.4", latency: 50)
        let pingData2 = PingData(ip: "5.6.7.8", latency: 100)
        mockLocalDatabase.addPingData(pingData: pingData1)
        mockLocalDatabase.addPingData(pingData: pingData2)

        repository.refreshBestLocation()

        let result = repository.getPingData(ip: "1.2.3.4")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.ip, "1.2.3.4")
        XCTAssertEqual(result?.latency, 50)
    }

    func testGetPingDataWithNonExistingIP() {
        let pingData = PingData(ip: "1.2.3.4", latency: 50)
        mockLocalDatabase.addPingData(pingData: pingData)

        repository.refreshBestLocation()

        let result = repository.getPingData(ip: "9.9.9.9")

        XCTAssertNil(result)
    }

    // MARK: LoadLatency Tests

    func testLoadLatencyWhenVPNConnected() async throws {
        let mockServers = createMockServerModels()
        mockServerRepository.mockServers = mockServers
        mockServerRepository.currentServerModels = mockServers
        mockVPNStateRepository.mockStatus = .connected

        try await repository.loadLatency()

        XCTAssertFalse(mockPingManager.pingCalled, "Ping should not be called when VPN is connected")
    }

    func testLoadLatencyWithEmptyServerList() async throws {
        mockServerRepository.mockServers = []
        mockServerRepository.currentServerModels = []
        mockVPNStateRepository.mockStatus = .disconnected

        try await repository.loadLatency()

        XCTAssertFalse(mockPingManager.pingCalled, "Ping should not be called with empty server list")
    }

    // MARK: LoadStaticIpLatency Tests

    func testLoadStaticIpLatency() async {
        let mockStaticIPs = createMockStaticIPs()
        mockStaticIpRepository.staticIPs = mockStaticIPs
        mockPingManager.mockPingResult = (30, true)

        await repository.loadStaticIpLatency()

        try? await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertTrue(mockPingManager.pingCalled, "Should ping static IPs")
        XCTAssertGreaterThan(mockPingManager.pingCount, 0, "Should have pinged at least one static IP")
    }

    func testLoadStaticIpLatencyWithEmptyList() async {
        mockStaticIpRepository.staticIPs = []

        await repository.loadStaticIpLatency()

        XCTAssertFalse(mockPingManager.pingCalled, "Should not ping with empty static IP list")
    }

    // MARK: PickBestLocation Tests

    func testPickBestLocationWithPingData() {
        let mockServers = createMockServerModels()
        mockServerRepository.mockServers = mockServers
        mockServerRepository.currentServerModels = mockServers
        mockUserSessionRepository.sessionModel = createMockSession(isPremium: true)

        let pingData1 = PingData(ip: "1.2.3.4", latency: 100)
        let pingData2 = PingData(ip: "5.6.7.8", latency: 50)
        mockLocalDatabase.addPingData(pingData: pingData1)
        mockLocalDatabase.addPingData(pingData: pingData2)

        let pingDataModels = [
            PingDataModel(from: pingData1),
            PingDataModel(from: pingData2)
        ]

        repository.pickBestLocation(pingData: pingDataModels)

        XCTAssertTrue(mockLocationsManager.saveBestLocationCalled, "Should save best location")
        XCTAssertNotNil(mockLocationsManager.lastSavedBestLocationID, "Should have saved a location ID")
    }

    func testPickBestLocationFreeUser() {
        let mockServers = createMockServerModelsWithPremium()
        mockServerRepository.mockServers = mockServers
        mockServerRepository.currentServerModels = mockServers
        mockUserSessionRepository.sessionModel = createMockSession(isPremium: false)

        let pingDataFree = PingData(ip: "1.2.3.4", latency: 100) // Free location
        let pingDataPremium = PingData(ip: "9.9.9.9", latency: 50) // Premium location (better latency)
        mockLocalDatabase.addPingData(pingData: pingDataFree)
        mockLocalDatabase.addPingData(pingData: pingDataPremium)

        let pingDataModels = [
            PingDataModel(from: pingDataFree),
            PingDataModel(from: pingDataPremium)
        ]

        repository.pickBestLocation(pingData: pingDataModels)

        XCTAssertTrue(mockLocationsManager.saveBestLocationCalled, "Should save best location")
    }

    func testPickBestLocationByRegion() {
        let mockServers = createMockServerModelsWithRegions()
        mockServerRepository.mockServers = mockServers
        mockServerRepository.currentServerModels = mockServers
        mockUserSessionRepository.sessionModel = createMockSession(isPremium: true)

        repository.pickBestLocation()

        let expectation = expectation(description: "Wait for async location selection")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1.0)

        XCTAssertTrue(mockLocationsManager.saveBestLocationCalled, "Should save best location")
    }

    // MARK: RefreshBestLocation Tests

    func testRefreshBestLocationShouldLoadFromDatabase() {
        let pingData = PingData(ip: "1.2.3.4", latency: 50)
        mockLocalDatabase.addPingData(pingData: pingData)

        repository.refreshBestLocation()

        let latencyValue = repository.latency.value
        XCTAssertGreaterThan(latencyValue.count, 0, "Should have loaded latency from database")
    }


    // MARK: CheckLocationsValidity Tests

    func testCheckLocationsValidityWhenDisconnected() async {
        let mockServers = createMockServerModels()
        mockServerRepository.mockServers = mockServers
        mockServerRepository.currentServerModels = mockServers
        mockVPNStateRepository.mockStatus = .disconnected

        try? await Task.sleep(nanoseconds: 1_100_000_000)

        await repository.checkLocationsValidity()

        XCTAssertTrue(mockPingManager.pingCalled, "Should attempt to load latency when disconnected")
        XCTAssertGreaterThan(mockPingManager.pingCount, 0, "Should have pinged at least one server")
    }

    func testCheckLocationsValidityWhenConnected() async {
        mockVPNStateRepository.mockStatus = .connected

        await repository.checkLocationsValidity()

        XCTAssertFalse(mockPingManager.pingCalled, "Should not ping when VPN is connected")
    }

    // MARK: Latency Subject Tests

    func testLatencySubject_shouldEmitUpdates() {
        let expectation = expectation(description: "Latency subject emits")
        var receivedPingData: [PingDataModel] = []

        repository.latency
            .dropFirst()
            .sink { pingData in
                receivedPingData = pingData
                expectation.fulfill()
            }
            .store(in: &cancellables)

        let pingData = PingData(ip: "1.2.3.4", latency: 50)
        mockLocalDatabase.addPingData(pingData: pingData)
        repository.refreshBestLocation()

        waitForExpectations(timeout: 1.0)
        XCTAssertGreaterThan(receivedPingData.count, 0, "Should have received ping data")
    }

    // MARK: Helper Methods

    private func createMockSession(isPremium: Bool) -> SessionModel {
        let session = Session()
        session.userId = "test-user-id"
        session.username = "testuser"
        session.isPremium = isPremium
        return session.getModel()
    }

    private func createMockServerModels() -> [ServerModel] {
        let node1 = NodeModel(
            ip1: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            hostname: "us-east.windscribe.com",
            dnsHostname: "us-east.windscribe.com",
            forceDisconnect: false,
            weight: 100
        )

        let group1 = GroupModel(
            id: 1,
            countryCode: "US",
            city: "New York",
            nick: "Big Apple",
            premiumOnly: false,
            nodes: [node1],
            bestNode: node1,
            bestNodeHostname: "us-east.windscribe.com",
            wgPublicKey: "test-key",
            ovpnX509: "test-cert",
            pingIp: "1.2.3.4",
            linkSpeed: "1000",
            health: 100,
            pingHost: "us-east.windscribe.com",
            wasEdited: false,
            timezone: "America/New_York"
        )

        let node2 = NodeModel(
            ip1: "5.6.7.8",
            ip2: "5.6.7.9",
            ip3: "5.6.7.10",
            hostname: "uk-london.windscribe.com",
            dnsHostname: "uk-london.windscribe.com",
            forceDisconnect: false,
            weight: 100
        )

        let group2 = GroupModel(
            id: 2,
            countryCode: "GB",
            city: "London",
            nick: "Big Ben",
            premiumOnly: false,
            nodes: [node2],
            bestNode: node2,
            bestNodeHostname: "uk-london.windscribe.com",
            wgPublicKey: "test-key",
            ovpnX509: "test-cert",
            pingIp: "5.6.7.8",
            linkSpeed: "1000",
            health: 100,
            pingHost: "uk-london.windscribe.com",
            wasEdited: false,
            timezone: "Europe/London"
        )

        let server1 = ServerModel(
            id: 1,
            name: "US East",
            countryCode: "US",
            status: true,
            premiumOnly: false,
            dnsHostname: "us.windscribe.com",
            groups: [group1],
            locType: "datacenter",
            p2p: false,
            wasEdited: false,
            timezone: "America/New_York"
        )

        let server2 = ServerModel(
            id: 2,
            name: "UK London",
            countryCode: "GB",
            status: true,
            premiumOnly: false,
            dnsHostname: "uk.windscribe.com",
            groups: [group2],
            locType: "datacenter",
            p2p: false,
            wasEdited: false,
            timezone: "Europe/London"
        )

        return [server1, server2]
    }

    private func createMockServerModelsWithPremium() -> [ServerModel] {
        let nodeFree = NodeModel(
            ip1: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            hostname: "us-free.windscribe.com",
            dnsHostname: "us-free.windscribe.com",
            forceDisconnect: false,
            weight: 100
        )

        let groupFree = GroupModel(
            id: 1,
            countryCode: "US",
            city: "New York",
            nick: "Free",
            premiumOnly: false,
            nodes: [nodeFree],
            bestNode: nodeFree,
            bestNodeHostname: "us-free.windscribe.com",
            wgPublicKey: "test-key",
            ovpnX509: "test-cert",
            pingIp: "1.2.3.4",
            linkSpeed: "1000",
            health: 100,
            pingHost: "us-free.windscribe.com",
            wasEdited: false,
            timezone: "America/New_York"
        )

        let nodePremium = NodeModel(
            ip1: "9.9.9.9",
            ip2: "9.9.9.10",
            ip3: "9.9.9.11",
            hostname: "us-premium.windscribe.com",
            dnsHostname: "us-premium.windscribe.com",
            forceDisconnect: false,
            weight: 100
        )

        let groupPremium = GroupModel(
            id: 2,
            countryCode: "US",
            city: "Los Angeles",
            nick: "Premium",
            premiumOnly: true,
            nodes: [nodePremium],
            bestNode: nodePremium,
            bestNodeHostname: "us-premium.windscribe.com",
            wgPublicKey: "test-key",
            ovpnX509: "test-cert",
            pingIp: "9.9.9.9",
            linkSpeed: "10000",
            health: 100,
            pingHost: "us-premium.windscribe.com",
            wasEdited: false,
            timezone: "America/Los_Angeles"
        )

        let serverFree = ServerModel(
            id: 1,
            name: "US Free",
            countryCode: "US",
            status: true,
            premiumOnly: false,
            dnsHostname: "us.windscribe.com",
            groups: [groupFree],
            locType: "datacenter",
            p2p: false,
            wasEdited: false,
            timezone: "America/New_York"
        )

        let serverPremium = ServerModel(
            id: 2,
            name: "US Premium",
            countryCode: "US",
            status: true,
            premiumOnly: false,
            dnsHostname: "us-premium.windscribe.com",
            groups: [groupPremium],
            locType: "datacenter",
            p2p: false,
            wasEdited: false,
            timezone: "America/Los_Angeles"
        )

        return [serverFree, serverPremium]
    }

    private func createMockServerModelsWithRegions() -> [ServerModel] {
        var countryCode = "US"
        if #available(iOS 16, tvOS 17, *) {
            countryCode = Locale.current.region?.identifier ?? countryCode
        }
        let node = NodeModel(
            ip1: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            hostname: "us-east.windscribe.com",
            dnsHostname: "us-east.windscribe.com",
            forceDisconnect: false,
            weight: 100
        )

        let group = GroupModel(
            id: 1,
            countryCode: countryCode,
            city: "New York",
            nick: "Big Apple",
            premiumOnly: false,
            nodes: [node],
            bestNode: node,
            bestNodeHostname: "us-east.windscribe.com",
            wgPublicKey: "test-key",
            ovpnX509: "test-cert",
            pingIp: "1.2.3.4",
            linkSpeed: "1000",
            health: 100,
            pingHost: "us-east.windscribe.com",
            wasEdited: false,
            timezone: "America/New_York"
        )

        let server = ServerModel(
            id: 1,
            name: "US East",
            countryCode: countryCode,
            status: true,
            premiumOnly: false,
            dnsHostname: "us.windscribe.com",
            groups: [group],
            locType: "datacenter",
            p2p: false,
            wasEdited: false,
            timezone: "America/New_York"
        )

        return [server]
    }

    private func createMockStaticIPs() -> [StaticIPModel] {
        var countryCode = "US"
        if #available(iOS 16, tvOS 17, *) {
            countryCode = Locale.current.region?.identifier ?? countryCode
        }

        let staticIP = StaticIP()
        staticIP.id = 1
        staticIP.staticIP = "10.10.10.10"
        staticIP.name = "\(countryCode) Static"
        staticIP.countryCode = countryCode
        staticIP.cityName = "New York"
        staticIP.deviceName = "My Device"
        staticIP.connectIP = "static-us.windscribe.com"
        staticIP.pingHost = "static-us.windscribe.com"
        staticIP.isActive = true
        staticIP.type = "datacenter"
        staticIP.wgPublicKey = "test-wg-key"
        staticIP.wgIp = "10.64.1.1"
        staticIP.ovpnX509 = "test-x509"

        let node = StaticIPNode()
        node.ip = "10.10.10.10"
        node.ip2 = "10.10.10.11"
        node.ip3 = "10.10.10.12"
        node.hostname = "static-us.windscribe.com"
        node.weight = 100
        staticIP.setStaticIPNodes(object: node)

        return [staticIP.getModel()]
    }
}
