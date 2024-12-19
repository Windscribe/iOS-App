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
    let isBestLocation: Bool
    let cityName: String
    let countryCode: String
}

protocol LocationsManagerType {
    func getBestLocationModel(from groupId: String) -> BestLocationModel?
    func getLocation(from groupId: String) throws -> (Server, Group)
    func getLocationUIInfo() -> LocationUIInfo?
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

    var selectedLocationUpdatedSubject: BehaviorSubject<Void> { get }
}

class LocationsManager: LocationsManagerType {
    private let localDatabase: LocalDatabase
    private let preferences: Preferences
    private let logger: FileLogger

    let selectedLocationUpdatedSubject = BehaviorSubject<Void>(value: ())

    init(localDatabase: LocalDatabase, preferences: Preferences, logger: FileLogger) {
        self.localDatabase = localDatabase
        self.preferences = preferences
        self.logger = logger
    }

    func getBestLocationModel(from groupId: String) -> BestLocationModel? {
        guard let groupServer = try? getLocation(from: groupId),
              let node = groupServer.1.nodes.randomElement(),
              let serverModel = groupServer.0.getServerModel() else { return nil }
        return BestLocationModel(node: node.getNodeModel(),
                                 group: groupServer.1.getGroupModel(),
                                 server: serverModel)
    }

    func getLocation(from groupId: String) throws -> (Server, Group) {
        guard let servers = localDatabase.getServers() else { throw VPNConfigurationErrors.locationNotFound(groupId) }
        let serverResult = servers.first { $0.groups.first { groupId == "\($0.id)" } != nil }
        guard let serverResultSafe = serverResult else { throw VPNConfigurationErrors.locationNotFound(groupId) }
        let groupResult = serverResultSafe.groups.first(where: { groupId == "\($0.id)" })
        guard let groupResultSafe = groupResult else { throw VPNConfigurationErrors.locationNotFound(groupId)
        }
        return (serverResultSafe, groupResultSafe)
    }

    func getLocationUIInfo() -> LocationUIInfo? {
        guard let locationType = getLocationType() else { return nil }
        let groupId = getLastSelectedLocation()
        if locationType == .server {
            guard let location = try? getLocation(from: groupId) else { return nil }
            let isBestLocation = getBestLocation() == getLastSelectedLocation()
            return LocationUIInfo(nickName: location.1.nick, isBestLocation: isBestLocation, cityName: location.1.city, countryCode: location.0.countryCode)
        } else {
            let locationID = getId()
            if locationType == .custom {
                guard let customConfig = localDatabase.getCustomConfigs().first(where: { locationID == "\($0.id)" }) else {
                    return nil
                }
                return LocationUIInfo(nickName: customConfig.name, isBestLocation: false, cityName: TextsAsset.configuredLocation, countryCode: Fields.configuredLocation)
            } else if locationType == .staticIP {
                guard let staticIP = localDatabase.getStaticIPs()?.first(where: { locationID == "\($0.id)" }) else {
                    return nil
                }
                return LocationUIInfo(nickName: staticIP.name, isBestLocation: false, cityName: staticIP.cityName, countryCode: staticIP.countryCode)
            }
        }
        return nil
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
        selectedLocationUpdatedSubject.onNext(())
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
        guard let servers = localDatabase.getServers() else { return nil }
        let serverResult = servers.first { $0.groups.first { groupId == "\($0.id)" } != nil }
        guard let serverResultSafe = serverResult else { return nil }
        let groupResult = serverResultSafe.groups.filter {
            groupId != "\($0.id)" && $0.getGroupModel().isNodesAvailable()
        }.randomElement()
        guard let groupResultSafe = groupResult else { return nil }
        return "\(groupResultSafe.id)"
    }
}
