//
//  ConfirmEmailViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ConfirmEmailViewModel {
    var alertManager: AlertManagerV2 { get }
    var sessionRepository: SessionRepository { get }
    var localDatabase: LocalDatabase { get }
    var apiManager: APIManager { get }
    func getSession()
    func updateSession()
}

class ConfirmEmailViewModelImpl: ConfirmEmailViewModel {
    var alertManager: AlertManagerV2
    let localDatabase: LocalDatabase
    var sessionRepository: SessionRepository
    let disposeBag = DisposeBag()
    let apiManager: APIManager
    let session = BehaviorSubject<Session?>(value: nil)

    init(alertManager: AlertManagerV2,
         sessionRepository: SessionRepository,
         localDatabase: LocalDatabase,
         apiManager: APIManager) {
        self.alertManager = alertManager
        self.sessionRepository = sessionRepository
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        getSession()
    }

    func getSession() {
        localDatabase.getSession().subscribe(onNext: { [self] session in
            self.session.onNext(session)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func updateSession() {
        sessionRepository.keepSessionUpdated()
    }
}
