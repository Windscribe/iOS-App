//
//  EnterEmailViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol EnterEmailViewModel {
    var alertManager: AlertManagerV2 { get }
    var sessionManager: SessionManaging { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var currentEmail: String? { get }
    func changeEmailAddress(email: String) -> Single<APIMessage>
}

class EnterEmailViewModelImpl: EnterEmailViewModel {
    let sessionManager: SessionManaging
    let alertManager: AlertManagerV2
    let apiManager: APIManager
    let isDarkMode: BehaviorSubject<Bool>

    var currentEmail: String? {
        sessionManager.session?.email
    }

    init(sessionManager: SessionManaging, alertManager: AlertManagerV2, lookAndFeelRepository: LookAndFeelRepositoryType, apiManager: APIManager) {
        self.sessionManager = sessionManager
        self.alertManager = alertManager
        self.apiManager = apiManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject

    }

    func changeEmailAddress(email: String) -> Single<APIMessage> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let apiMessage = try await self.apiManager.addEmail(email: email)
                    single(.success(apiMessage))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }
}
