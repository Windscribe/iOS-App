//
//  LocationsManager.swift
//  Windscribe
//
//  Created by Andre Fonseca on 28/11/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

protocol LocationsManagerType {
    func getBestLocationModel(from groupId: String) -> BestLocationModel?
    func getLocation(from groupId: String) throws -> (Server, Group)
}

class LocationsManager: LocationsManagerType {
    private let localDatabase: LocalDatabase
    
    init(localDatabase: LocalDatabase) {
        self.localDatabase = localDatabase
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
}
