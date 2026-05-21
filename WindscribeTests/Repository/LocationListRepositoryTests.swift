//
//  LocationListRepositoryTests.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class LocationListRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: LocationListRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockUserSessionRepository: MockUserSessionRepository!
    var mockLogger: MockLogger!
    var mockPreferences: MockPreferences!
    var mockAdvanceRepository: MockAdvanceRepository!
    var mockAntiCensorshipRepository: MockAntiCensorshipRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockUserSessionRepository = MockUserSessionRepository()
        mockPreferences = MockPreferences()
        mockLogger = MockLogger()
        mockAdvanceRepository = MockAdvanceRepository()
        mockAntiCensorshipRepository = MockAntiCensorshipRepository()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(UserSessionRepository.self) { _ in
            return self.mockUserSessionRepository
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(AdvanceRepository.self) { _ in
            return self.mockAdvanceRepository
        }.inObjectScope(.container)

        mockContainer.register(AntiCensorshipRepository.self) { _ in
            return self.mockAntiCensorshipRepository
        }.inObjectScope(.container)

        // Register LocationListRepository
        mockContainer.register(LocationListRepository.self) { r in
            return LocationListRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                antiCensorshipRepository: r.resolve(AntiCensorshipRepository.self)!,
                preferences: r.resolve(Preferences.self)!,
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(LocationListRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockAPIManager.reset()
        mockAdvanceRepository.reset()
        mockLocalDatabase.clean()
        mockContainer = nil
        repository = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockUserSessionRepository = nil
        mockPreferences = nil
        mockLogger = nil
        mockAdvanceRepository = nil
        super.tearDown()
    }

    // MARK: - Test Cases
    func testGetUpdatedServersSuccess() async throws {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        guard let mockServerList = createMockServerMachineList() else {
            XCTFail("ServerMachineList was nil, should be something")
            return
        }

        guard let mockLocationList = createMockLocationList() else {
            XCTFail("LocationList was nil, should be something")
            return
        }

        mockAPIManager.mockServerList = mockServerList
        mockAPIManager.mockLocationList = mockLocationList

        let expectedServers = mockServerList.servers

        // When
        try await repository.updatedServerList()
        try await repository.updateLocations()

        let savedServerMachines = mockLocalDatabase.getServerMachines()
        let currentServerModels = repository.currentServerModels
        let savedServersModels = savedServerMachines ?? []

        // Then
        XCTAssertEqual(currentServerModels.count, expectedServers.count)
        XCTAssertEqual(savedServersModels.count, currentServerModels.count)
    }

    func testGetUpdatedServersAPIErrorFallbackToLocal() async throws {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        // API will fail
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.datanotfound

        guard let mockServerList = createMockServerMachineList() else {
            XCTFail("ServerMachineList was nil, should be something")
            return
        }

        // But local database has data
        let localServers = mockServerList.servers
        mockLocalDatabase.mockServerMachines = localServers

        // When
        try await repository.updatedServerList()

        // Then
        let currentServerModels = repository.currentServerModels
        XCTAssertEqual(currentServerModels.count, localServers.count)
        XCTAssertEqual(currentServerModels.first?.hostname, localServers.first?.hostname)
    }

    func testGetUpdatedServersAPIErrorNoLocalData() async {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        // API will fail and no local data
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.datanotfound
        mockLocalDatabase.mockServerMachines = nil

        // When/Then
        do {
            try await repository.updatedServerList()
            XCTFail("Should have thrown network error")
        } catch {
            XCTAssertEqual(error as? Errors, Errors.datanotfound)
        }
    }

    func testserverListSubject() async throws {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        guard let mockServerList = createMockServerMachineList() else {
            XCTFail("ServerMachineList was nil, should be something")
            return
        }

        mockAPIManager.mockServerList = mockServerList

        let mockServers = mockServerList.servers

        var receivedServers: [ServerMachineModel] = []
        try await repository.updatedServerList()

        receivedServers = await withCheckedContinuation { continuation in
            repository.serverListSubject
                .sink(receiveValue: { servers in
                    if !servers.isEmpty {
                        continuation.resume(returning: servers)
                    }
                })
                .store(in: &cancellables)
        }

        // Then
        XCTAssertEqual(receivedServers.count, mockServers.count)
        XCTAssertEqual(receivedServers.first?.hostname, mockServers.first?.hostname)
    }

    func testUpdateRegionsWithCustomLocations() async throws {
        // Given
        let mockRegions = createMockExportedRegions()

        guard let mockLocationList = createMockLocationList() else {
            XCTFail("LocationList was nil, should be something")
            return
        }

        // Set up initial locations in the database
        mockAPIManager.mockLocationList = mockLocationList

        // Reload repository to pick up the locations
        try await repository.updateLocations()

        let expectation = expectation(description: "Locations updated with custom regions")

        // Set up the subscription before calling updateRegions to avoid race conditions
        repository.locationListSubject
            .dropFirst() // Skip initial value
            .first() // Only take the first emission to prevent multiple fulfillments
            .sink { locations in
                if !locations.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        repository.updateRegions(with: mockRegions)

        // Then
        wait(for: [expectation], timeout: 2.0)

        let region = mockRegions.first
        let location = repository.currentLocationModels.first { region?.id == $0.id }
        let city = region?.cities.first
        let datacenter = location?.datacenters.first { city?.id == $0.id }
        XCTAssertEqual(location?.name, region?.country)
        XCTAssertEqual(datacenter?.city, city?.name)
        XCTAssertEqual(datacenter?.nick, city?.nickname)
    }

    func testUpdateLocationsOrdersByGeographyInRepository() async throws {
        mockAPIManager.mockLocationList = LocationsListModel(locations: [
            makeLocation(id: 300, name: "Zimbabwe", sortOrder: 30),
            makeLocation(id: 100, name: "Canada", sortOrder: 10),
            makeLocation(id: 200, name: "France", sortOrder: 20),
            makeLocation(id: 40, name: "Albania", sortOrder: 10)
        ])

        try await repository.updateLocations()

        XCTAssertEqual(repository.currentLocationModels.map(\.id), [40, 100, 200, 300])
        XCTAssertEqual(mockLocalDatabase.mockLocations?.map(\.id), [40, 100, 200, 300])
    }

    func testInitialCachedLocationsOrderByGeographyInRepository() {
        mockLocalDatabase.mockLocations = [
            makeLocation(id: 300, name: "Zimbabwe", sortOrder: 30),
            makeLocation(id: 100, name: "Canada", sortOrder: 10),
            makeLocation(id: 200, name: "France", sortOrder: 20),
            makeLocation(id: 40, name: "Albania", sortOrder: 10)
        ]

        repository = LocationListRepositoryImpl(
            apiManager: mockAPIManager,
            localDatabase: mockLocalDatabase,
            logger: mockLogger,
            antiCensorshipRepository: mockAntiCensorshipRepository,
            preferences: mockPreferences
        )

        XCTAssertEqual(repository.currentLocationModels.map(\.id), [40, 100, 200, 300])
    }

    func testFavouritsStartEmpty() async {
        // Then
        XCTAssertEqual(repository.favouriteListSubject.value.count, 0)
    }

    func testSavingFavorite() async {
        // Given
        let mockFavorite = FavouriteModel(id: "1")

        repository.saveFavorite(for: mockFavorite)

        // Then
        XCTAssertEqual(repository.getFavorite(from: mockFavorite.id), mockFavorite)
    }

    func testRemoveFavorite() async {
        // Given
        let mockFavorite1 = FavouriteModel(id: "1")
        let mockFavorite2 = FavouriteModel(id: "2")

        repository.saveFavorite(for: mockFavorite1)
        repository.saveFavorite(for: mockFavorite2)

        XCTAssertEqual(repository.getFavorite(from: mockFavorite1.id), mockFavorite1)
        XCTAssertEqual(repository.getFavorite(from: mockFavorite2.id), mockFavorite2)

        repository.removeFavorite(with: "1")

        // Then
        XCTAssertEqual(repository.getFavorite(from: mockFavorite1.id), nil)
        XCTAssertEqual(repository.getFavorite(from: mockFavorite2.id), mockFavorite2)

        repository.removeFavorite(with: 2)

        // And then
        XCTAssertEqual(repository.getFavorite(from: mockFavorite1.id), nil)
        XCTAssertEqual(repository.getFavorite(from: mockFavorite2.id), nil)
    }

    func testLocationPinned() async {
        // Given
        let mockFavorite1 = FavouriteModel(id: "1", pinnedIp: "1:1:1:1", pinnedNodeHostname: "11:11:11:11")
        let mockFavorite2 = FavouriteModel(id: "2")

        repository.saveFavorite(for: mockFavorite1)
        repository.saveFavorite(for: mockFavorite2)

        // Then
        XCTAssertEqual(repository.getDatacenterPinnedHotname(for: 1), mockFavorite1.pinnedNodeHostname)
        XCTAssertEqual(repository.getDatacenterPinnedHotname(for: 2), nil)
    }
}

// MARK: - Helper Methods
extension LocationListRepositoryTests {

    private func makeLocation(id: Int, name: String, sortOrder: Int) -> LocationModel {
        LocationModel(
            id: id,
            name: name,
            countryCode: String(name.prefix(2)).uppercased(),
            shortName: name,
            sortOrder: sortOrder,
            continent: "",
            datacenters: []
        )
    }

    private func createMockSessionModel() -> SessionModel {
        let session = Session()
        session.userId = "test-user-id"
        session.username = "testuser"
        session.sessionAuthHash = "test-auth-hash"
        return session.getModel()
    }

    private func createMockLocationList() -> LocationsListModel? {
        guard let url = Bundle(for: type(of: self)).url(forResource: "LocationList", withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(LocationsListModel.self, from: data)
        } catch {
            return nil
        }
    }


    private func createMockServerMachineList() -> ServerMachinesListModel? {
        guard let url = Bundle(for: type(of: self)).url(forResource: "ServerMachineList", withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(ServerMachinesListModel.self, from: data)
        } catch _ {
            return nil
        }
    }

    private func createMockExportedRegions() -> [ExportedRegion] {
        let city1 = ExportedCity(id: 276, name: "Custom Chicago", nickname: "Res")
        let city2 = ExportedCity(id: 156, name: "Custom Atlanta", nickname: "Peachtree")

        let region = ExportedRegion(id: 65, country: "Custom US Central", cities: [city1, city2])

        return [region]
    }
}
