//
//  LocationsManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift

struct LocationUIInfo {
    let nickName: String
    let cityName: String
    let countryCode: String
}

protocol LocationsManagerType {
    func getBestLocationModel(from groupId: String) -> BestLocationModel?
    func getLocation(from groupId: String) throws -> (ServerModel, GroupModel)
    func getLocationUIInfo() -> LocationUIInfo
    func saveLastSelectedLocation(with locationID: String)
    func saveStaticIP(withID staticID: Int?)
    func saveCustomConfig(withID staticID: String?)
    func clearLastSelectedLocation()
    func saveBestLocation(with locationID: String)
    func selectBestLocation(with locationID: String)
    func getBestLocation() -> String
    func getLastSelectedLocation() -> String
    func getLocationType() -> LocationType?
    func getLocationType(id: String) -> LocationType?
    func getId() -> String
    func getId(location: String) -> String
    func isCustomConfigSelected() -> Bool
    func checkLocationValidity(checkProAccess: () -> Bool)
    func checkForForceDisconnect() -> Bool

    var selectedLocationUpdatedSubject: BehaviorSubject<Bool> { get }
}

class LocationsManager: LocationsManagerType {
    private let localDatabase: LocalDatabase
    private let preferences: Preferences
    private let logger: FileLogger
    private let languageManager: LanguageManagerV2
    private let serverRepository: ServerRepository

    private let disposeBag = DisposeBag()

    let selectedLocationUpdatedSubject = BehaviorSubject<Bool>(value: (false))

    init(localDatabase: LocalDatabase, preferences: Preferences, logger: FileLogger, languageManager: LanguageManagerV2, serverRepository: ServerRepository) {
        self.localDatabase = localDatabase
        self.preferences = preferences
        self.logger = logger
        self.languageManager = languageManager
        self.serverRepository = serverRepository

        languageManager.activelanguage.subscribe { [weak self] _ in
            self?.selectedLocationUpdatedSubject.onNext(false)
        }.disposed(by: disposeBag)

        serverRepository.updatedServerModelsSubject.subscribe { [weak self] _ in
            self?.selectedLocationUpdatedSubject.onNext(false)
        }.disposed(by: disposeBag)


    }

    func getBestLocationModel(from groupId: String) -> BestLocationModel? {
        guard let groupServer = try? getLocation(from: groupId),
              let node = groupServer.1.nodes.randomElement() else { return nil }
        return BestLocationModel(node: node,
                                 group: groupServer.1,
                                 server: groupServer.0)
    }

    func getLocation(from groupId: String) throws -> (ServerModel, GroupModel) {
        let servers = serverRepository.currentServerModels
        guard !servers.isEmpty else { throw VPNConfigurationErrors.locationNotFound(groupId) }
        let serverResult = servers.first { $0.groups.first { groupId == "\($0.id)" } != nil }
        guard let serverResultSafe = serverResult else { throw VPNConfigurationErrors.locationNotFound(groupId) }
        let groupResult = serverResultSafe.groups.first(where: { groupId == "\($0.id)" })
        guard let groupResultSafe = groupResult else { throw VPNConfigurationErrors.locationNotFound(groupId)
        }
        return (serverResultSafe, groupResultSafe)
    }

    func getLocationUIInfo() -> LocationUIInfo {
        guard let locationType = getLocationType() else {
            return getEmptyUIInfo()
        }
        let groupId = getLastSelectedLocation()
        if locationType == .server {
            guard let location = try? getLocation(from: groupId) else {
                return getEmptyUIInfo()
            }
            let cityName = getBestLocation() == getLastSelectedLocation() ? TextsAsset.bestLocation : location.1.city
            return LocationUIInfo(nickName: location.1.nick, cityName: cityName, countryCode: location.0.countryCode)
        } else {
            let locationID = getId()
            if locationType == .custom {
                guard let customConfig = localDatabase.getCustomConfigs().first(where: { locationID == "\($0.id)" }) else {
                    return getEmptyUIInfo()
                }
                return LocationUIInfo(nickName: customConfig.name, cityName: TextsAsset.configuredLocation, countryCode: Fields.configuredLocation)
            } else if locationType == .staticIP {
                guard let staticIP = localDatabase.getStaticIPs()?.first(where: { locationID == "\($0.id)" }) else {
                    return getEmptyUIInfo()
                }
                return LocationUIInfo(nickName: staticIP.staticIP, cityName: staticIP.cityName, countryCode: staticIP.countryCode)
            }
        }
        return getEmptyUIInfo()
    }

