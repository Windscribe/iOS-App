//
//    AccountViewModel.swift
//    Windscribe
//
//    Created by Thomas on 20/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
enum ManageAccountState {
    case initial
    case loading
    case error(String)
    case success
}
protocol AccountViewModelType {
    var apiCallManager: APIManager {get}
    var alertManager: AlertManagerV2 {get}
    var isDarkMode: BehaviorSubject<Bool> {get}
    var cancelAccountState: BehaviorSubject<ManageAccountState> {get}

    func titleForHeader(in section: Int) -> String
    func numberOfSections() -> Int
    func numberOfRowsInSection(in section: Int) -> Int
    func celldata(at indexPath: IndexPath) -> AccountItemCell
    func resendConfirmEmail(success: (() -> Void)?, failure: ((String) -> Void)?)
    func getWebSession(success: ((String) -> Void)?, failure: ((String) -> Void)?)
    func loadSession() -> Single<Session>
    func cancelAccount(password: String)
    func logoutUser()
}

class AccountViewModel: AccountViewModelType {
    let alertManager: AlertManagerV2
    let apiCallManager: APIManager
    let logger: FileLogger
    let sessionManager: SessionManagerV2
    var sections = [AccountSectionItem]()
    let disposeBag = DisposeBag()
    let isDarkMode: BehaviorSubject<Bool>
    let cancelAccountState = BehaviorSubject(value: ManageAccountState.initial)

    init(apiCallManager: APIManager, alertManager: AlertManagerV2, themeManager: ThemeManager, sessionManager: SessionManagerV2, logger: FileLogger) {
        self.apiCallManager = apiCallManager
        self.logger = logger
        self.sessionManager = sessionManager
        sections = [.info, .plan]
        self.alertManager = alertManager
        isDarkMode = themeManager.darkTheme
    }

    func numberOfRowsInSection(in section: Int) -> Int {
        return sections[section].items.count
    }

    func numberOfSections() -> Int {
        return sections.count
    }

    func celldata(at indexPath: IndexPath) -> AccountItemCell {
        let data = sections[indexPath.section].items[indexPath.row]
        return data
    }

    func titleForHeader(in section: Int) -> String {
        return sections[section].title
    }

    func resendConfirmEmail(success: (() -> Void)?, failure: ((String) -> Void)?) {
        apiCallManager.confirmEmail().subscribe(onSuccess: { _ in
            success?()

        }, onFailure: { error in
            failure?(error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    func getWebSession(success: ((String) -> Void)?, failure: ((String) -> Void)?) {
        apiCallManager.getWebSession().subscribe(onSuccess: { session in
            let url = LinkProvider.getWindscribeLinkWithAutoLogin(
                path: Links.acccount,
                tempSession: session.tempSession
            )
            success?(url)
        }, onFailure: { error in
            failure?(error.localizedDescription)
        }).disposed(by: disposeBag)

    }

    func cancelAccount(password: String) {
        cancelAccountState.onNext(.loading)
        apiCallManager.cancelAccount(password: password).subscribe(onSuccess: { _ in
            self.cancelAccountState.onNext(.success)
        }, onFailure: { error in
            switch error {
                case Errors.validationFailure:
                    self.cancelAccountState.onNext(.error("Password is incorrect."))
                case Errors.apiError(let e):
                    self.cancelAccountState.onNext(.error(e.errorMessage ?? ""))
                default:
                    self.cancelAccountState.onNext(.error("Unable to reach server. Check your internet connection."))
            }
            self.logger.logE(self, error.localizedDescription)
        }).disposed(by: disposeBag)
    }

    func loadSession() -> Single<Session> {
        return apiCallManager.getSession()
    }

    func logoutUser() {
        sessionManager.logoutUser()
    }
}
