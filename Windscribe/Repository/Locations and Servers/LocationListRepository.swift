//
//  LocationListRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol LocationListRepository: Sendable {
    var locationListSubject: CurrentValueSubject<[LocationModel], Never> { get }
    var datacenterListSubject: CurrentValueSubject<[DatacenterModel], Never> { get }
    var serverListSubject: CurrentValueSubject<[ServerMachineModel], Never> { get }
    var favouriteListSubject: CurrentValueSubject<[FavouriteModel], Never> { get }

    var currentLocationModels: [LocationModel] { get }
    var currentDatacenterModels: [DatacenterModel] { get }
    var currentServerModels: [ServerMachineModel] { get }
    var currentFavouriteModels: [FavouriteModel] { get }

    func updateLocations() async throws
    func updatedServerList() async throws
    func updateInventory(with inventory: ServerInventoryModel)
    func updateAll() async throws

    func updateRegions(with regions: [ExportedRegion])

    func getLocation(by id: Int) -> LocationModel?
    func getDatacenter(by id: Int) -> DatacenterModel?
    func getDatacenters(for locationId: Int) -> [DatacenterModel]

    func getServers(for datacenterId: Int) -> [ServerMachineModel]
    func getRandomServer(for datacenterId: Int) -> ServerMachineModel?

    func getFavorite(from locationId: String) -> FavouriteModel?
    func removeFavorite(with datacenterId: String)
    func removeFavorite(with datacenterId: Int)
    func saveFavorite(for favourite: FavouriteModel)

    func getDatacenterPinnedHotname(for datacenterId: Int) -> String?
    func saveLastConnectedHost(for hostName: String, with locationId: Int)

    func updateAllIfEmpty() async throws
}

class LocationListRepositoryImpl: LocationListRepository {
    var locationListSubject = CurrentValueSubject<[LocationModel], Never>([])
    var datacenterListSubject = CurrentValueSubject<[DatacenterModel], Never>([])
    var serverListSubject = CurrentValueSubject<[ServerMachineModel], Never>([])
    var favouriteListSubject = CurrentValueSubject<[FavouriteModel], Never>([])

    var hasPinnedNodeMismatch = false

    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger
    private let antiCensorshipRepository: AntiCensorshipRepository
    private let preferences: Preferences

    private var cancellables = Set<AnyCancellable>()

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

    init(apiManager: APIManager,
         localDatabase: LocalDatabase,
         logger: FileLogger,
         antiCensorshipRepository: AntiCensorshipRepository,
         preferences: Preferences) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        self.preferences = preferences
        self.antiCensorshipRepository = antiCensorshipRepository

        serverListSubject
            .sink { [weak self] serverList in
                guard let self = self else { return }

                let datacenterList = self.currentDatacenterModels
                guard !datacenterList.isEmpty else { return }

                self.populateDatacenters(from: datacenterList, with: serverList)
            }
            .store(in: &cancellables)

