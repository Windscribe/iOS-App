//
//  LatencyRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol LatencyRepository {
    var latency: CurrentValueSubject<[PingDataModel], Never> { get }
    func getPingData(ip: String) -> PingDataModel?
    func loadLatency() async throws
    func loadStaticIpLatency() async
    func loadCustomConfigLatency() async
    func pickBestLocation(pingData: [PingDataModel])
    func pickBestLocation()
    func refreshBestLocation()
    func checkLocationsValidity() async
}
