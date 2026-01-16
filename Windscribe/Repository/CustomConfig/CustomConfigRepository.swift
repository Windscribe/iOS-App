//
//  CustomConfigRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-26.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol CustomConfigRepository {
    var customConfigs: CurrentValueSubject<[CustomConfigModel], Never> { get }

    func saveWgConfig(url: URL) async throws
    func removeWgConfig(fileId: String) async
    func saveOpenVPNConfig(url: URL) async throws
    func removeOpenVPNConfig(fileId: String) async

    func removeCustomConfig(fileId: String)

    func saveOpenVPNCustomConfig(data: Data,
                                 configInfo: OpenVPNConnectionInfo,
                                 configuationName: String) async throws -> CustomConfigModel

    func getCustomConfig(fileId: String) -> CustomConfigModel?

    func saveCustomConfig(customConfig: CustomConfigModel)

}
