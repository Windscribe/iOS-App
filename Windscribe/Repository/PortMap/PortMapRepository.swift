//
//  PortMapRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol PortMapRepository {
    var currentPortMaps: [PortMapModel] { get }
    var suggestedPorts: SuggestedPortsModel? { get }

    func getUpdatedPortMap() async throws -> [PortMapModel]
    func getPorts(protocolType: String) -> [String]?
}
