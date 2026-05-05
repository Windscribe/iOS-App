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
    var suggestedPorts: SuggestedPortsModel?

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger

        if let portMaps = localDatabase.getPortMap() {
            currentPortMaps = portMaps
        }
        suggestedPorts = localDatabase.getSuggestedPorts()?.first
    }

    func getUpdatedPortMap() async throws -> [PortMapModel] {
        do {
            let portList = try await apiManager.getPortMap(version: APIParameterValues.portMapVersion, forceProtocols: APIParameterValues.forceProtocols)
            localDatabase.savePortMap(portMap: Array(portList.portMaps).map { $0.getModel() })
            if let suggested = portList.suggested {
                localDatabase.saveSuggestedPorts(suggestedPorts: [suggested.getModel()])
                suggestedPorts = suggested.getModel()
            }
            currentPortMaps = Array(portList.portMaps).map { $0.getModel() }
            return currentPortMaps
        } catch {
            // Fallback to cached data on error
            if let portMaps = localDatabase.getPortMap(), !portMaps.isEmpty {
                currentPortMaps = portMaps
                return currentPortMaps
            } else {
                throw error
            }
        }
    }

    func getPorts(protocolType: String) -> [String]? {
        let selectedProtocolPorts = currentPortMaps.filter { $0.heading == protocolType }
        var portsArray = [String]()
        guard let portsList = selectedProtocolPorts.first?.ports else { return nil }
        portsArray.append(contentsOf: portsList)
        return portsArray
    }
}
