//
//  LatencyViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-06-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol LatencyViewModel {
    var latencyUpdatedTrigger: PassthroughSubject<Void, Never> { get }

    func loadAllServerLatency(onAllServerCompletion: @escaping () -> Void,
                              onStaticCompletion: @escaping () -> Void,
                              onCustomConfigCompletion: @escaping () -> Void,
                              onExitCompletion: @escaping () -> Void)
}

class LatencyViewModelImpl: LatencyViewModel {
    let latencyRepo: LatencyRepository
    let locationListRepository: LocationListRepository
    let staticIpRepository: StaticIpRepository

    let latencyUpdatedTrigger: PassthroughSubject<Void, Never>

    init(latencyRepo: LatencyRepository, locationListRepository: LocationListRepository, staticIpRepository: StaticIpRepository) {
        self.latencyRepo = latencyRepo
        self.locationListRepository = locationListRepository
        self.staticIpRepository = staticIpRepository

        latencyUpdatedTrigger = latencyRepo.latencyUpdatedTrigger
    }

    func loadAllServerLatency(onAllServerCompletion: @escaping () -> Void,
                              onStaticCompletion: @escaping () -> Void,
                              onCustomConfigCompletion: @escaping () -> Void,
                              onExitCompletion: @escaping () -> Void) {
        Task {
            _ = try? await updateServerList()

            await latencyRepo.loadStaticIpLatency()
            onStaticCompletion()

            try await latencyRepo.loadLatency()
            onAllServerCompletion()

            await latencyRepo.loadCustomConfigLatency()
            onCustomConfigCompletion()

            onExitCompletion()
        }
    }

    private func updateServerList() async throws -> [StaticIPModel] {
        try await staticIpRepository.updateStaticServers()
        return staticIpRepository.staticIPs
    }

}
