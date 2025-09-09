//
//    AccountViewModel.swift
//    Windscribe
//
//    Created by Thomas on 20/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

enum ManageAccountState: Equatable {
    case initial
    case loading
    case error(String)
    case success
}

protocol AccountViewModelType {
    var apiCallManager: APIManager { get }
    var alertManager: AlertManagerV2 { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var cancelAccountState: BehaviorSubject<ManageAccountState> { get }
    var languageUpdatedTrigger: PublishSubject<Void> { get }
    var sessionUpdatedTrigger: PublishSubject<Void> { get }

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
    func verifyCodeEntered(code: String, success: (() -> Void)?, failure: ((String) -> Void)?)
    func verifyVoucherEntered(code: String, success: ((ClaimVoucherCodeResponse) -> Void)?, failure: ((String) -> Void)?)
    func updateSession()
}

class AccountViewModel: AccountViewModelType {
    let alertManager: AlertManagerV2
    let apiCallManager: APIManager
    let logger: FileLogger
    let sessionManager: SessionManaging
    let localDatabase: LocalDatabase

    var sections = [AccountSectionItem]()
    let disposeBag = DisposeBag()
    let isDarkMode: BehaviorSubject<Bool>
    let cancelAccountState = BehaviorSubject(value: ManageAccountState.initial)
    let languageUpdatedTrigger = PublishSubject<Void>()
    var sessionUpdatedTrigger = PublishSubject<Void>()
    let session = BehaviorSubject<Session?>(value: nil)

    init(apiCallManager: APIManager, alertManager: AlertManagerV2, lookAndFeelRepository: LookAndFeelRepositoryType, sessionManager: SessionManaging, logger: FileLogger, languageManager: LanguageManager, localDatabase: LocalDatabase) {
        self.apiCallManager = apiCallManager
        self.logger = logger
        self.sessionManager = sessionManager
        self.localDatabase = localDatabase
        self.alertManager = alertManager

        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        #if os(iOS)
            sections = [.info, .plan, .other]
        #else
            sections = [.info, .plan]
        #endif
        languageManager.activelanguage.subscribe { [weak self] _ in
            self?.languageUpdatedTrigger.onNext(())
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
        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiCallManager.confirmEmail()
                await MainActor.run {
                    success?()
                }
            } catch {
                await MainActor.run {
                    failure?(error.localizedDescription)
                }
            }
        }
    }

    func getWebSession(success: ((String) -> Void)?, failure: ((String) -> Void)?) {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                let session = try await self.apiCallManager.getWebSession()
                await MainActor.run {
                    let url = LinkProvider.getWindscribeLinkWithAutoLogin(
                        path: Links.acccount,
                        tempSession: session.tempSession
                    )
                    success?(url)
                }
            } catch {
                await MainActor.run {
                    failure?(error.localizedDescription)
                }
            }
        }
    }

    func cancelAccount(password: String) {
        cancelAccountState.onNext(.loading)
        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiCallManager.cancelAccount(password: password)
                await MainActor.run {
                    self.cancelAccountState.onNext(.success)
                }
            } catch {
                await MainActor.run {
                    switch error {
                    case Errors.validationFailure:
                        self.cancelAccountState.onNext(.error("Password is incorrect."))
                    case let Errors.apiError(e):
                        self.cancelAccountState.onNext(.error(e.errorMessage ?? ""))
                    default:
                        self.cancelAccountState.onNext(.error("Unable to reach server. Check your internet connection."))
                    }
                    self.logger.logE("AccountViewModel", error.localizedDescription)
                }
            }
        }
    }

    func loadSession() -> Single<Session> {
        return Single.create { single in
            let task = Task { [weak self] in
                guard let self = self else {
                    single(.failure(Errors.validationFailure))
                    return
                }

                do {
                    let session = try await self.apiCallManager.getSession(nil)
                    await MainActor.run {
                        self.localDatabase.saveOldSession()
                        self.localDatabase.saveSession(session: session).disposed(by: self.disposeBag)
                        let oldSession = self.localDatabase.getOldSession()
                        let sessionSync = self.localDatabase.getSessionSync()
                        if self.localDatabase.getOldSession() != self.localDatabase.getSessionSync() {
                            self.sessionUpdatedTrigger.onNext(())
                        }
                    }
                    single(.success(session))
                } catch {
                    await MainActor.run {
                        self.logger.logE("AccountViewModel", "Failed to get session from server with error \(error).")
                    }
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func logoutUser() {
        sessionManager.logoutUser()
    }

    func verifyCodeEntered(code: String, success: (() -> Void)?, failure: ((String) -> Void)?) {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiCallManager.verifyTvLoginCode(code: code)
                await MainActor.run {
                    success?()
                }
            } catch {
                await MainActor.run {
                    if let error = error as? Errors {
                        switch error {
                        case let .apiError(e):
                            failure?(e.errorMessage ?? "Failed to verify login code.")
                        default:
                            failure?("Failed to verify login code \(error.description)")
                        }
                    }
                }
            }
        }
    }

    func verifyVoucherEntered(code: String, success: ((ClaimVoucherCodeResponse) -> Void)?, failure: ((String) -> Void)?) {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                let response = try await self.apiCallManager.claimVoucherCode(code: code)
                await MainActor.run {
                    success?(response)
                }
            } catch {
                await MainActor.run {
                    if let error = error as? Errors {
                        switch error {
                        case let .apiError(e):
                            failure?(e.errorMessage ?? "Error applying Voucher Code: \(code)")
                        default:
                            failure?("Error applying Voucher Code: \(error.description)")
                        }
                    }
                }
            }
        }
    }

    func updateSession() {
        localDatabase.getSession().observe(on: MainScheduler.asyncInstance).subscribe(onNext: { [self] session in
            self.session.onNext(session)
        }, onError: { _ in }).disposed(by: disposeBag)
    }
}
