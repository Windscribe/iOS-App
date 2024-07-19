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
    var sessionManager: SessionManagerV2 {get}
    var localDatabase: LocalDatabase {get}
    var apiManager: APIManager {get}
    func getSession()
}

class ConfirmEmailViewModelImpl: ConfirmEmailViewModel {

    var alertManager: AlertManagerV2
    var localDatabase: LocalDatabase
    var sessionManager: SessionManagerV2
    let disposeBag = DisposeBag()
    var apiManager: APIManager
    let session = BehaviorSubject<Session?>(value: nil)

    init(alertManager: AlertManagerV2, sessionManager: SessionManagerV2, localDatabase: LocalDatabase, apiManager: APIManager) {
        self.alertManager = alertManager
        self.sessionManager = sessionManager
        self.localDatabase = localDatabase
        self.apiManager = apiManager
        getSession()
    }

    func getSession() {
        localDatabase.getSession().subscribe(onNext: { [self] session in
            self.session.onNext(session)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

}