        self.antiCensorshipRepository.selecteRoutingTypeSubject
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    try? await self?.updatedServerList()
                }
            }
            .store(in: &cancellables)

        loadInitialServers()
        loadInitialLocations()
        loadInitialFavourites()
    }

    private func populateDatacenters(from datacenterList: [DatacenterModel],
                                     with serverList: [ServerMachineModel]) {

        var serversByDatacenter: [Int: [ServerMachineModel]] = [:]
        serverList.forEach { server in
            serversByDatacenter[server.datacenterId, default: []].append(server)
        }

        let updatedDatacenterList = datacenterList.map { datacenter in
            var updatedDatacenter = datacenter
            updatedDatacenter.servers = serversByDatacenter[datacenter.id] ?? []
            return updatedDatacenter
        }

        datacenterListSubject.send(updatedDatacenterList)
        populateLocations(from: updatedDatacenterList)
    }

    private func populateLocations(from datacenterList: [DatacenterModel]) {
        var datacenterbyLocation: [Int: [DatacenterModel]] = [:]
        datacenterList.forEach { datacenter in
            datacenterbyLocation[datacenter.locationId, default: []].append(datacenter)
        }

        let updatedLocationList = self.currentLocationModels.map { location in
            var updatedLocation = location
            updatedLocation.datacenters = datacenterbyLocation[location.id] ?? []
            return updatedLocation
        }

        self.locationListSubject.send(updatedLocationList)
    }

    private func updateDatacenterList(from locations: [LocationModel]) {
        let allDatacenters = locations.flatMap { $0.datacenters }
        logger.logI("LocationListRepositoryImpl", "Successfully updated \(allDatacenters.count) datacenters")
        populateDatacenters(from: allDatacenters, with: currentServerModels)
    }

    private func loadInitialLocations(skipCustomNames: Bool = false) {
        if let locationObjects = localDatabase.getLocations(), !locationObjects.isEmpty {
            let orderedLocations = sortLocationsByGeography(locationObjects)
            guard skipCustomNames else {
                updateLocationModels(orderedLocations)
                return
            }
            locationListSubject.send(orderedLocations)
            updateDatacenterList(from: orderedLocations)
        } else if let deprecatedList = self.localDatabase.getServers(), !deprecatedList.isEmpty {
            saveLocationList(with: deprecatedList)
        }
    }

    private func loadInitialServers() {
        if let serversObjects = self.localDatabase.getServerMachines() {
            serverListSubject.send(serversObjects)
        }
    }

    private func saveLocationList(with locations: [LocationModel], skipCustomNames: Bool = false) {
        let orderedLocations = sortLocationsByGeography(locations)

        // Persist locations before applying custom names so the disk copy is the canonical shape.
        localDatabase.saveLocations(locations: orderedLocations)

        logger.logI("LocationListRepositoryImpl", "Successfully updated \(orderedLocations.count) locations")

        // Apply custom names (if any) and update subjects
        guard skipCustomNames else {
            updateLocationModels(orderedLocations)
            return
        }
        locationListSubject.send(orderedLocations)
        updateDatacenterList(from: orderedLocations)
    }

    func updateLocations() async throws {
        do {
            let locationsList = try await apiManager.getLocationsList()
            let locations = locationsList.locations
            saveLocationList(with: locations)
        } catch {
            logger.logE("LocationListRepositoryImpl", "Failed to update locations: \(error.localizedDescription)")

            // Try to load from local database as fallback
            if let locationObjects = localDatabase.getLocations() {
                updateLocationModels(sortLocationsByGeography(locationObjects))
                return
            } else {
                throw error
            }
        }
    }

    private func loadInitialFavourites() {
        let favList = self.localDatabase.getFavouriteList()
        favouriteListSubject.send(favList)
    }

    func updatedServerList() async throws {
        do {
            let serverList = try await self.apiManager.getServerMachinesList()
            let servers = serverList.servers
            updateCurrentServers(with: servers, revision: serverList.revision, hasBackup: serverList.hasBakcup)

            logger.logI("LocationListRepositoryImpl", "Successfully updated \(servers.count) server machines")
        } catch {
            logger.logE("LocationListRepositoryImpl", "Failed to update servers machines: \(error.localizedDescription)")

            if let serversObjects = self.localDatabase.getServerMachines() {
                serverListSubject.send(serversObjects)
                return
            } else {
                throw error
            }
        }
    }

    func updateAll() async throws {
        try await updatedServerList()
        try await updateLocations()
    }

    func updateAllIfEmpty() async throws {
        if currentServerModels.isEmpty {
            try await updatedServerList()
        }
        if currentLocationModels.isEmpty {
            try await updateLocations()
        }
    }

    func updateInventory(with inventory: ServerInventoryModel) {
        preferences.saveServerRevision(revision: inventory.revision)

        var currentServers = serverListSubject.value
        inventory.disabled.forEach { disabled in
            currentServers.removeAll(where: {$0.id == disabled.id})
        }
        currentServers.append(contentsOf: inventory.enabled)

        updateCurrentServers(with: currentServers, revision: inventory.revision, hasBackup: inventory.hasBakcup)
    }

    private func updateCurrentServers(with servers: [ServerMachineModel], revision: Int64, hasBackup: Bool) {
        preferences.saveServerRevision(revision: revision)
        serverListSubject.send(servers)
        localDatabase.saveServerMachines(serverMachines: servers)
    }

    func getServers(for datacenterId: Int) -> [ServerMachineModel] {
        getDatacenter(by: datacenterId)?.servers ?? []
    }

    func getRandomServer(for datacenterId: Int) -> ServerMachineModel? {
        getServers(for: datacenterId).randomElement()
    }

    func getLocation(by id: Int) -> LocationModel? {
        currentLocationModels.first { $0.id == id }
    }

    func getDatacenter(by id: Int) -> DatacenterModel? {
        currentDatacenterModels.first { $0.id == id }
    }

    func getDatacenters(for locationId: Int) -> [DatacenterModel] {
        guard let location = getLocation(by: locationId) else {
            return []
        }
        return location.datacenters
    }

    // MARK: - Favorites
    func getFavorite(from locationId: String) -> FavouriteModel? {
        localDatabase.getFavouriteList()
            .first { $0.id == locationId }
    }

    func removeFavorite(with datacenterId: String) {
        var favList = currentFavouriteModels
        favList.removeAll(where: { datacenterId == $0.id })
        favouriteListSubject.send(favList)
        localDatabase.removeFavourite(datacenterId: datacenterId)
    }

    func removeFavorite(with datacenterId: Int) {
        removeFavorite(with: "\(datacenterId)")
    }

    func saveFavorite(for favourite: FavouriteModel) {
        var favList = currentFavouriteModels
        let savedFavourite = favList.first(where: { favourite.id == $0.id })
        if favourite != savedFavourite {
            if savedFavourite != nil {
                favList.removeAll(where: { favourite.id == $0.id })
            }
            favList.append(favourite)
            favouriteListSubject.send(favList)
        }
        localDatabase.saveFavourite(favourite: favourite)
    }

    // MARK: - Pinned Locations
    func saveLastConnectedHost(for hostName: String, with locationId: Int) {
        preferences.saveLastNodeIP(nodeIp: hostName)
        hasPinnedNodeMismatch = false

        if let favorite = getFavorite(from: String(locationId)),
           let pinnedNodeHostname = favorite.pinnedNodeHostname {
            if hostName.areSubdomainsEqual(other: pinnedNodeHostname) {
                if let pinnedIp = favorite.pinnedIp {
                    preferences.saveLastSelectedPinnedIp(with: pinnedIp)
                    return
                }
            } else {
                hasPinnedNodeMismatch = true
            }
        }
        preferences.saveLastSelectedPinnedIp(with: "")
    }

    func getDatacenterPinnedHotname(for datacenterId: Int) -> String? {
        localDatabase.getFavouriteList().first {
            $0.id == String(datacenterId) && $0.pinnedNodeHostname != nil
        }?.pinnedNodeHostname
    }

    // MARK: - Exported Regions

    func updateRegions(with regions: [ExportedRegion]) {
        let locations = currentLocationModels
        guard !locations.isEmpty else { return }
        self.preferences.saveCustomLocationsNames(value: regions)
        self.updateLocationModels(locations)
    }

    private func updateLocationModels(_ locationList: [LocationModel]) {
        logger.logI("LocationListRepository", "Stating merge of local and external servers")
        let regions = preferences.getCustomLocationsNames()
        if regions.isEmpty {
            locationListSubject.send(locationList)
            updateDatacenterList(from: locationList)
            return
        }

        var mergedModels: [LocationModel] = []
        locationList.forEach { location in
            if let region = regions.first(where: { $0.id == location.id }) {
                var mergedDatacenters = [DatacenterModel]()
                location.datacenters.forEach { datacenter in
                    if let city = region.cities.first(where: { $0.id == datacenter.id }) {
                        mergedDatacenters.append(datacenter.getCustomDatacenter(withCity: city.name, andNick: city.nickname))
                    } else {
                        mergedDatacenters.append(datacenter)
                    }
                }
                if location.datacenters.count == mergedDatacenters.count {
                    mergedModels.append(location.getCustomLocation(withName: region.country,
                                                                   andDatacenters: mergedDatacenters))
                } else {
                    mergedModels.append(location.getCustomLocation(withName: region.country,
                                                                   andDatacenters: location.datacenters))
                }
            } else {
                mergedModels.append(location)
            }
        }
        if mergedModels.count == locationList.count {
            logger.logI("ServerRepositoryImpl", "Merge of local and external servers successful")
            locationListSubject.send(mergedModels)
            updateDatacenterList(from: mergedModels)
            return
        }
    }

    private func sortLocationsByGeography(_ locations: [LocationModel]) -> [LocationModel] {
        locations.sorted { location1, location2 in
            if location1.sortOrder != location2.sortOrder {
                return location1.sortOrder < location2.sortOrder
            }

            if location1.name != location2.name {
                return location1.name < location2.name
            }

            return location1.id < location2.id
        }
    }
}
