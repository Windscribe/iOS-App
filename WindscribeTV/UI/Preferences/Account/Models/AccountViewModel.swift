//
//    AccountViewModel.swift
//    Windscribe
//
//    Created by Thomas on 20/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Combine
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
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var cancelAccountState: BehaviorSubject<ManageAccountState> { get }
    var languageUpdatedTrigger: PublishSubject<Void> { get }
    var sessionUpdatedTrigger: PublishSubject<Void> { get }

    func titleForHeader(in section: Int) -> String
    func numberOfSections() -> Int
    func numberOfRowsInSection(in section: Int) -> Int
    func celldata(at indexPath: IndexPath) -> AccountItemCell
    func resendConfirmEmail(success: (() -> Void)?, failure: ((String) -> Void)?)
    func getWebSession(success: ((String) -> Void)?, failure: ((String) -> Void)?)
    func loadSession()
    func cancelAccount(password: String)
    func logoutUser()
    func getSections() -> [AccountSectionItem]
    func verifyCodeEntered(code: String, success: (() -> Void)?, failure: ((String) -> Void)?)
    func verifyVoucherEntered(code: String, success: ((ClaimVoucherCodeResponse) -> Void)?, failure: ((String) -> Void)?)
}

class AccountViewModel: AccountViewModelType {
    let alertManager: AlertManagerV2
    let apiCallManager: APIManager
    let logger: FileLogger
    let sessionManager: SessionManager
    let localDatabase: LocalDatabase
    let userSessionRepository: UserSessionRepository

    var sections = [AccountSectionItem]()
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let cancelAccountState = BehaviorSubject(value: ManageAccountState.initial)
    let languageUpdatedTrigger = PublishSubject<Void>()
    var sessionUpdatedTrigger = PublishSubject<Void>()

    init(apiCallManager: APIManager,
         alertManager: AlertManagerV2,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         sessionManager: SessionManager,
         logger: FileLogger,
         languageManager: LanguageManager,
         localDatabase: LocalDatabase,
         userSessionRepository: UserSessionRepository) {
        self.apiCallManager = apiCallManager
        self.logger = logger
        self.sessionManager = sessionManager
        self.localDatabase = localDatabase
        self.alertManager = alertManager
        self.userSessionRepository = userSessionRepository

        isDarkMode = lookAndFeelRepository.isDarkModeSubject
#if os(iOS)
        sections = [.info, .plan, .other]
#else
        sections = [.info, .plan]
#endif
        languageManager.activelanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.languageUpdatedTrigger.onNext(())
            }.store(in: &cancellables)
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

    func loadSession() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                try await sessionManager.updateSession()
                await MainActor.run {
                    let oldSession = self.userSessionRepository.oldSessionModel
                    let sessionSync = self.userSessionRepository.sessionModel
                    if oldSession != sessionSync {
                        self.sessionUpdatedTrigger.onNext(())
                    }
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("AccountViewModel", "Failed to get session from server with error \(error).")
                }
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
}
