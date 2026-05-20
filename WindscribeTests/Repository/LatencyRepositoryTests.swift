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
    var mockLocationListRepository: MockLocationListRepository!
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
        mockLocationListRepository = MockLocationListRepository()
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

        mockContainer.register(LocationListRepository.self) { _ in
            return self.mockLocationListRepository
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
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                staticIpRepository: r.resolve(StaticIpRepository.self)!,
                locationListRepository: r.resolve(LocationListRepository.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(LatencyRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockPingManager.reset()
        mockLocationListRepository.reset()
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
        mockLocationListRepository = nil
        mockUserSessionRepository = nil
        mockStaticIpRepository = nil
        super.tearDown()
    }

    // MARK: GetPingData Tests

    func testGetPingDataWithExistingIP() {
        let pingData1 = PingDataModel(ip: "1.2.3.4", latency: 50)
        let pingData2 = PingDataModel(ip: "5.6.7.8", latency: 100)
        mockLocalDatabase.addPingData(pingData: pingData1)
        mockLocalDatabase.addPingData(pingData: pingData2)

        repository.refreshBestLocation()

        let result = repository.getPingData(ip: "1.2.3.4")

        XCTAssertNotNil(result)
        XCTAssertEqual(result?.ip, "1.2.3.4")
        XCTAssertEqual(result?.latency, 50)
    }

    func testGetPingDataWithNonExistingIP() {
        let pingData = PingDataModel(ip: "1.2.3.4", latency: 50)
        mockLocalDatabase.addPingData(pingData: pingData)

        repository.refreshBestLocation()

        let result = repository.getPingData(ip: "9.9.9.9")

        XCTAssertNil(result)
    }

    // MARK: LoadLatency Tests

    func testLoadLatencyWhenVPNConnected() async throws {
        let (locations, datacenters, serverMachines) = createMockData()
        mockLocationListRepository.locationListSubject.send(locations)
        mockLocationListRepository.datacenterListSubject.send(datacenters)
        mockLocationListRepository.serverListSubject.send(serverMachines)
        mockVPNStateRepository.mockStatus = .connected

        try await repository.loadLatency()

        XCTAssertFalse(mockPingManager.pingCalled, "Ping should not be called when VPN is connected")
    }

    func testLoadLatencyWithEmptyServerList() async throws {
        mockLocationListRepository.locationListSubject.send([])
        mockLocationListRepository.datacenterListSubject.send([])
        mockLocationListRepository.serverListSubject.send([])
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

        try? await Task.sleep(nanoseconds: 500_000_000)

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
        let (locations, datacenters, serverMachines) = createMockData()
        mockLocationListRepository.locationListSubject.send(locations)
        mockLocationListRepository.datacenterListSubject.send(datacenters)
        mockLocationListRepository.serverListSubject.send(serverMachines)
        mockUserSessionRepository.sessionModel = createMockSession(isPremium: true)

        let pingData1 = PingDataModel(ip: "1.2.3.4", latency: 100)
        let pingData2 = PingDataModel(ip: "5.6.7.8", latency: 50)
        mockLocalDatabase.addPingData(pingData: pingData1)
        mockLocalDatabase.addPingData(pingData: pingData2)

        let pingDataModels = [
            pingData1,
            pingData2
        ]

        repository.pickBestLocation(pingData: pingDataModels)

        XCTAssertTrue(mockLocationsManager.saveBestLocationCalled, "Should save best location")
        XCTAssertNotNil(mockLocationsManager.lastSavedBestLocationId, "Should have saved a location ID")
    }

    func testPickBestLocationFreeUser() {
        let (locations, datacenters, serverMachines) = createMockDataWithPremium()
        mockLocationListRepository.locationListSubject.send(locations)
        mockLocationListRepository.datacenterListSubject.send(datacenters)
        mockLocationListRepository.serverListSubject.send(serverMachines)
        mockUserSessionRepository.sessionModel = createMockSession(isPremium: false)

        let pingDataFree = PingDataModel(ip: "1.2.3.4", latency: 100) // Free location
        let pingDataPremium = PingDataModel(ip: "9.9.9.9", latency: 50) // Premium location (better latency)
        mockLocalDatabase.addPingData(pingData: pingDataFree)
        mockLocalDatabase.addPingData(pingData: pingDataPremium)

        let pingDataModels = [
            pingDataFree,
            pingDataPremium
        ]

        repository.pickBestLocation(pingData: pingDataModels)

        XCTAssertTrue(mockLocationsManager.saveBestLocationCalled, "Should save best location")
    }

    func testPickBestLocationByRegion() {
        let (locations, datacenters, serverMachines) = createMockDataWithRegions()
        mockLocationListRepository.locationListSubject.send(locations)
        mockLocationListRepository.datacenterListSubject.send(datacenters)
        mockLocationListRepository.serverListSubject.send(serverMachines)
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
        let pingData = PingDataModel(ip: "1.2.3.4", latency: 50)
        mockLocalDatabase.addPingData(pingData: pingData)

        repository.refreshBestLocation()

        let latencyValue = repository.latency.value
        XCTAssertGreaterThan(latencyValue.count, 0, "Should have loaded latency from database")
    }


    // MARK: CheckLocationsValidity Tests

    func testCheckLocationsValidityWhenDisconnected() async {
        let (locations, datacenters, serverMachines) = createMockData()
        mockLocationListRepository.locationListSubject.send(locations)
        mockLocationListRepository.datacenterListSubject.send(datacenters)
        mockLocationListRepository.serverListSubject.send(serverMachines)
        mockVPNStateRepository.mockStatus = .disconnected

        try? await Task.sleep(nanoseconds: 2_000_000_000)

        await repository.checkLocationsValidity()

        XCTAssertTrue(mockPingManager.pingCalled, "Should attempt to load latency when disconnected")
        XCTAssertGreaterThan(mockPingManager.pingCount, 0, "Should have pinged at least one server")
    }

    func testCheckLocationsValidityWhenConnected() async {
        let (locations, datacenters, serverMachines) = createMockData()
        mockLocationListRepository.locationListSubject.send(locations)
        mockLocationListRepository.datacenterListSubject.send(datacenters)
        mockLocationListRepository.serverListSubject.send(serverMachines)
        mockUserSessionRepository.sessionModel = createMockSession(isPremium: true)
        mockLocalDatabase.addPingData(pingData: PingDataModel(ip: "1.2.3.4", latency: 50))
        mockVPNStateRepository.mockStatus = .connected

        await repository.checkLocationsValidity()

        XCTAssertFalse(mockPingManager.pingCalled, "Should not ping when VPN is connected")
        XCTAssertFalse(mockLocationsManager.saveBestLocationCalled, "Should not refresh best location when VPN is connected")
    }

    // MARK: Datacenter Ping Server Tests

    func testDatacenterPingServerStaysStableUntilServersChange() {
        var datacenter = DatacenterModel(
            id: 101,
            city: "New York",
            nick: "Big Apple",
            iata: "NYC",
            status: 1,
            gps: "40.7128,-74.0060",
            tz: "America/New_York",
            p2p: 1,
            isPremium: 0,
            wgPubkey: "test-wg-key",
            wgEndpoint: "us-east.windscribe.com:443",
            ovpnX509: "test-x509",
            linkSpeed: 1000
        )
        let firstServer = ServerMachineModel(
            id: 3,
            hostname: "server-3.windscribe.com",
            ip: "3.3.3.3",
            ip2: "",
            ip3: "",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 30,
            sclass: 1
        )
        let secondServer = ServerMachineModel(
            id: 1,
            hostname: "server-1.windscribe.com",
            ip: "1.1.1.1",
            ip2: "",
            ip3: "",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 10,
            sclass: 1
        )
        let thirdServer = ServerMachineModel(
            id: 2,
            hostname: "server-2.windscribe.com",
            ip: "2.2.2.2",
            ip2: "",
            ip3: "",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 20,
            sclass: 1
        )

        datacenter.servers = [firstServer, secondServer, thirdServer]
        let initialPingServer = datacenter.pingServer

        datacenter.servers = [thirdServer, firstServer, secondServer]

        XCTAssertEqual(datacenter.pingServer, initialPingServer)

        datacenter.servers = [thirdServer]

        XCTAssertEqual(datacenter.pingServer, thirdServer)
    }

    func testDatacenterPingServerDoesNotRandomizeWhenServerDetailsChange() {
        let (_, datacenters, serverMachines) = createMockData()
        var datacenter = datacenters[0]
        let originalServer = serverMachines[0]
        let updatedServer = ServerMachineModel(
            id: originalServer.id,
            hostname: originalServer.hostname,
            ip: originalServer.ip,
            ip2: originalServer.ip2,
            ip3: originalServer.ip3,
            ipv6: originalServer.ipv6,
            datacenterId: originalServer.datacenterId,
            weight: originalServer.weight,
            netLoad: 90,
            sclass: originalServer.sclass
        )

        datacenter.servers = [updatedServer]

        XCTAssertEqual(datacenter.pingServer?.id, originalServer.id)
        XCTAssertEqual(datacenter.pingServer?.netLoad, updatedServer.netLoad)
        XCTAssertEqual(datacenter.netLoad, updatedServer.netLoad)
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

        let pingData = PingDataModel(ip: "1.2.3.4", latency: 50)
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

    /// Creates mock Location, Datacenter, and ServerMachine models for testing
    private func createMockData() -> (locations: [LocationModel], datacenters: [DatacenterModel], serverMachines: [ServerMachineModel]) {
        // Create server machines
        let server1 = ServerMachineModel(
            id: 1,
            hostname: "us-east-001.windscribe.com",
            ip: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 50,
            sclass: 1
        )

        let server2 = ServerMachineModel(
            id: 2,
            hostname: "uk-london-001.windscribe.com",
            ip: "5.6.7.8",
            ip2: "5.6.7.9",
            ip3: "5.6.7.10",
            ipv6: 0,
            datacenterId: 102,
            weight: 100,
            netLoad: 60,
            sclass: 1
        )

        // Create datacenters
        var datacenter1 = DatacenterModel(
            id: 101,
            city: "New York",
            nick: "Big Apple",
            iata: "NYC",
            status: 1,
            gps: "40.7128,-74.0060",
            tz: "America/New_York",
            p2p: 1,
            isPremium: 0,
            wgPubkey: "test-wg-key-1",
            wgEndpoint: "us-east.windscribe.com:443",
            ovpnX509: "test-x509-1",
            linkSpeed: 1000
        )
        datacenter1.locationId = 1
        datacenter1.servers = [server1]

        var datacenter2 = DatacenterModel(
            id: 102,
            city: "London",
            nick: "Big Ben",
            iata: "LON",
            status: 1,
            gps: "51.5074,-0.1278",
            tz: "Europe/London",
            p2p: 1,
            isPremium: 0,
            wgPubkey: "test-wg-key-2",
            wgEndpoint: "uk-london.windscribe.com:443",
            ovpnX509: "test-x509-2",
            linkSpeed: 1000
        )
        datacenter2.locationId = 2
        datacenter2.servers = [server2]

        // Create locations
        let location1 = LocationModel(
            id: 1,
            name: "United States",
            countryCode: "US",
            shortName: "US",
            sortOrder: 1,
            continent: "North America",
            datacenters: [datacenter1]
        )

        let location2 = LocationModel(
            id: 2,
            name: "United Kingdom",
            countryCode: "GB",
            shortName: "UK",
            sortOrder: 2,
            continent: "Europe",
            datacenters: [datacenter2]
        )

        return (
            locations: [location1, location2],
            datacenters: [datacenter1, datacenter2],
            serverMachines: [server1, server2]
        )
    }

    /// Creates mock data with premium and free locations
    private func createMockDataWithPremium() -> (locations: [LocationModel], datacenters: [DatacenterModel], serverMachines: [ServerMachineModel]) {
        // Free server
        let serverFree = ServerMachineModel(
            id: 1,
            hostname: "us-free-001.windscribe.com",
            ip: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 70,
            sclass: 1
        )

        // Premium server (better latency in tests)
        let serverPremium = ServerMachineModel(
            id: 2,
            hostname: "us-premium-001.windscribe.com",
            ip: "9.9.9.9",
            ip2: "9.9.9.10",
            ip3: "9.9.9.11",
            ipv6: 0,
            datacenterId: 102,
            weight: 100,
            netLoad: 30,
            sclass: 1
        )

        // Free datacenter
        var datacenterFree = DatacenterModel(
            id: 101,
            city: "New York",
            nick: "Free",
            iata: "NYC",
            status: 1,
            gps: "40.7128,-74.0060",
            tz: "America/New_York",
            p2p: 1,
            isPremium: 0,
            wgPubkey: "test-wg-key-free",
            wgEndpoint: "us-free.windscribe.com:443",
            ovpnX509: "test-x509-free",
            linkSpeed: 1000
        )
        datacenterFree.locationId = 1
        datacenterFree.servers = [serverFree]

        // Premium datacenter
        var datacenterPremium = DatacenterModel(
            id: 102,
            city: "Los Angeles",
            nick: "Premium",
            iata: "LAX",
            status: 1,
            gps: "34.0522,-118.2437",
            tz: "America/Los_Angeles",
            p2p: 1,
            isPremium: 1,
            wgPubkey: "test-wg-key-premium",
            wgEndpoint: "us-premium.windscribe.com:443",
            ovpnX509: "test-x509-premium",
            linkSpeed: 10000
        )
        datacenterPremium.locationId = 1
        datacenterPremium.servers = [serverPremium]

        let location = LocationModel(
            id: 1,
            name: "United States",
            countryCode: "US",
            shortName: "US",
            sortOrder: 1,
            continent: "North America",
            datacenters: [datacenterFree, datacenterPremium]
        )

        return (
            locations: [location],
            datacenters: [datacenterFree, datacenterPremium],
            serverMachines: [serverFree, serverPremium]
        )
    }

    /// Creates mock data with region-based locations
    private func createMockDataWithRegions() -> (locations: [LocationModel], datacenters: [DatacenterModel], serverMachines: [ServerMachineModel]) {
        var countryCode = "US"
        if #available(iOS 16, tvOS 17, *) {
            countryCode = Locale.current.region?.identifier ?? countryCode
        }

        let server = ServerMachineModel(
            id: 1,
            hostname: "us-east-001.windscribe.com",
            ip: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 50,
            sclass: 1
        )

        var datacenter = DatacenterModel(
            id: 101,
            city: "New York",
            nick: "Big Apple",
            iata: "NYC",
            status: 1,
            gps: "40.7128,-74.0060",
            tz: "America/New_York",
            p2p: 1,
            isPremium: 0,
            wgPubkey: "test-wg-key",
            wgEndpoint: "us-east.windscribe.com:443",
            ovpnX509: "test-x509",
            linkSpeed: 1000
        )
        datacenter.locationId = 1
        datacenter.servers = [server]

        let location = LocationModel(
            id: 1,
            name: "User Region Country",
            countryCode: countryCode,
            shortName: countryCode,
            sortOrder: 1,
            continent: "North America",
            datacenters: [datacenter]
        )

        return (
            locations: [location],
            datacenters: [datacenter],
            serverMachines: [server]
        )
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
