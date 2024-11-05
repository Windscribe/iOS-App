//
//  LatencyViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-06-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol LatencyViewModel {
    func loadAllServerLatency() -> Completable
}

class LatencyViewModelImpl: LatencyViewModel {
    let latencyRepo: LatencyRepository
    let serverRepository: ServerRepository
    let staticIpRepository: StaticIpRepository

    init(latencyRepo: LatencyRepository, serverRepository: ServerRepository, staticIpRepository: StaticIpRepository) {
        self.latencyRepo = latencyRepo
        self.serverRepository = serverRepository
        self.staticIpRepository = staticIpRepository
    }

    func loadAllServerLatency() -> Completable {
        return updateServerList()
            .andThen(latencyRepo.loadAllServerLatency())
            .andThen(latencyRepo.loadStaticIpLatency().asCompletable())
            .andThen(latencyRepo.loadCustomConfigLatency())
    }

    private func updateServerList() -> Completable {
        return serverRepository.getUpdatedServers().flatMap { _ in
            self.staticIpRepository.getStaticServers()
        }.asCompletable()
    }
}
