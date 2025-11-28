//
//  ConfirmEmailViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

protocol ConfirmEmailViewModel {
    var alertManager: AlertManagerV2 { get }
    var apiManager: APIManager { get }
}

class ConfirmEmailViewModelImpl: ConfirmEmailViewModel {
    var alertManager: AlertManagerV2
    let apiManager: APIManager

    private var cancellables = Set<AnyCancellable>()

    init(alertManager: AlertManagerV2,
         apiManager: APIManager) {
        self.alertManager = alertManager
        self.apiManager = apiManager
    }
}
