//
//  EnterEmailViewModelOld.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol EnterEmailViewModelOld {
    var alertManager: AlertManagerV2 { get }
    var sessionManager: SessionManagerV2 { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var currentEmail: String? { get }
    func changeEmailAddress(email: String) -> Single<APIMessage>
}

class EnterEmailViewModelImplOld: EnterEmailViewModelOld {
    let sessionManager: SessionManagerV2
    let alertManager: AlertManagerV2
    let apiManager: APIManager
    let isDarkMode: BehaviorSubject<Bool>

    var currentEmail: String? {
        sessionManager.session?.email
    }

    init(sessionManager: SessionManagerV2, alertManager: AlertManagerV2, lookAndFeelRepo: LookAndFeelRepositoryType, apiManager: APIManager) {
        self.sessionManager = sessionManager
        self.alertManager = alertManager
        self.apiManager = apiManager
        isDarkMode = lookAndFeelRepo.isDarkModeSubject
    }

    func changeEmailAddress(email: String) -> Single<APIMessage> {
        return apiManager.addEmail(email: email).map { apimessage in
            apimessage
        }.catch { error in
            Single.error(error)
        }
    }
}
