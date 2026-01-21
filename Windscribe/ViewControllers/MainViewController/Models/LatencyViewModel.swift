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
    func loadAllServerLatency(onAllServerCompletion: @escaping () -> Void,
                              onStaticCompletion: @escaping () -> Void,
                              onCustomConfigCompletion: @escaping () -> Void,
                              onExitCompletion: @escaping () -> Void)
}

class LatencyViewModelImpl: LatencyViewModel {
    let latencyRepo: LatencyRepository
    let serverRepository: ServerRepository
    let staticIpRepository: StaticIpRepository

    let disposeBag = DisposeBag()

    init(latencyRepo: LatencyRepository, serverRepository: ServerRepository, staticIpRepository: StaticIpRepository) {
        self.latencyRepo = latencyRepo
        self.serverRepository = serverRepository
        self.staticIpRepository = staticIpRepository
    }

    func loadAllServerLatency(onAllServerCompletion: @escaping () -> Void,
                              onStaticCompletion: @escaping () -> Void,
                              onCustomConfigCompletion: @escaping () -> Void,
                              onExitCompletion: @escaping () -> Void) {
        Task {
            _ = try? await updateServerList()

            await latencyRepo.loadStaticIpLatency()
            onStaticCompletion()
            onExitCompletion()

            try await latencyRepo.loadLatency()
            onAllServerCompletion()
            onExitCompletion()

            await latencyRepo.loadCustomConfigLatency()
            onCustomConfigCompletion()
            onExitCompletion()
        }
    }

    private func updateServerList() async throws -> [StaticIPModel] {
        try await serverRepository.updatedServers()
        try await staticIpRepository.updateStaticServers()
        return staticIpRepository.staticIPs
    }

}
