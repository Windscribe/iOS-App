//
//  ConfirmEmailViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ConfirmEmailViewModel {
    var alertManager: AlertManager { get }
    var apiManager: APIManager { get }
}

class ConfirmEmailViewModelImpl: ConfirmEmailViewModel {
    var alertManager: AlertManager
    let apiManager: APIManager

    private var cancellables = Set<AnyCancellable>()

    init(alertManager: AlertManager,
         apiManager: APIManager) {
        self.alertManager = alertManager
        self.apiManager = apiManager
    }
}
