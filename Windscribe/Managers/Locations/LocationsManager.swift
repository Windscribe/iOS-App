//
//  LocationsManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import RxSwift

protocol LocationsManagerType {
    func getBestLocationModel(from groupId: String) -> BestLocationModel?
    func getLocation(from groupId: String) throws -> (Server, Group)
    func saveLastSelectedLocation(with locationID: String)
    func saveBestLocation(with locationID: String)
    func selectBestLocation(with locationID: String)
    func getBestLocation() -> String
    func getLastSelectedLocation() -> String
    func getLocationType() -> LocationType?
    func getLocationType(id: String) -> LocationType?
    func getId() -> String
    func getId(location: String) -> String
    func isCustomConfigSelected() -> Bool

    var selectedLocationUpdatedSubject: BehaviorSubject<Void> { get }
}

class LocationsManager: LocationsManagerType {
    private let localDatabase: LocalDatabase
    private let preferences: Preferences

    let selectedLocationUpdatedSubject = BehaviorSubject<Void>(value: ())

    init(localDatabase: LocalDatabase, preferences: Preferences) {
        self.localDatabase = localDatabase
        self.preferences = preferences
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
        var serverResult: Server?
        var groupResult: Group?
        for server in servers {
            let groups = server.groups
            for group in groups where groupId == "\(group.id)" {
                serverResult = server
                groupResult = group
            }
        }
        guard let serverResultSafe = serverResult, let groupResultSafe = groupResult else { throw VPNConfigurationErrors.locationNotFound(groupId)
        }
        return (serverResultSafe, groupResultSafe)
    }

    func saveLastSelectedLocation(with locationID: String) {
        preferences.saveLastSelectedLocation(with: locationID)
        selectedLocationUpdatedSubject.onNext(())
    }

    func saveBestLocation(with locationID: String) {
        preferences.saveBestLocation(with: locationID)
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
        let parts = location.split(separator: "_")
        if parts.count == 1 {
            return location
        }
        return String(parts[1])
    }

    func isCustomConfigSelected() -> Bool {
        return preferences.isCustomConfigSelected()
    }
}
