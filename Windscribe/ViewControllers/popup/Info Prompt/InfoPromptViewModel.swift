//
//  InfoPromptViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 18/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol InfoPromptViewDelegate: AnyObject {
    func dismissWith(actionTaken: Bool, dismiss: Bool)
}

protocol InfoPromptViewModelType {
    var title: BehaviorSubject<String> { get }
    var actionValue: BehaviorSubject<String> { get }
    func action()
    func cancel()
    func setInfo(title: String,
                 actionValue: String,
                 justDismissOnAction: Bool,
                 delegate: InfoPromptViewDelegate?)
}

class InfoPromptViewModel: InfoPromptViewModelType {
    weak var delegate: InfoPromptViewDelegate?
    var justDismissOnAction = false

    let actionValue = BehaviorSubject<String>(value: "")
    let title = BehaviorSubject<String>(value: "")

    func setInfo(title: String, actionValue: String, justDismissOnAction: Bool, delegate: InfoPromptViewDelegate?) {
        self.justDismissOnAction = justDismissOnAction
        self.delegate = delegate
        self.title.onNext(title)
        self.actionValue.onNext(actionValue)
    }

    func action() {
        delegate?.dismissWith(actionTaken: !justDismissOnAction, dismiss: justDismissOnAction)
    }

    func cancel() {
        delegate?.dismissWith(actionTaken: false, dismiss: false)
    }
}
