//
//  EnterEmailViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol EnterEmailViewModel {
    var alertManager: AlertManager { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var currentEmail: String? { get }
    func changeEmailAddress(email: String) -> AnyPublisher<APIMessage, Error>
}

class EnterEmailViewModelImpl: EnterEmailViewModel {
    let userSessionRepository: UserSessionRepository
    let alertManager: AlertManager
    let apiManager: APIManager
    let isDarkMode: CurrentValueSubject<Bool, Never>

    var currentEmail: String? {
        userSessionRepository.sessionModel?.email
    }

    init(userSessionRepository: UserSessionRepository,
         alertManager: AlertManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         apiManager: APIManager) {
        self.userSessionRepository = userSessionRepository
        self.alertManager = alertManager
        self.apiManager = apiManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject

    }

    func changeEmailAddress(email: String) -> AnyPublisher<APIMessage, Error> {
        return Future { [weak self] promise in
            Task { [weak self] in
                guard let self = self else {
                    promise(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let apiMessage = try await self.apiManager.addEmail(email: email)
                    promise(.success(apiMessage))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }
}
