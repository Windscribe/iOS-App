//
//  RobertViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 17/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol RobertViewModelType {
    var alertManager: AlertManagerV2 { get }
    var updadeinProgress: BehaviorSubject<Bool> { get }
    var robertFilters: BehaviorSubject<[RobertFilter]?> { get }
    var showProgress: BehaviorSubject<Bool> { get }
    var showError: BehaviorSubject<String?> { get }
    var urlToOpen: BehaviorSubject<URL?> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    func loadRobertFilters()
    func handleCustomRulesTap()
    func handleLearnMoreTap()
    func ruleUpdateTapped(number: Int)
}

class RobertViewModel: RobertViewModelType {
    var apiManager: APIManager
    var localDB: LocalDatabase
    var alertManager: AlertManagerV2
    var logger: FileLogger
    var updadeinProgress: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    var robertFilters: BehaviorSubject<[RobertFilter]?> = BehaviorSubject(value: nil)
    let showProgress: BehaviorSubject<Bool> = BehaviorSubject(value: false)
    var showError: BehaviorSubject<String?> = BehaviorSubject(value: nil)
    var urlToOpen: BehaviorSubject<URL?> = BehaviorSubject(value: nil)
    let isDarkMode: BehaviorSubject<Bool>

    let disposeBag = DisposeBag()

    init(apiManager: APIManager, localDB: LocalDatabase, themeManager: ThemeManager, alertManager: AlertManagerV2, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDB = localDB
        self.alertManager = alertManager
        self.logger = logger
        isDarkMode = themeManager.darkTheme
    }

    func loadRobertFilters() {
        showProgress.onNext(true)
        apiManager.getRobertFilters().observe(on: MainScheduler.instance).subscribe(onSuccess: { [self] robertFilters in
            showProgress.onNext(false)
            localDB.saveRobertFilters(filters: robertFilters).disposed(by: self.disposeBag)
            DispatchQueue.main.async {
                self.localDB.saveRobertFilters(filters: robertFilters).disposed(by: self.disposeBag)
                self.robertFilters.onNext(robertFilters.getRules())
            }
        }, onFailure: { [weak self] _ in
            self?.showProgress.onNext(false)
            guard let robertFilters = self?.localDB.getRobertFilters() else {
                self?.showError.onNext("Unable to load robert rules. Check your network connection.")
                return
            }
            self?.robertFilters.onNext(robertFilters.getRules())
        }).disposed(by: disposeBag)
    }

    func handleCustomRulesTap() {
        logger.logE(self, "User tapped custom rules button.")
        showProgress.onNext(true)
        apiManager.getWebSession().observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] webSession in
                self?.showProgress.onNext(false)
                let url = LinkProvider.getRobertRulesUrl(session: webSession.tempSession)
                if let roberRulesUrl = url {
                    self?.urlToOpen.onNext(roberRulesUrl)
                }
            }, onFailure: { [weak self] error in
                self?.showProgress.onNext(false)
                if let error = error as? Errors {
                    switch error {
                    case let .apiError(e):
                        self?.showError.onNext(e.errorMessage ?? "Failed to update Robert Setting.")
                    default:
                        self?.showError.onNext("Failed to update Robert Setting. \(error.description)")
                    }
                }
            }).disposed(by: disposeBag)
    }

    func handleLearnMoreTap() {
        if let url = URL(string: LinkProvider.getWindscribeLink(path: Links.learMoreAboutRobert)) {
            urlToOpen.onNext(url)
        }
    }

    func ruleUpdateTapped(number: Int) {
        updadeinProgress.onNext(true)
        let rowNumber = number
        guard let changedFilter = try? robertFilters.value()?[rowNumber] else {
            updadeinProgress.onNext(false)
            return
        }

        showProgress.onNext(true)
        var status: Int32 = 0
        if changedFilter.enabled {
            status = 0
        } else {
            status = 1
        }
        apiManager.updateRobertSettings(id: changedFilter.id, status: status).subscribe(onSuccess: { [self] _ in
            DispatchQueue.main.async {
                self.showProgress.onNext(false)
                self.updadeinProgress.onNext(false)
                self.localDB.toggleRobertRule(id: changedFilter.id)
                guard let robertFilters = self.localDB.getRobertFilters() else {
                    self.showError.onNext("Unable to load robert rules. Check your network connection.")
                    return
                }
                self.robertFilters.onNext(robertFilters.getRules())
                self.apiManager.syncRobertFilters().subscribe(onSuccess: { _ in }).disposed(by: self.disposeBag)
            }
        }, onFailure: { [weak self] error in
            DispatchQueue.main.async {
                self?.showProgress.onNext(false)
                self?.updadeinProgress.onNext(false)
                if let error = error as? Errors {
                    switch error {
                    case let .apiError(e):
                        self?.showError.onNext(e.errorMessage ?? "Failed to update Robert Setting.")
                    default:
                        self?.showError.onNext("Failed to update Robert Setting. \(error.description)")
                    }
                }
            }
        }).disposed(by: disposeBag)
    }
}
