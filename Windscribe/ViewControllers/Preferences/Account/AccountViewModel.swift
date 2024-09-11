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
    var languageUpdatedTrigger: PublishSubject<()> { get }
    var sessionUpdatedTrigger: PublishSubject<()> { get }

    func titleForHeader(in section: Int) -> String
    func numberOfSections() -> Int
    func numberOfRowsInSection(in section: Int) -> Int
    func celldata(at indexPath: IndexPath) -> AccountItemCell
    func resendConfirmEmail(success: (() -> Void)?, failure: ((String) -> Void)?)
    func getWebSession(success: ((String) -> Void)?, failure: ((String) -> Void)?)
    func loadSession() -> Single<Session>
    func cancelAccount(password: String)
    func logoutUser()
    func getSections() -> [AccountSectionItem]
}

class AccountViewModel: AccountViewModelType {
    let alertManager: AlertManagerV2
    let apiCallManager: APIManager
    let logger: FileLogger
    let sessionManager: SessionManagerV2
    let localDatabase: LocalDatabase

    var sections = [AccountSectionItem]()
    let disposeBag = DisposeBag()
    let isDarkMode: BehaviorSubject<Bool>
    let cancelAccountState = BehaviorSubject(value: ManageAccountState.initial)
    let languageUpdatedTrigger = PublishSubject<()>()
    var sessionUpdatedTrigger = PublishSubject<()>()

    init(apiCallManager: APIManager, alertManager: AlertManagerV2, themeManager: ThemeManager, sessionManager: SessionManagerV2, logger: FileLogger, languageManager: LanguageManagerV2, localDatabase: LocalDatabase) {
        self.apiCallManager = apiCallManager
        self.logger = logger
        self.sessionManager = sessionManager
        self.localDatabase = localDatabase
        self.alertManager = alertManager

        isDarkMode = themeManager.darkTheme
        sections = [.info, .plan]
        languageManager.activelanguage.subscribe { _ in
            self.languageUpdatedTrigger.onNext(())
        }.disposed(by: disposeBag)
    }

    func getSections() -> [AccountSectionItem] {
        return sections
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
        let sessionSingle = apiCallManager.getSession(nil)
        sessionSingle.observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { [self] session in
            localDatabase.saveOldSession()
            localDatabase.saveSession(session: session).disposed(by: disposeBag)
            if localDatabase.getOldSession() != localDatabase.getSessionSync() {
                sessionUpdatedTrigger.onNext(())
            }
        }, onFailure: { [self] error in
            logger.logE(self, "Failed to get session from server with error \(error).")
        }).disposed(by: disposeBag)
        return sessionSingle
    }

    func logoutUser() {
        sessionManager.logoutUser()
    }
}
