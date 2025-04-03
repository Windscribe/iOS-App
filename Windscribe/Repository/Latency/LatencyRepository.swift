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
    var latency: BehaviorSubject<[PingData]> { get }
    func getPingData(ip: String) -> PingData?
    func loadLatency()
    func loadAllServerLatency() -> Completable
    func loadStaticIpLatency() -> Single<[PingData]>
    func loadFavouriteLatency() -> Completable
    func loadCustomConfigLatency() -> Completable
    func pickBestLocation(pingData: [PingData])
    func pickBestLocation()
    func refreshBestLocation()
}
