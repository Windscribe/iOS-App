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
    var mockLocationListRepository: MockLocationListRepository!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()

        mockLocationsManager = MockLocationsManager()
        mockUserSessionRepository = MockUserSessionRepository()
        mockConnectivity = MockConnectivityManager()
        mockVPNStateRepository = MockVPNStateRepository()
        mockLocationListRepository = MockLocationListRepository()
        cancellables = Set<AnyCancellable>()

        viewModel = FavouriteListViewModel(
            logger: MockLogger(),
            vpnStateRepository: mockVPNStateRepository,
            connectivity: mockConnectivity,
            userSessionRepository: mockUserSessionRepository,
            locationsManager: mockLocationsManager,
            protocolManager: MockProtocolManager(),
            locationListRepository: mockLocationListRepository
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
        mockLocationListRepository = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: Maintenance Check Tests
    //
    // `FavouriteListViewModel.setSelectedFav` was simplified in commit
    // 06b1346f ("Fix status of locations, check under mantainace") so that
    // the maintenance popup fires for one and only one condition:
    // `favourite.statusValue == .underMantainance`. The earlier
    // location-lookup / no-servers / premium special cases were intentionally
    // removed; tests below mirror that contract.
    //
    // `DatacenterModel.statusValue` returns `.underMantainance` when
    // `status == 2 && servers.isEmpty` — so that's how we provoke a
    // maintenance datacenter in fixtures.

    func testUnderMaintenanceDatacenterShowsMaintenancePopup() {
        // Given — datacenter with status=2 and no servers maps to
        // statusValue == .underMantainance.
        let (location, datacenter) = createMockLocationWithDatacenter(
            locationId: 1,
            locationName: "Maintenance Location",
            datacenterId: 123,
            city: "New York",
            status: 2,
            hasServers: false
        )
        var maintenanceTriggered = false

        mockLocationListRepository.locationListSubject.send([location])
        mockLocationListRepository.datacenterListSubject.send([datacenter])

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        // When
        viewModel.setSelectedFav(favourite: datacenter)

        // Then
        XCTAssertTrue(
            maintenanceTriggered,
            "Maintenance popup should be triggered for an under-maintenance datacenter"
        )
    }

    func testAvailableDatacenterDoesNotShowMaintenancePopup() {
        // Given — datacenter with status=1 and a server maps to
        // statusValue == .available.
        let (location, datacenter) = createMockLocationWithDatacenter(
            locationId: 1,
            locationName: "Available Location",
            datacenterId: 123,
            city: "New York",
            status: 1,
            hasServers: true
        )
        var maintenanceTriggered = false

        mockLocationListRepository.locationListSubject.send([location])
        mockLocationListRepository.datacenterListSubject.send([datacenter])

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        // When
        viewModel.setSelectedFav(favourite: datacenter)

        // Then
        XCTAssertFalse(
            maintenanceTriggered,
            "Maintenance popup must NOT fire for an available datacenter"
        )
    }

    func testProDatacenterDoesNotShowMaintenancePopup() {
        // Given — datacenter with status=1 and no servers maps to
        // statusValue == .isPro (not .underMantainance), so no popup.
        let (location, datacenter) = createMockLocationWithDatacenter(
            locationId: 1,
            locationName: "Pro Location",
            datacenterId: 456,
            city: "Tokyo",
            status: 1,
            isPremium: 1,
            hasServers: false
        )
        var maintenanceTriggered = false

        mockLocationListRepository.locationListSubject.send([location])
        mockLocationListRepository.datacenterListSubject.send([datacenter])

        viewModel.showMaintenanceLocationTrigger
            .sink { _ in maintenanceTriggered = true }
            .store(in: &cancellables)

        // When
        viewModel.setSelectedFav(favourite: datacenter)

        // Then
        XCTAssertFalse(
            maintenanceTriggered,
            "Maintenance popup must NOT fire for a pro-required datacenter — that flow uses showUpgradeTrigger"
        )
    }

    // MARK: Helper Methods

    private func createMockLocation(id: Int, name: String, countryCode: String = "US", status: Int = 1, premiumOnly: Int = 0) -> LocationModel {
        return LocationModel(
            id: id,
            name: name,
            countryCode: countryCode,
            shortName: countryCode,
            sortOrder: 1,
            continent: "North America",
            datacenters: []
        )
    }

    private func createMockDatacenter(
        id: Int,
        city: String,
        nick: String = "Test Nick",
        isPremium: Int = 0,
        status: Int = 1,
        servers: [ServerMachineModel] = []
    ) -> DatacenterModel {
        var datacenter = DatacenterModel(
            id: id,
            city: city,
            nick: nick,
            iata: "TST",
            status: status,
            gps: "0.0,0.0",
            tz: "UTC",
            p2p: 1,
            isPremium: isPremium,
            wgPubkey: "test-wg-key",
            wgEndpoint: "test.windscribe.com:443",
            ovpnX509: "test-cert",
            linkSpeed: 1000
        )
        // Honor the caller's servers argument verbatim. The earlier helper
        // silently replaced an empty list with a default mock, which made it
        // impossible to provoke `statusValue == .underMantainance`
        // (status=2 && servers.isEmpty).
        datacenter.servers = servers
        return datacenter
    }

    private func createMockServerMachine(
        id: Int = 1,
        hostname: String = "test-node.windscribe.com",
        ip: String = "1.2.3.4",
        datacenterId: Int
    ) -> ServerMachineModel {
        return ServerMachineModel(
            id: id,
            hostname: hostname,
            ip: ip,
            ip2: "1.2.3.5",
            ip3: "1.2.3.6",
            ipv6: 0,
            datacenterId: datacenterId,
            weight: 100,
            netLoad: 50,
            sclass: 1
        )
    }

    private func createMockLocationWithDatacenter(
        locationId: Int,
        locationName: String,
        datacenterId: Int,
        city: String,
        status: Int = 1,
        isPremium: Int = 0,
        hasServers: Bool = true
    ) -> (location: LocationModel, datacenter: DatacenterModel) {
        let servers = hasServers ? [createMockServerMachine(datacenterId: datacenterId)] : []
        var datacenter = createMockDatacenter(
            id: datacenterId,
            city: city,
            isPremium: isPremium,
            status: status,
            servers: servers
        )
        datacenter.locationId = locationId

        let location = LocationModel(
            id: locationId,
            name: locationName,
            countryCode: "US",
            shortName: "US",
            sortOrder: 1,
            continent: "North America",
            datacenters: [datacenter]
        )

        return (location, datacenter)
    }
}
