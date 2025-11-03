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

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
    }

    func getUpdatedPortMap() async throws -> [PortMap] {
        do {
            let portList = try await apiManager.getPortMap(version: APIParameterValues.portMapVersion, forceProtocols: APIParameterValues.forceProtocols)
            localDatabase.savePortMap(portMap: Array(portList.portMaps))
            if let suggested = portList.suggested {
                localDatabase.saveSuggestedPorts(suggestedPorts: [suggested])
            }
            return Array(portList.portMaps)
        } catch {
            // Fallback to cached data on error
            if let portMaps = localDatabase.getPortMap(), !portMaps.isEmpty {
                return portMaps
            } else {
                throw error
            }
        }
    }
}
