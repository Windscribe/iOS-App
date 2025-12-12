//
//  LatencyRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol LatencyRepository {
    var latency: BehaviorSubject<[PingDataModel]> { get }
    func getPingData(ip: String) -> PingDataModel?
    func loadLatency() async throws
    func loadStaticIpLatency() -> Single<[PingDataModel]>
    func loadCustomConfigLatency() -> Completable
    func pickBestLocation(pingData: [PingDataModel])
    func pickBestLocation()
    func refreshBestLocation()
    func checkLocationsValidity() async
}
