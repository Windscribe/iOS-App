//
//  ViewLogViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-25.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ViewLogViewModel {
    var title: String { get }
    var logContent: BehaviorSubject<String> { get }
    var showProgress: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
}

class ViewLogViewModelImpl: ViewLogViewModel {
    let title = TextsAsset.Debug.viewLog
    let logContent = BehaviorSubject(value: "")
    let showProgress = BehaviorSubject(value: false)
    let isDarkMode: BehaviorSubject<Bool>
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    init(logger: FileLogger, themeManager: ThemeManager) {
        self.logger = logger
        isDarkMode = themeManager.darkTheme
        load()
    }

    private func load() {
        showProgress.onNext(true)
        logger.getLogData().subscribe(onSuccess: { [weak self] content in
            guard let self = self else { return }
            self.showProgress.onNext(false)
            self.logContent.onNext(content)
        }, onFailure: { [weak self] _ in
            self?.showProgress.onNext(false)
        }).disposed(by: disposeBag)
    }
}
