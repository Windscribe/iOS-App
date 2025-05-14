//
//  AdvanceParamsViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-12.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol AdvanceParamsViewModel {
    var titleText: BehaviorSubject<String> { get }
    var advanceParams: BehaviorSubject<String?> { get }
    var showProgressBar: BehaviorSubject<Bool> { get }
    var showError: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    func saveButtonTap()
    func onAdvanceParamsTextChange(text: String?)
}

class AdvanceParamsViewModelImpl: AdvanceParamsViewModel {
    // MARK: - Dependencies

    private var preferences: Preferences
    private var apiManager: APIManager

    // MARK: - State

    private let disposeBag = DisposeBag()
    let titleText = BehaviorSubject<String>(value: TextsAsset.Preferences.advanceParameters)
    let advanceParams = BehaviorSubject<String?>(value: nil)
    let showProgressBar = BehaviorSubject(value: false)
    let showError = BehaviorSubject<Bool>(value: false)
    let isDarkMode: BehaviorSubject<Bool>

    // MARK: - Data

    init(preferences: Preferences, apiManager: APIManager, lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.preferences = preferences
        self.apiManager = apiManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        load()
    }

    private func load() {
        preferences.getAdvanceParams().subscribe { data in
            self.advanceParams.onNext(data)
        }.disposed(by: disposeBag)
    }

    // MARK: - Actions

    func saveButtonTap() {
        showProgressBar.onNext(true)
        parseAdvanceParams()
            .delaySubscription(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .map { self.preferences.saveAdvanceParams(params: $0) }
            .subscribe(onSuccess: {
                self.showProgressBar.onNext(false)
            }, onFailure: { error in
                self.showProgressBar.onNext(false)
                if let error = error as? AdvanceParamsErrors {
                    switch error {
                    case .invalidKeyValuePair:
                        self.showError.onNext(true)
                    }
                }
            }).disposed(by: disposeBag)
    }

    func onAdvanceParamsTextChange(text: String?) {
        showError.onNext(false)
        advanceParams.onNext(text)
    }

    private func parseAdvanceParams() -> Single<String> {
        do {
            if let text = try advanceParams.value() {
                let lines = text.splitToArray(separator: "\n")
                for value in lines {
                    if !value.contains("=") || value.splitToArray(separator: "=").count != 2 {
                        return Single.error(AdvanceParamsErrors.invalidKeyValuePair)
                    }
                }
                return Single.just(text)
            }
            return Single.just("")
        } catch {
            return Single.error(error)
        }
    }
}
