//
//  FavouriteListViewModelTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-01-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
import Combine
@testable import Windscribe

final class FavouriteListViewModelTests: XCTestCase {
    var viewModel: FavouriteListViewModel!
    var mockLocationsManager: MockLocationsManager!
    var mockUserSessionRepository: MockUserSessionRepository!
    var mockConnectivity: MockConnectivityManager!
    var mockVPNStateRepository: MockVPNStateRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        mockLocationsManager = MockLocationsManager()
        mockUserSessionRepository = MockUserSessionRepository()
        mockConnectivity = MockConnectivityManager()
        mockVPNStateRepository = MockVPNStateRepository()
        cancellables = Set<AnyCancellable>()

        viewModel = FavouriteListViewModel(
            logger: MockLogger(),
            vpnStateRepository: mockVPNStateRepository,
            connectivity: mockConnectivity,
            userSessionRepository: mockUserSessionRepository,
            locationsManager: mockLocationsManager,
            protocolManager: MockProtocolManager()
        )

        mockConnectivity.mockInternetAvailable = true
        mockVPNStateRepository.configurationState = .initial
    }

    override func tearDown() {
        viewModel = nil
        mockLocationsManager = nil
        mockUserSessionRepository = nil
        mockConnectivity = nil
        mockVPNStateRepository = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: Maintenance Check Tests

    func testDisabledServerShowsMaintenancePopup() {
        let disabledServer = createMockServer(id: 1, name: "Test Server", status: false)
        let group = createMockGroup(id: 123, city: "New York")
        var maintenanceTriggered = false

        mockLocationsManager.mockLocation = (disabledServer, group)

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        viewModel.setSelectedFav(favourite: group)

        XCTAssertTrue(maintenanceTriggered)
        XCTAssertTrue(mockLocationsManager.getLocationCalled, "Should check location status")
    }

    func testEnabledServerDoesNotShowMaintenancePopup() {
        let enabledServer = createMockServer(id: 1, name: "Test Server", status: true)
        let group = createMockGroup(id: 123, city: "New York")
        var maintenanceTriggered = false

        mockLocationsManager.mockLocation = (enabledServer, group)

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        viewModel.setSelectedFav(favourite: group)

        XCTAssertFalse(maintenanceTriggered)
        XCTAssertTrue(mockLocationsManager.getLocationCalled, "Should check location status")
    }

    func testLocationNotFoundShowsMaintenancePopup() {
        let group = createMockGroup(id: 999, city: "Unknown City")
        var maintenanceTriggered = false

        mockLocationsManager.mockLocationError = VPNConfigurationErrors.locationNotFound("999")

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        viewModel.setSelectedFav(favourite: group)

        XCTAssertTrue(maintenanceTriggered)
        XCTAssertTrue(mockLocationsManager.getLocationCalled, "Should attempt to get location")
    }

    func testNoNodesAvailableShowsMaintenancePopup() {
        let enabledServer = createMockServer(id: 1, name: "Test Server", status: true)
        let groupWithNoNodes = createMockGroup(id: 123, city: "New York", nodes: [])
        var maintenanceTriggered = false

        mockLocationsManager.mockLocation = (enabledServer, groupWithNoNodes)

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        viewModel.setSelectedFav(favourite: groupWithNoNodes)

        XCTAssertTrue(maintenanceTriggered, "Maintenance popup should be triggered when no nodes available")
    }

    func testPremiumLocationWithNoNodesShowsMaintenanceForPremiumUser() {
        let enabledServer = createMockServer(id: 1, name: "Premium Server", status: true)
        let premiumGroupWithNoNodes = createMockGroup(id: 456, city: "Tokyo", premiumOnly: true, nodes: [])
        var maintenanceTriggered = false

        mockLocationsManager.mockLocation = (enabledServer, premiumGroupWithNoNodes)
        mockUserSessionRepository.setMockSession(userId: "123", isPremium: true)

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        viewModel.setSelectedFav(favourite: premiumGroupWithNoNodes)

        XCTAssertTrue(maintenanceTriggered, "Maintenance popup should be triggered for premium user with no nodes")
    }

    // MARK: Helper Methods

    private func createMockServer(id: Int, name: String, status: Bool) -> ServerModel {
        return ServerModel(
            id: id,
            name: name,
            countryCode: "US",
            status: status,
            premiumOnly: false,
            dnsHostname: "test.windscribe.com",
            groups: [],
            locType: "datacenter",
            p2p: false,
            wasEdited: false,
            timezone: "UTC"
        )
    }

    private func createMockGroup(
        id: Int,
        city: String,
        premiumOnly: Bool = false,
        nodes: [NodeModel] = [createMockNode()]
    ) -> GroupModel {
        return GroupModel(
            id: id,
            countryCode: "US",
            city: city,
            nick: "Test Nick",
            premiumOnly: premiumOnly,
            nodes: nodes,
            bestNode: nodes.first,
            bestNodeHostname: nodes.first?.hostname ?? "",
            wgPublicKey: "test-key",
            ovpnX509: "test-cert",
            pingIp: "1.2.3.4",
            linkSpeed: "1000",
            health: 100,
            pingHost: "test.windscribe.com",
            wasEdited: false,
            timezone: "UTC"
        )
    }

    private static func createMockNode() -> NodeModel {
        return NodeModel(
            ip1: "1.2.3.4",
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            hostname: "test-node.windscribe.com",
            dnsHostname: "test-node.windscribe.com",
            forceDisconnect: false,
            weight: 100
        )
    }
}
