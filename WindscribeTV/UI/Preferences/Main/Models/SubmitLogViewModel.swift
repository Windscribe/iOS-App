//
//  SubmitLogViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-04.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine
import Swinject

protocol SubmitLogViewModel {
    var alertManager: AlertManagerV2 { get }
    var networkStatus: NetworkStatus { get }
    func submitDebugLog(username: String?, completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
}

class SubmitLogViewModelImpl: SubmitLogViewModel {
    var alertManager: AlertManagerV2
    let sessionRepository: SessionRepository
    let apiManager: APIManager
    let connectivity: ConnectivityManager

    private var cancellables = Set<AnyCancellable>()
    var networkStatus = NetworkStatus.disconnected
    let logger = Assembler.resolve(FileLogger.self)

    init(sessionRepository: SessionRepository,
         apiManager: APIManager,
         alertManager: AlertManagerV2,
         connectivity: ConnectivityManager) {
        self.sessionRepository = sessionRepository
        self.apiManager = apiManager
        self.alertManager = alertManager
        self.connectivity = connectivity

        observerConnectivity()
    }

    private func observerConnectivity() {
        connectivity.network.sink { [weak self] appNetwork in
            guard let self = self else { return }
            self.networkStatus = appNetwork.status
        }.store(in: &cancellables)
    }

    func submitDebugLog(username: String? = nil, completion: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        Task {
            do {
                let logData = try await logger.getLogData()

                let username = await MainActor.run {
                    var username = sessionRepository.session?.username ?? ""
                    if let session = sessionRepository.session, session.isUserGhost {
                        username = "ghost_\(session.userId)"
                    }
                    return username
                }

                _ = try await apiManager.sendDebugLog(username: username, log: logData)

                await MainActor.run {
                    completion(true, nil)
                }
            } catch {
                await MainActor.run {
                    completion(false, error.localizedDescription)
                }
            }
        }
    }
}
