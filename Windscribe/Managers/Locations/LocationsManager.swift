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
    func getLocationDatacenter(from datacenterId: Int) throws -> (LocationModel, DatacenterModel)
    func getLocationDatacenter(from datacenterId: String) throws -> (LocationModel, DatacenterModel)
    func getLocationUIInfo() -> LocationUIInfo

    func saveStaticIP(withId staticId: Int?)
    func saveCustomConfig(withId customId: String?)

    /// Saves the best location, it needs a datacenterId to access the information needed, the BestLocation is Not a Datacenter
    /// And holds information from both LocationModel and the DatacenterModel
    func saveBestLocation(with datacenterId: String)

    /// Selects the Best Locations associated to the datacenterId as the last Connected Target and saves the best location
    /// it needs a datacenterId to access the information needed, the BestLocation is Not a Datacenter
    /// And holds information from both LocationModel and the DatacenterModel
    func selectBestLocation(with datacenterId: String)
    func getBestLocation() -> Int
    func getCustomId(location: String) -> String
    func isCustomConfigSelected() -> Bool
    func checkForForceDisconnect() -> Bool
    func getIsProDatacenterSelected() -> Bool

    /// Gets the full Id of the Datacenter / Static IP / Custom Config that was last connected/selected by the user
    func getLastConnectionTarget() -> String
    /// Saves the full Id of the Datacenter / Static IP / Custom Config that was last connected/selected by the user
    func saveLastConnectionTarget(with targetId: String)
    /// Clears the full id, making it empty string "", so there is no Datacenter / Static IP / Custom Config as the last place the user connected to
    func clearLastConnectionTarget()

    func getConnectionTargetType() -> ConnectionTargetType?
    func getConnectionTargetType(id: String) -> ConnectionTargetType?

    /// Gets the short Id (no identifier for the target type, server, static, custom) of the Datacenter / Static IP / Custom Config that was last connected/selected by the user
    func getLastConnectionTargetId() -> Int
    /// Gets the short Id (no identifier for the target type, server, static, custom) of the Datacenter / Static IP / Custom Config that was last connected/selected by the user
    func getLastConnectionTargetId(location: String) -> Int

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
        guard let locationDatacenter = try? getLocationDatacenter(from: datacenterId) else { return nil }
        return BestLocationModel(datacenter: locationDatacenter.1,
                                 location: locationDatacenter.0)
    }

    func getLocationDatacenter(from datacenterId: String) throws -> (LocationModel, DatacenterModel) {
        if let intId = Int(datacenterId) {
            return try getLocationDatacenter(from: intId)
        }
        throw VPNConfigurationErrors.locationNotFound(datacenterId)
    }

    func getLocationDatacenter(from datacenterId: Int) throws -> (LocationModel, DatacenterModel) {
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
        let selectedId = getLastConnectionTarget()
        let bestLocationId = getBestLocation()
        var selectedDatacenterId = Int(selectedId) ?? 0

        guard let connectionTargetType = getConnectionTargetType(id: selectedId) else {
            return getEmptyUIInfo()
        }

        // If no location selected but best location exists, use best location
        if (selectedId.isEmpty || selectedId == "0") && bestLocationId != 0 {
            selectedDatacenterId = bestLocationId
        }

        if connectionTargetType == .server {
            guard let location = try? getLocationDatacenter(from: selectedDatacenterId) else {
                return getEmptyUIInfo()
            }
            let cityName = bestLocationId == selectedDatacenterId ? TextsAsset.bestLocation : location.1.city
            return LocationUIInfo(nickName: location.1.nick, cityName: cityName, countryCode: location.0.countryCode, isServer: true)
        } else {
            if connectionTargetType == .custom {
                let customId = getCustomId(location: selectedId)
                guard let customConfig = customConfigRepository.getCustomConfig(fileId: customId) else {
                    return getEmptyUIInfo()
                }
                // Never show emergency connect configs in the UI
                if customConfig.name == AppConstants.emergencyConfig {
                    return getEmptyUIInfo()
                }
                return LocationUIInfo(nickName: customConfig.name, cityName: TextsAsset.configuredLocation, countryCode: Fields.configuredLocation, isServer: false)
            } else if connectionTargetType == .staticIP {
                let targetId = getLastConnectionTargetId()
                guard let staticIP = staticIpRepository.getStaticIp(id: targetId) else {
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
        let targetId = getLastConnectionTarget()
        guard !targetId.isEmpty, targetId != "0", let datacenterId = Int(targetId) else {
            return false
        }
        guard !locationListRepository.currentServerModels.isEmpty else {
            return false
        }
        if locationListRepository.getServers(for: datacenterId).isEmpty {
            if let sisterLocationId = getSisterLocationId(from: datacenterId) {
                saveLastConnectionTarget(with: "\(sisterLocationId)")
                return true
            }
        }
        return false
    }

    func saveLastConnectionTarget(with targetId: String) {
        saveLastConnectionTarget(with: targetId, shouldReconnect: true)
    }

    func saveStaticIP(withId staticId: Int?) {
        saveLastConnectionTarget(with: "static_\(staticId ?? 0)")
    }

    func saveCustomConfig(withId customId: String?) {
        saveLastConnectionTarget(with: "custom_\(customId ?? "0")")
    }

    func clearLastConnectionTarget() {
        preferences.saveLastConnectionTarget(with: "")
    }

    func saveBestLocation(with datacenterId: String) {
        let currentBestLocation = getBestLocation()
        preferences.saveBestLocation(with: datacenterId)
        self.logger.logI("LocationsManager", "Saved BestLocation Id: \(datacenterId) (previous: \(currentBestLocation))")
        checkLocationValidity()
        // Always send update even if location is same, to ensure UI reactivity
        bestLocationUpdatedTrigger.send(())
    }

    func selectBestLocation(with datacenterId: String) {
        saveLastConnectionTarget(with: datacenterId)
        saveBestLocation(with: datacenterId)
    }

    func getBestLocation() -> Int {
        if let datacenterId = Int(preferences.getBestLocation()) {
            return datacenterId
        }
        return 0
    }

    func getLastConnectionTarget() -> String {
        preferences.getLastConnectionTarget()
    }

    func getConnectionTargetType() -> ConnectionTargetType? {
        preferences.getConnectionTargetType()
    }

    /// Gets the Connection target  type based on id.
    func getConnectionTargetType(id: String) -> ConnectionTargetType? {
        preferences.getConnectionTargetType(id: id)
    }

    /// Gets id from location id which can be used to access data from database.
    func getLastConnectionTargetId() -> Int {
        return getLastConnectionTargetId(location: getLastConnectionTarget())
    }

    func getLastConnectionTargetId(location: String) -> Int {
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

        let connectionTargetType = getConnectionTargetType() ?? .server

        let locationId = getLastConnectionTarget()
        guard !locationId.isEmpty, locationId != "0" else {
            self.logger.logI("LocationsManager", "Location is empty or invalid.. Switching to Best location.")
            updateToBestLocation()
            return
        }
        if connectionTargetType == .server, let datacenterId = Int(locationId) {
            guard let currentLocation = try? getLocationDatacenter(from: datacenterId) else {
                self.logger.logI("LocationsManager", "Unable to find location with Id: \(datacenterId). Switching to Sister location.")
                if let sisterLocationId = getSisterLocationId(from: datacenterId) {
                    saveLastConnectionTarget(with: String(sisterLocationId))
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

    func getIsProDatacenterSelected() -> Bool {
        let datacenterId = getLastConnectionTargetId()
        guard let datacenter = locationListRepository.getDatacenter(by: datacenterId) else { return false }
        return datacenter.isPremiumOnly
    }
}

extension LocationsManagerImpl {
    private func updateToBestLocation() {
        saveLastConnectionTarget(with: String(getBestLocation()), shouldReconnect: false)
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

    private func saveLastConnectionTarget(with locationId: String, shouldReconnect: Bool) {
        let currentLocation = getLastConnectionTarget()
        guard locationId != currentLocation else {
            // Even if location hasn't changed, trigger update for UI reactivity
            selectedLocationUpdated.send(shouldReconnect)
            return
        }
        preferences.saveLastConnectionTarget(with: locationId)
        selectedLocationUpdated.send(shouldReconnect)
    }
}
