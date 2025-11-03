//
//  ServerRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ServerRepository {
    var updatedServerModelsSubject: CurrentValueSubject<[ServerModel], Never> { get }
    var currentServerModels: [ServerModel] { get }
    func getUpdatedServers() async throws -> [Server]
    func updateRegions(with regions: [ExportedRegion])
}
