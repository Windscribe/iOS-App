//
//  EmergencyRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-23.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

protocol EmergencyRepository {
    func getConfig() async -> [OpenVPNConnectionInfo]
    func connect(configInfo: OpenVPNConnectionInfo) -> AnyPublisher<State, Error>
    func disconnect() -> AnyPublisher<State, Error>
    func isConnected() -> Bool
    func cleansEmergencyConfigs()
}
