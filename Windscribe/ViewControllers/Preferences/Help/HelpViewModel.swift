//
//  HelpViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-04.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import RxSwift

protocol HelpViewModel {
    var isDarkMode: BehaviorSubject<Bool> {get}
    var sessionManager: SessionManagerV2 {get}
    var apiManager: APIManager {get}
    var alertManager: AlertManagerV2 {get}
    var networkStatus: NetworkStatus { get }
    func submitDebugLog(username: String?, completion: @escaping (_ result: Bool?, _ error: String?) -> Void)
}

class HelpViewModelImpl: HelpViewModel {
    var alertManager: AlertManagerV2
    var themeManager: ThemeManager
    var sessionManager: SessionManagerV2
    var apiManager: APIManager
    let connectivity: Connectivity

    let dispose = DisposeBag()
    let isDarkMode: BehaviorSubject<Bool>
    var networkStatus = NetworkStatus.disconnected
    let logger = Assembler.resolve(FileLogger.self)

    init(themeManager: ThemeManager, sessionManager: SessionManagerV2, apiManager: APIManager, alertManager: AlertManagerV2, connectivity: Connectivity) {
        self.themeManager = themeManager
        self.sessionManager = sessionManager
        self.apiManager = apiManager
        self.alertManager = alertManager
        self.connectivity = connectivity
        isDarkMode = themeManager.darkTheme
        observerConnectivity()
    }

    private func observerConnectivity() {
        connectivity.network.subscribe(onNext: { appNetwork in
            self.networkStatus = appNetwork.status
        }, onError: { _ in

        }).disposed(by: dispose)
    }

    func submitDebugLog(username: String? = nil, completion: @escaping (_ result: Bool?, _ error: String?) -> Void) {
        logger.getLogData().flatMap { fileData in
            var debugUsername = "user435"
            if let session = self.sessionManager.session {
                debugUsername = session.username
            }
            if username != nil {
                debugUsername = username ?? ""
            }
            if let session =  self.sessionManager.session, session.isUserGhost == true {
                debugUsername = "ghost_\(session.userId)"
            }
            return self.apiManager.sendDebugLog(username: debugUsername, log: fileData)
        }.subscribe(onSuccess: { _ in
            self.logger.logD(self, "Debug log submitted.")
            completion(true, nil)
        }, onFailure: { error in
            completion(false, error.localizedDescription)
        }).disposed(by: dispose)
    }

}
