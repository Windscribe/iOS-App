//
//  LocationListRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Combine

protocol LocationListRepository {
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

    func getDatacenterPinnedIp(for datacenterId: Int) -> String?
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
    private let preferences: Preferences

    private var cancellables = Set<AnyCancellable>()
    private let datacentersUpdatedTrigger = PassthroughSubject<Void, Never>()

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
         preferences: Preferences) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
        self.preferences = preferences

        loadInitialServers()
        loadInitialLocations()
        loadInitialFavourites()

        // Update datacenter servers when either servers change or datacenters are updated
        Publishers.CombineLatest(serverListSubject, datacentersUpdatedTrigger)
            .sink { [weak self] (serverList, _) in
                guard let self = self else { return }

                var serversByDatacenter: [Int: [ServerMachineModel]] = [:]
                serverList.forEach { server in
                    serversByDatacenter[server.datacenterId, default: []].append(server)
                }

                let updatedDatacenterList = self.currentDatacenterModels.map { datacenter in
                    var updatedDatacenter = datacenter
                    updatedDatacenter.servers = serversByDatacenter[datacenter.id] ?? []
                    return updatedDatacenter
                }

                self.datacenterListSubject.send(updatedDatacenterList)
                self.populateLocations(from: updatedDatacenterList)
            }
            .store(in: &cancellables)
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

    private func updateDatacenterList(from locations: [LocationModel], shouldTrigger: Bool = true) {
        let allDatacenters = locations.flatMap { $0.datacenters }
        datacenterListSubject.send(allDatacenters)
        if shouldTrigger {
            datacentersUpdatedTrigger.send(())
        }
        logger.logI("LocationListRepositoryImpl", "Successfully updated \(allDatacenters.count) datacenters")
    }

    private func loadInitialLocations() {
        if let locationObjects = localDatabase.getLocations(), !locationObjects.isEmpty {
            let locations = locationObjects.map { LocationModel(from: $0) }
            locationListSubject.send(locations)
            updateDatacenterList(from: locations)
        } else if let deprecatedList = self.localDatabase.getServers(), !deprecatedList.isEmpty {
            let newlocationList = deprecatedList.map { $0.getLocationModel() }
            saveLocationList(with: newlocationList)
        }
    }

    private func loadInitialServers() {
        if let serversObjects = self.localDatabase.getServerMachines() {
            let servers = serversObjects.map { ServerMachineModel(from: $0) }
            serverListSubject.send(servers)
        }
    }

    private func saveLocationList(with locations: [LocationModel]) {
        locationListSubject.send(locations)
        // Convert models to Realm objects and save to local database
        let locationObjects = locations.map { LocationObject(from: $0) }
        localDatabase.saveLocations(locations: locationObjects)

        logger.logI("LocationListRepositoryImpl", "Successfully updated \(locations.count) locations")

        // Extract and save all datacenters separately for easier querying
        updateDatacenterList(from: locations)
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
                let locations = locationObjects.map { LocationModel(from: $0) }
                locationListSubject.send(locations)
                updateDatacenterList(from: locations)
                return
            } else {
                throw error
            }
        }
    }

    private func loadInitialFavourites() {
        let favListObjects = self.localDatabase.getFavouriteList()
        let favList = favListObjects.map { FavouriteModel(from: $0) }
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
                let servers = serversObjects.map { ServerMachineModel(from: $0) }
                serverListSubject.send(servers)
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
        preferences.saveHasIpBackup(backup: hasBackup)
        serverListSubject.send(servers)
        let serverObjects = servers.map { ServerMachineObject(from: $0) }
        localDatabase.saveServerMachines(serverMachines: serverObjects)
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
            .first { $0.id == locationId }?
            .getModel()
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
        if favList.first(where: { favourite.id == $0.id }) == nil {
            favList.append(favourite)
            favouriteListSubject.send(favList)
        }
        localDatabase.saveFavourite(favourite: favourite.getObject())
    }

    // MARK: - Pinned Locations
    func saveLastConnectedHost(for hostName: String, with locationId: Int) {
        preferences.saveLastNodeIP(nodeIp: hostName)
        hasPinnedNodeMismatch = false

        if let favorite = getFavorite(from: String(locationId)),
           favorite.pinnedNodeIp != nil {
            if favorite.pinnedNodeIp == hostName {
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

    func getDatacenterPinnedIp(for datacenterId: Int) -> String? {
        localDatabase.getFavouriteList().first {
            $0.id == String(datacenterId) && $0.pinnedNodeIp != nil
        }?.pinnedNodeIp
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
            updateDatacenterList(from: mergedModels, shouldTrigger: false)
            return
        }
    }
}
