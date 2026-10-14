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

    /// Canonical merge inputs, mutated/read only on `mergeQueue` so every recompute sees a
    /// consistent snapshot of both feeds. `rawLocations` is the sorted, un-renamed on-disk shape.
    private let mergeQueue = DispatchQueue(label: "com.windscribe.locationlist.merge")
    private var rawLocations: [LocationModel] = []
    private var rawServers: [ServerMachineModel] = []

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

        self.antiCensorshipRepository.selecteRoutingTypeSubject
            .dropFirst()
            .sink { [weak self] _ in
                Task {
                    try? await self?.updatedServerList()
                }
            }
            .store(in: &cancellables)

        loadInitialState()
        loadInitialFavourites()
    }

    // MARK: - Serialized merge

    /// Runs `work` on `mergeQueue` and suspends until it completes, serializing all merges.
    private func onMergeQueue(_ work: @escaping () -> Void) async {
        await withCheckedContinuation { (continuation: CheckedContinuation<Void, Never>) in
            mergeQueue.async {
                work()
                continuation.resume()
            }
        }
    }

    /// Rebuilds and republishes all three subjects from the current `rawLocations` + `rawServers`. Must run on `mergeQueue`.
    private func recomputeAndPublish() {
        let displayLocations = applyCustomNames(to: rawLocations)

        var serversByDatacenter: [Int: [ServerMachineModel]] = [:]
        rawServers.forEach { server in
            serversByDatacenter[server.datacenterId, default: []].append(server)
        }

        let mergedLocations = displayLocations.map { location -> LocationModel in
            var updatedLocation = location
            updatedLocation.datacenters = location.datacenters.map { datacenter -> DatacenterModel in
                var updatedDatacenter = datacenter
                updatedDatacenter.servers = serversByDatacenter[datacenter.id] ?? []
                return updatedDatacenter
            }
            return updatedLocation
        }
        let mergedDatacenters = mergedLocations.flatMap { $0.datacenters }

        let withServers = mergedDatacenters.filter { !$0.servers.isEmpty }.count
        logger.logI("LocationListRepositoryImpl",
                    "Merge: attached servers to \(withServers)/\(mergedDatacenters.count) datacenters (\(rawServers.count) servers, \(mergedLocations.count) locations)")

        // Publish the merged views first, then the raw server list, so any server-list observer
        // already sees the fresh datacenters/locations.
        datacenterListSubject.send(mergedDatacenters)
        locationListSubject.send(mergedLocations)
        serverListSubject.send(rawServers)
    }

    /// Applies cached custom location/datacenter names, keeping the original count-match safeguard.
    private func applyCustomNames(to locationList: [LocationModel]) -> [LocationModel] {
        let regions = preferences.getCustomLocationsNames()
        guard !regions.isEmpty else { return locationList }

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
        return mergedModels.count == locationList.count ? mergedModels : locationList
    }

    // MARK: - Initial load

    /// Loads cached data synchronously during init (callers expect it immediately); `sync` is safe as nothing references the repository yet.
    private func loadInitialState() {
        mergeQueue.sync {
            if let serversObjects = localDatabase.getServerMachines() {
                rawServers = serversObjects
            }

            if let locationObjects = localDatabase.getLocations(), !locationObjects.isEmpty {
                rawLocations = sortLocationsByGeography(locationObjects)
            } else if let deprecatedList = localDatabase.getServers(), !deprecatedList.isEmpty {
                let ordered = sortLocationsByGeography(deprecatedList)
                localDatabase.saveLocations(locations: ordered)
                rawLocations = ordered
            }

            recomputeAndPublish()
        }
    }

    private func loadInitialFavourites() {
        let favList = self.localDatabase.getFavouriteList()
        favouriteListSubject.send(favList)
    }

    // MARK: - Network updates

    func updateLocations() async throws {
        do {
            let locationsList = try await apiManager.getLocationsList()
            let ordered = sortLocationsByGeography(locationsList.locations)
            logger.logI("LocationListRepositoryImpl", "Successfully updated \(ordered.count) locations")
            await setRawLocations(ordered, persist: true)
        } catch {
            logger.logE("LocationListRepositoryImpl", "Failed to update locations: \(error.localizedDescription)")

            // Try to load from local database as fallback
            if let locationObjects = localDatabase.getLocations() {
                await setRawLocations(sortLocationsByGeography(locationObjects), persist: false)
                return
            } else {
                throw error
            }
        }
    }

    func updatedServerList() async throws {
        do {
            let serverList = try await self.apiManager.getServerMachinesList()
            let servers = serverList.servers
            await setRawServers(servers, revision: serverList.revision)
            logger.logI("LocationListRepositoryImpl", "Successfully updated \(servers.count) server machines")
        } catch {
            logger.logE("LocationListRepositoryImpl", "Failed to update servers machines: \(error.localizedDescription)")

            if let serversObjects = self.localDatabase.getServerMachines() {
                await setRawServers(serversObjects, revision: nil)
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
        mergeQueue.async { [weak self] in
            guard let self = self else { return }
            self.preferences.saveServerRevision(revision: inventory.revision)

            var currentServers = self.rawServers
            inventory.disabled.forEach { disabled in
                currentServers.removeAll(where: { $0.id == disabled.id })
            }
            let enabledServerIds = Set(inventory.enabled.map(\.id))
            currentServers.removeAll(where: { enabledServerIds.contains($0.id) })
            currentServers.append(contentsOf: inventory.enabled)

            self.rawServers = currentServers
            self.localDatabase.saveServerMachines(serverMachines: currentServers)
            self.recomputeAndPublish()
        }
    }

    /// Sets the canonical server list (persisting when a fresh `revision` is supplied) and republishes.
    private func setRawServers(_ servers: [ServerMachineModel], revision: Int64?) async {
        await onMergeQueue { [weak self] in
            guard let self = self else { return }
            if let revision = revision {
                self.preferences.saveServerRevision(revision: revision)
                self.localDatabase.saveServerMachines(serverMachines: servers)
            }
            self.rawServers = servers
            self.recomputeAndPublish()
        }
    }

    /// Sets the canonical location list (persisting the canonical shape when fresh) and republishes.
    private func setRawLocations(_ locations: [LocationModel], persist: Bool) async {
        await onMergeQueue { [weak self] in
            guard let self = self else { return }
            if persist {
                self.localDatabase.saveLocations(locations: locations)
            }
            self.rawLocations = locations
            self.recomputeAndPublish()
        }
    }

    // MARK: - Lookups

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
        guard !currentLocationModels.isEmpty else { return }
        mergeQueue.async { [weak self] in
            guard let self = self else { return }
            self.preferences.saveCustomLocationsNames(value: regions)
            self.recomputeAndPublish()
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
