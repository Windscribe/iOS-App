//
//  LocationsManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine

struct LocationUIInfo {
    let nickName: String
    let cityName: String
    let countryCode: String
    let isServer: Bool
}

protocol LocationsManager {
    func getBestLocationModel(from datacenterId: Int) -> BestLocationModel?
    func getBestLocationModel() -> BestLocationModel?
    func getLocation(from datacenterId: Int) throws -> (LocationModel, DatacenterModel)
    func getLocation(from datacenterId: String) throws -> (LocationModel, DatacenterModel)
    func getLocationUIInfo() -> LocationUIInfo
    func saveLastSelectedLocation(with locationID: String)
    func saveStaticIP(withID staticID: Int?)
    func saveCustomConfig(withID staticID: String?)
    func clearLastSelectedLocation()
    func saveBestLocation(with locationID: String)
    func selectBestLocation(with locationID: String)
    func getBestLocation() -> Int
    func getLastSelectedLocation() -> String
    func getLocationType() -> LocationType?
    func getLocationType(id: String) -> LocationType?
    func getId() -> Int
    func getId(location: String) -> Int
    func getCustomId(location: String) -> String
    func isCustomConfigSelected() -> Bool
    func checkForForceDisconnect() -> Bool
    func getIsSelectedLocationPremium() -> Bool

    var selectedLocationUpdated: CurrentValueSubject<Bool, Never> { get }
    var bestLocationUpdatedTrigger: PassthroughSubject<Void, Never> { get }
}

class LocationsManagerImpl: LocationsManager {
    private let customConfigRepository: CustomConfigRepository
    private let preferences: Preferences
    private let logger: FileLogger
    private let staticIpRepository: StaticIpRepository
    private let languageManager: LanguageManager
    private let locationListRepository: LocationListRepository
    private let userSessionRepository: UserSessionRepository

    private var cancellables = Set<AnyCancellable>()

    let selectedLocationUpdated = CurrentValueSubject<Bool, Never>(false)
    let bestLocationUpdatedTrigger = PassthroughSubject<Void, Never>()

