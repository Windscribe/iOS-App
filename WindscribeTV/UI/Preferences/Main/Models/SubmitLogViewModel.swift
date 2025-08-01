//
//  SubmitLogViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-04.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject

protocol SubmitLogViewModel {
    var sessionManager: SessionManaging { get }
    var apiManager: APIManager { get }
    var alertManager: AlertManagerV2 { get }
    var networkStatus: NetworkStatus { get }
    func submitDebugLog(username: String?, completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
}

class SubmitLogViewModelImpl: SubmitLogViewModel {
    var alertManager: AlertManagerV2
    var sessionManager: SessionManaging
    var apiManager: APIManager
    let connectivity: Connectivity

    let dispose = DisposeBag()
    var networkStatus = NetworkStatus.disconnected
    let logger = Assembler.resolve(FileLogger.self)

    init(sessionManager: SessionManaging, apiManager: APIManager, alertManager: AlertManagerV2, connectivity: Connectivity) {
        self.sessionManager = sessionManager
        self.apiManager = apiManager
        self.alertManager = alertManager
        self.connectivity = connectivity

        observerConnectivity()
    }

    private func observerConnectivity() {
        connectivity.network.subscribe(
            onNext: { [weak self] appNetwork in
                guard let self = self else { return }
                self.networkStatus = appNetwork.status
            },
            onError: { _ in})
        .disposed(by: dispose)
    }

    func submitDebugLog(username: String? = nil, completion: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        logger.getLogData()
            .subscribe(on: SerialDispatchQueueScheduler(qos: DispatchQoS.background))
            .observe(on: MainScheduler.asyncInstance)
            .flatMap { fileData in
            var debugUsername = ""
            if let session = self.sessionManager.session {
                debugUsername = session.username
            }
            if username != nil {
                debugUsername = username ?? ""
            }
            if let session = self.sessionManager.session, session.isUserGhost == true {
                debugUsername = "ghost_\(session.userId)"
            }
            return self.apiManager.sendDebugLog(username: debugUsername, log: fileData)
        }.subscribe(onSuccess: { _ in
            self.logger.logD("SubmitLogViewModelImpl", "Debug log submitted.")
            completion(true, nil)
        }, onFailure: { error in
            completion(false, error.localizedDescription)
        }).disposed(by: dispose)
    }
}