    private func getEmptyUIInfo() -> LocationUIInfo {
        return LocationUIInfo(nickName: "", cityName: "", countryCode: "")
    }

    func checkForForceDisconnect() -> Bool {
        let locationID = getLastSelectedLocation()
        guard !locationID.isEmpty, locationID != "0" else { return false }
        guard let serverGroup = try? getLocation(from: locationID) else { return false }
        if serverGroup.1.bestNode?.forceDisconnect ?? false {
            if let sisterLocationID = getSisterLocationID(from: locationID) {
                saveLastSelectedLocation(with: sisterLocationID)
                return true
            }
        }
        return false
    }

    func saveLastSelectedLocation(with locationID: String) {
        guard locationID != getLastSelectedLocation() else { return }
        preferences.saveLastSelectedLocation(with: locationID)
        selectedLocationUpdatedSubject.onNext(true)
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
        preferences.saveBestLocation(with: locationID)
        let lastLocation = getLastSelectedLocation()
        if lastLocation.isEmpty || lastLocation == "0" {
            saveLastSelectedLocation(with: locationID)
        }
    }

    func selectBestLocation(with locationID: String) {
        saveLastSelectedLocation(with: locationID)
        saveBestLocation(with: locationID)
    }

    func getBestLocation() -> String {
        preferences.getBestLocation()
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
    func getId() -> String {
        return getId(location: getLastSelectedLocation())
    }

    func getId(location: String) -> String {
        guard !location.isEmpty else {
            return getBestLocation()
        }

        let parts = location.split(separator: "_")
        if parts.count == 1 {
            return location
        }
        return String(parts[1])
    }

    func isCustomConfigSelected() -> Bool {
        return preferences.isCustomConfigSelected()
    }

    func checkLocationValidity(checkProAccess: () -> Bool) {
        let locationID = getLastSelectedLocation()
        guard !locationID.isEmpty, locationID != "0" else {
            self.logger.logD(self, "Location is empty or invalid.. Switching to Best location.")
            updateToBestLocation()
            return
        }
        guard let currentLocation = try? getLocation(from: locationID) else {
            self.logger.logD(self, "Unable to find location with ID: \(locationID). Switching to Sister location.")
            if let sisterLocationID = getSisterLocationID(from: locationID) {
                saveLastSelectedLocation(with: sisterLocationID)
            } else {
                self.logger.logD(self, "Unable to find sister location. Switching to Best location.")
                updateToBestLocation()
            }
            return
        }
        if !checkProAccess() && currentLocation.1.premiumOnly {
            updateToBestLocation()
        }
    }
}

extension LocationsManager {
    private func updateToBestLocation() {
        saveLastSelectedLocation(with: getBestLocation())
    }

    private func getSisterLocationID(from groupId: String) -> String? {
        let servers = serverRepository.currentServerModels
        guard !servers.isEmpty else { return nil }
        let serverResult = servers.first { $0.groups.first { groupId == "\($0.id)" } != nil }
        guard let serverResultSafe = serverResult else { return nil }
        let groupResult = serverResultSafe.groups.filter {
            groupId != "\($0.id)" && $0.isNodesAvailable()
        }.randomElement()
        guard let groupResultSafe = groupResult else { return nil }
        return "\(groupResultSafe.id)"
    }
}
