//
//  ErrorPopupViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ErrorPopupViewModelType {
    var message: BehaviorSubject<String> {get}
    var dismissAction: (() -> Void)? {get}
    func setMessage(with message: String)
    func setDismissAction(with dismissAction: (() -> Void)?)
}

class ErrorPopupViewModel: ErrorPopupViewModelType {
    var message = BehaviorSubject<String>(value: "")
    var dismissAction: (() -> Void)?

    func setMessage(with message: String) {
        self.message.onNext(message)
    }

    func setDismissAction(with dismissAction: (() -> Void)?) {
        self.dismissAction = dismissAction
    }
}
