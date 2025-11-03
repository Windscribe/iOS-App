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
        Task { @MainActor in
            _ = try? await updateServerList()
            self.latencyRepo.loadStaticIpLatency()
                .asCompletable()
                .observe(on: MainScheduler.asyncInstance)
                .subscribe(onCompleted: {
                    onStaticCompletion()
                    onExitCompletion()
                }, onError: { _ in
                    onExitCompletion()
                })
                .disposed(by: self.disposeBag)
            self.latencyRepo.loadAllServerLatency()
                .observe(on: MainScheduler.asyncInstance)
                .subscribe(onCompleted: {
                    onAllServerCompletion()
                    onExitCompletion()
                }, onError: { _ in
                    onExitCompletion()
                })
                .disposed(by: self.disposeBag)

            self.latencyRepo.loadCustomConfigLatency()
                .observe(on: MainScheduler.asyncInstance)
                .subscribe(onCompleted: {
                    onCustomConfigCompletion()
                    onExitCompletion()
                }, onError: { _ in
                    onExitCompletion()
                })
                .disposed(by: self.disposeBag)

            onExitCompletion()
        }
    }

    private func updateServerList() async throws-> [StaticIP] {
        _ = try await serverRepository.getUpdatedServers()
        return try await self.staticIpRepository.getStaticServers().value
    }

}
