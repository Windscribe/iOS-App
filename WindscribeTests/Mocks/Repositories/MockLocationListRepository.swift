//
//  MockLocationListRepository.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-03-16.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockLocationListRepository: LocationListRepository {

    var locationListSubject = CurrentValueSubject<[LocationModel], Never>([])
    var datacenterListSubject = CurrentValueSubject<[DatacenterModel], Never>([])
    var serverListSubject = CurrentValueSubject<[ServerMachineModel], Never>([])
    var favouriteListSubject = CurrentValueSubject<[FavouriteModel], Never>([])
    var updateInventoryCalled = false
    var lastInventory: ServerInventoryModel?

    var currentLocationModels: [LocationModel] {
        locationListSubject.value
    }

    var currentDatacenterModels: [DatacenterModel] {
        datacenterListSubject.value
    }

    var currentServerModels: [ServerMachineModel] {
        serverListSubject.value
    }

    var currentFavouriteModels: [FavouriteModel] {
        favouriteListSubject.value
    }

    var shouldThrowError = false
    var customError: Error?

    private var favourites: [FavouriteModel] = []

    func updateLocations() async throws {
        if shouldThrowError {
            throw customError ?? NSError(domain: "MockError", code: -1)
        }
    }

    func updatedServerList() async throws {
        if shouldThrowError {
            throw customError ?? NSError(domain: "MockError", code: -1)
        }
    }

    func updateAll() async throws {
        try await updatedServerList()
        try await updateLocations()
    }

    func updateAllIfEmpty() async throws {
        if shouldThrowError {
            throw customError ?? NSError(domain: "MockError", code: -1)
        }
    }


    func updateInventory(with inventory: ServerInventoryModel) {
        updateInventoryCalled = true
        lastInventory = inventory
    }

    func updateRegions(with regions: [ExportedRegion]) {
        // Mock implementation
    }

    func getLocation(by id: Int) -> LocationModel? {
        currentLocationModels.first { $0.id == id }
    }

    func getDatacenter(by id: Int) -> DatacenterModel? {
        currentDatacenterModels.first { $0.id == id }
    }

    func getDatacenters(for locationId: Int) -> [DatacenterModel] {
        currentDatacenterModels.filter { $0.locationId == locationId }
    }

    func getServers(for datacenterId: Int) -> [ServerMachineModel] {
        currentServerModels.filter { $0.datacenterId == datacenterId }
    }

    func getRandomServer(for datacenterId: Int) -> ServerMachineModel? {
        getServers(for: datacenterId).randomElement()
    }

    func getFavorite(from locationId: String) -> FavouriteModel? {
        favourites.first { $0.id == locationId }
    }

    func removeFavorite(with datacenterId: String) {
        favourites.removeAll { $0.id == datacenterId }
        favouriteListSubject.send(favourites)
    }

    func removeFavorite(with datacenterId: Int) {
        removeFavorite(with: "\(datacenterId)")
    }

    func saveFavorite(for favourite: FavouriteModel) {
        if !favourites.contains(where: { $0.id == favourite.id }) {
            favourites.append(favourite)
            favouriteListSubject.send(favourites)
        }
    }

    func getDatacenterPinnedHotname(for datacenterId: Int) -> String? {
        favourites.first { $0.id == "\(datacenterId)" }?.pinnedNodeHostname
    }

    func saveLastConnectedHost(for hostName: String, with locationId: Int) {
        // Mock implementation
    }

    func reset() {
        locationListSubject.send([])
        datacenterListSubject.send([])
        serverListSubject.send([])
        favouriteListSubject.send([])
        favourites = []
        shouldThrowError = false
        customError = nil
        updateInventoryCalled = false
        lastInventory = nil
    }
}
