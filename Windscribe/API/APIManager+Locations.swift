//
//  APIManager+Locations.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

extension APIManagerImpl {
    // Locations and Servers
    func getLocationsList() async throws -> LocationsListModel {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: LocationsListModel.self) { completion in
            self.api.getLocations(sessionAuth, callback: completion)
        }
    }

    func getServerMachinesList() async throws -> ServerMachinesListModel {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        let useBackup = preferences.getRoutingType().apiValue
        return try await apiUtil.makeApiCall(modalType: ServerMachinesListModel.self) { completion in
            self.api.getServers(sessionAuth, backup: useBackup, callback: completion)
        }
    }
}