    init(customConfigRepository: CustomConfigRepository,
         preferences: Preferences,
         logger: FileLogger,
         languageManager: LanguageManager,
         userSessionRepository: UserSessionRepository,
         locationListRepository: LocationListRepository,
         staticIpRepository: StaticIpRepository) {
        self.customConfigRepository = customConfigRepository
        self.preferences = preferences
        self.logger = logger
        self.languageManager = languageManager
        self.userSessionRepository = userSessionRepository
        self.locationListRepository = locationListRepository
        self.staticIpRepository = staticIpRepository

        languageManager.activelanguage.sink { [weak self] _ in
            self?.selectedLocationUpdated.send(false)
        }.store(in: &cancellables)

        locationListRepository.locationListSubject
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                self?.selectedLocationUpdated.send(false)
            })
            .store(in: &cancellables)
        bestLocationUpdatedTrigger.send(())
    }

    func getBestLocationModel() -> BestLocationModel? {
        getBestLocationModel(from: getBestLocation())
    }

    func getBestLocationModel(from datacenterId: Int) -> BestLocationModel? {
        guard let locationDatacenter = try? getLocation(from: datacenterId) else { return nil }
        return BestLocationModel(datacenter: locationDatacenter.1,
                                 location: locationDatacenter.0)
    }

    func getLocation(from datacenterId: String) throws -> (LocationModel, DatacenterModel) {
        if let intId = Int(datacenterId) {
            return try getLocation(from: intId)
        }
        throw VPNConfigurationErrors.locationNotFound(datacenterId)
    }

    func getLocation(from datacenterId: Int) throws -> (LocationModel, DatacenterModel) {
        let locations = locationListRepository.currentLocationModels
        guard !locations.isEmpty else { throw VPNConfigurationErrors.locationNotFound(String(datacenterId)) }
        var datacenterResult: DatacenterModel?
        let locationResult = locations.first { $0.datacenters.first {
            if datacenterId == $0.id {
                datacenterResult = $0
                return true
            }
            return false
        } != nil }
        guard let locationResultSafe = locationResult,
              let datacenterResultSafe = datacenterResult else {
            throw VPNConfigurationErrors.locationNotFound(String(datacenterId))
        }
        return (locationResultSafe, datacenterResultSafe)
    }

    func getLocationUIInfo() -> LocationUIInfo {
        let selectedId = getLastSelectedLocation()
        let bestLocationId = getBestLocation()
        var selectedLocationId = Int(selectedId) ?? 0

        guard let locationType = getLocationType(id: selectedId) else {
            return getEmptyUIInfo()
        }

        // If no location selected but best location exists, use best location
        if (selectedId.isEmpty || selectedId == "0") && bestLocationId != 0 {
            selectedLocationId = bestLocationId
        }

        if locationType == .server {
            guard let location = try? getLocation(from: selectedLocationId) else {
                return getEmptyUIInfo()
            }
            let cityName = bestLocationId == selectedLocationId ? TextsAsset.bestLocation : location.1.city
            return LocationUIInfo(nickName: location.1.nick, cityName: cityName, countryCode: location.0.countryCode, isServer: true)
        } else {
            if locationType == .custom {
                let customId = getCustomId(location: selectedId)
                guard let customConfig = customConfigRepository.getCustomConfig(fileId: customId) else {
                    return getEmptyUIInfo()
                }
                // Never show emergency connect configs in the UI
                if customConfig.name == AppConstants.emergencyConfig {
                    return getEmptyUIInfo()
                }
                return LocationUIInfo(nickName: customConfig.name, cityName: TextsAsset.configuredLocation, countryCode: Fields.configuredLocation, isServer: false)
            } else if locationType == .staticIP {
                let locationID = getId()
                guard let staticIP = staticIpRepository.getStaticIp(id: locationID) else {
                    return getEmptyUIInfo()
                }
                return LocationUIInfo(nickName: staticIP.staticIP, cityName: staticIP.cityName, countryCode: staticIP.countryCode, isServer: false)
            }
        }
        return getEmptyUIInfo()
    }

    private func getEmptyUIInfo() -> LocationUIInfo {
        return LocationUIInfo(nickName: "", cityName: "", countryCode: "", isServer: false)
    }

    func checkForForceDisconnect() -> Bool {
        let locationID = getLastSelectedLocation()
        guard !locationID.isEmpty, locationID != "0", let datacenterId = Int(locationID) else {
            return false
        }
        guard !locationListRepository.currentServerModels.isEmpty else {
            return false
        }
        if locationListRepository.getServers(for: datacenterId).isEmpty {
            if let sisterLocationID = getSisterLocationId(from: datacenterId) {
                saveLastSelectedLocation(with: "\(sisterLocationID)")
                return true
            }
        }
        return false
    }

    func saveLastSelectedLocation(with locationID: String) {
        saveLastSelectedLocation(with: locationID, shouldReconnect: true)
    }

    func saveStaticIP(withID staticID: Int?) {
        saveLastSelectedLocation(with: "static_\(staticID ?? 0)")
    }

    func saveCustomConfig(withID customID: String?) {
        saveLastSelectedLocation(with: "custom_\(customID ?? "0")")
    }

    func clearLastSelectedLocation() {
        preferences.saveLastSelectedLocation(with: "")
    }

    func saveBestLocation(with locationID: String) {
        let currentBestLocation = getBestLocation()
        preferences.saveBestLocation(with: locationID)
        self.logger.logI("LocationsManager", "Saved BestLocation ID: \(locationID) (previous: \(currentBestLocation))")
        checkLocationValidity()
        // Always send update even if location is same, to ensure UI reactivity
        bestLocationUpdatedTrigger.send(())
    }

    func selectBestLocation(with locationID: String) {
        saveLastSelectedLocation(with: locationID)
        saveBestLocation(with: locationID)
    }

    func getBestLocation() -> Int {
        if let locationId = Int(preferences.getBestLocation()) {
            return locationId
        }
        return 0
    }

    func getLastSelectedLocation() -> String {
        preferences.getLastSelectedLocation()
    }

    func getLocationType() -> LocationType? {
        preferences.getLocationType()
    }

    /// Gets location type based on id.
    func getLocationType(id: String) -> LocationType? {
        preferences.getLocationType(id: id)
    }

    /// Gets id from location id which can be used to access data from database.
    func getId() -> Int {
        return getId(location: getLastSelectedLocation())
    }

    func getId(location: String) -> Int {
        guard !location.isEmpty else {
            return getBestLocation()
        }

        let parts = location.split(separator: "_")
        if parts.count == 1 {
            return Int(location) ?? 0
        }
        return Int(parts[1]) ?? 0
    }

    func getCustomId(location: String) -> String {
        guard !location.isEmpty else { return "" }

        let parts = location.split(separator: "_")
        guard parts.count == 2 else { return "" }
        return String(parts[1])
    }

    func isCustomConfigSelected() -> Bool {
        return preferences.isCustomConfigSelected()
    }

    private func checkLocationValidity() {
        guard !locationListRepository.currentServerModels.isEmpty else {
            return
        }

        let locationType = getLocationType() ?? .server

        let locationId = getLastSelectedLocation()
        guard !locationId.isEmpty, locationId != "0" else {
            self.logger.logI("LocationsManager", "Location is empty or invalid.. Switching to Best location.")
            updateToBestLocation()
            return
        }
        if locationType == .server, let datacenterId = Int(locationId) {
            guard let currentLocation = try? getLocation(from: datacenterId) else {
                self.logger.logI("LocationsManager", "Unable to find location with ID: \(datacenterId). Switching to Sister location.")
                if let sisterLocationId = getSisterLocationId(from: datacenterId) {
                    saveLastSelectedLocation(with: String(sisterLocationId))
                } else {
                    self.logger.logI("LocationsManager", "Unable to find sister location. Switching to Best location.")
                    updateToBestLocation()
                }
                return
            }
            let isPremiumOnly = currentLocation.1.isPremiumOnly
            if userSessionRepository.sessionModel != nil,
               !userSessionRepository.canAccesstoProLocation(location: currentLocation.0),
               isPremiumOnly {
                updateToBestLocation()
            }
        }
    }

    func getIsSelectedLocationPremium() -> Bool {
        let datacenterId = getId()
        guard let datacenter = locationListRepository.getDatacenter(by: datacenterId) else { return false }
        return datacenter.isPremiumOnly
    }
}

extension LocationsManagerImpl {
    private func updateToBestLocation() {
        saveLastSelectedLocation(with: String(getBestLocation()), shouldReconnect: false)
    }

    private func getSisterLocationId(from datacenterId: Int) -> Int? {
        let locations = locationListRepository.currentLocationModels
        guard !locations.isEmpty else { return nil }
        let location = locations.first { $0.datacenters.first { datacenterId == $0.id } != nil }
        guard let safeLocation = location else { return nil }
        let datacenter = safeLocation.datacenters.filter { datacenterId != $0.id }
            .randomElement()
        return datacenter?.id
    }

    private func saveLastSelectedLocation(with locationID: String, shouldReconnect: Bool) {
        let currentLocation = getLastSelectedLocation()
        guard locationID != currentLocation else {
            // Even if location hasn't changed, trigger update for UI reactivity
            selectedLocationUpdated.send(shouldReconnect)
            return
        }
        preferences.saveLastSelectedLocation(with: locationID)
        selectedLocationUpdated.send(shouldReconnect)
    }
}
