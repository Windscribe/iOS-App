//
//  PortMapRepositoryImpl.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class PortMapRepositoryImpl: PortMapRepository {

    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger

    var currentPortMaps = [PortMapModel]()

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger

        if let portMaps = localDatabase.getPortMap() {
            currentPortMaps = portMaps.map { $0.getModel() }
        }
    }

    func getUpdatedPortMap() async throws -> [PortMapModel] {
        do {
            let portList = try await apiManager.getPortMap(version: APIParameterValues.portMapVersion, forceProtocols: APIParameterValues.forceProtocols)
            localDatabase.savePortMap(portMap: Array(portList.portMaps))
            if let suggested = portList.suggested {
                localDatabase.saveSuggestedPorts(suggestedPorts: [suggested])
            }
            currentPortMaps = Array(portList.portMaps).map { $0.getModel() }
            return currentPortMaps
        } catch {
            // Fallback to cached data on error
            if let portMaps = localDatabase.getPortMap(), !portMaps.isEmpty {
                currentPortMaps = portMaps.map { $0.getModel() }
                return currentPortMaps
            } else {
                throw error
            }
        }
    }
}
