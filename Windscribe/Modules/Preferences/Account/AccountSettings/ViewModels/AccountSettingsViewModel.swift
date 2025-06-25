//
//  AccountSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import RxSwift

protocol AccountSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get }
    var sections: [AccountSectionModel] { get }
    var loadingState: AccountState { get }

    func loadSession()
    func handleRowAction(_ action: AccountRowAction)
}

final class AccountSettingsViewModelImpl: AccountSettingsViewModel {

    @Published var isDarkMode: Bool = false
    @Published var sections: [AccountSectionModel] = []
    @Published var loadingState: AccountState = .initial
    @Published var activeDialog: AccountDialogType?
    @Published var alertMessage: AccountSettingsAlertContent?
    @Published private(set) var accountEmailStatus: AccountEmailStatusType = .missing

    private var cancellables = Set<AnyCancellable>()
    private var currentSession: Session?

    // Dependencies
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let preferences: Preferences
    private let sessionManager: SessionManaging
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let languageManager: LanguageManager
    private let logger: FileLogger

    private let disposeBag = DisposeBag()

    var shouldShowAddEmailButton: Bool {
        guard currentSession?.isInvalidated == false else {
            return false
        }
        return currentSession?.email.isEmpty == true
    }

    var shouldShowPlanActionButtons: Bool {
        accountEmailStatus == .missing || accountEmailStatus == .unverified
    }

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         preferences: Preferences,
         sessionManager: SessionManaging,
         apiManager: APIManager,
         localDatabase: LocalDatabase,
         languageManager: LanguageManager,
         logger: FileLogger) {
        self.lookAndFeelRepository = lookAndFeelRepository
        self.preferences = preferences
        self.sessionManager = sessionManager
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.languageManager = languageManager
        self.logger = logger

        bindSubjects()
    }

    private func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("AccountViewModel", "Theme Adjustment Change: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)

        NotificationCenter.default.publisher(for: Notifications.sessionUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, let updatedSession = self.sessionManager.session else { return }
                self.currentSession = updatedSession
                self.buildSections(from: updatedSession)
                self.accountEmailStatus = self.calculateEmailStatus(from: updatedSession)
            }
            .store(in: &cancellables)
    }

    func loadSession() {
        loadingState = .loading(isFullScreen: true)

        apiManager.getSession(nil)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    guard let session = localDatabase.getSessionSync() else {
                        self.loadingState = .error(error.localizedDescription)
                        self.logger.logE("AccountViewModel", "Failed to load session: \(error)")
                        return
                    }
                    self.currentSession = session
                    self.buildSections(from: session)
                    self.loadingState = .success

                }
            }, receiveValue: { [weak self] session in
                guard let self = self else { return }
                self.currentSession = session
                self.accountEmailStatus = self.calculateEmailStatus(from: session)
                self.buildSections(from: session)
                self.loadingState = .success
                self.localDatabase.saveSession(session: session).disposed(by: disposeBag)
            })
            .store(in: &cancellables)
    }

    private func buildSections(from session: Session) {
        var infoRows: [AccountRowModel] = [
            .init(
                type: .textRow(
                    title: TextsAsset.Authentication.username,
                    value: session.username
                ),
                action: nil
            )
        ]

        if session.email.isEmpty {
            infoRows.append(.init(
                type: .textRow(
                    title: TextsAsset.email,
                    value: TextsAsset.General.none
                ),
                action: nil
            ))

        } else if !session.emailStatus {
            infoRows.append(.init(
                type: .confirmEmail(
                    email: session.email
                ),
                action: nil
            ))
        } else {
            infoRows.append(.init(
                type: .textRow(
                    title: TextsAsset.email,
                    value: session.email
                ),
                action: nil
            ))
        }

        var planRows: [AccountRowModel] = []

        planRows.append(.init(
            type: .textRow(
                title: session.isUserPro
                    ? TextsAsset.UpgradeView.unlimitedData
                    : "\(session.getDataMax())/\(TextsAsset.UpgradeView.month)",
                value: session.isUserPro
                    ? (session.billingPlanId == -9 ? TextsAsset.unlimited : TextsAsset.pro)
                    : TextsAsset.Account.freeAccountDescription
            ),
            action: nil
        ))

        planRows.append(.init(
            type: .textRow(
                title: session.isPremium ? TextsAsset.Account.expiryDate : TextsAsset.Account.resetDate,
                value: session.isPremium ? session.premiumExpiryDate : session.getNextReset()
            ),
            action: nil
        ))

        if !session.isUserPro {
            planRows.append(.init(
                type: .textRow(title: TextsAsset.Account.dataLeft, value: session.getDataLeft()),
                action: nil
            ))
        }

        let otherRows: [AccountRowModel] = [
            .init(type: .navigation(title: TextsAsset.voucherCode,
                                    subtitle: TextsAsset.Account.voucherCodeDescription),
                  action: .openVoucher),
            .init(type: .navigation(title: TextsAsset.Account.lazyLogin,
                                    subtitle: TextsAsset.Account.lazyLoginDescription),
                  action: .openLazyLogin)
        ]

        sections = [
            .init(type: .info, items: infoRows)
        ]

        sections.append(.init(type: .plan, items: planRows))
        sections.append(.init(type: .other, items: otherRows))
    }

    func handleRowAction(_ action: AccountRowAction) {
        if action == .resendEmail {
            resendConfirmationEmail()
        }
    }

    private func resendConfirmationEmail() {
        loadingState = .loading(isFullScreen: false)

        apiManager.confirmEmail()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.loadingState = .error(error.localizedDescription)
                    self?.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.ConfirmationEmailSentAlert.title,
                        message: error.localizedDescription,
                        buttonText: TextsAsset.okay
                    )
                }
            }, receiveValue: { [weak self] _ in
                self?.loadingState = .success
                self?.alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.ConfirmationEmailSentAlert.title,
                    message: TextsAsset.ConfirmationEmailSentAlert.message,
                    buttonText: TextsAsset.okay
                )
            })
            .store(in: &cancellables)
    }

    func confirmCancelAccount(password: String) {
        loadingState = .loading(isFullScreen: false)
        apiManager.cancelAccount(password: password)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                switch completion {
                case .failure(let error):
                    guard let self = self else { return }

                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.error,
                        message: self.fetchErrorMessage(from: error),
                        buttonText: TextsAsset.okay)
                case .finished:
                    break
                }
            }, receiveValue: { [weak self] _ in
                self?.loadingState = .success
                self?.logoutUser()
            })
            .store(in: &cancellables)
    }

    func verifyLazyLogin(code: String) {
        loadingState = .loading(isFullScreen: false)

        apiManager.verifyTvLoginCode(code: code)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                if case let .failure(error) = completion {
                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.error,
                        message: self.fetchErrorMessage(from: error),
                        buttonText: TextsAsset.okay)
                }
            }, receiveValue: { [weak self] _ in
                self?.loadingState = .success
                self?.alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.Account.lazyLogin,
                    message: TextsAsset.Account.lazyLoginSuccess,
                    buttonText: TextsAsset.okay)
            })
            .store(in: &cancellables)
    }

    func verifyVoucher(code: String) {
        loadingState = .loading(isFullScreen: false)

        apiManager.claimVoucherCode(code: code)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    guard let self = self else { return }

                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.voucherCode,
                        message: self.fetchErrorMessage(from: error),
                        buttonText: TextsAsset.okay)
                }
            }, receiveValue: { [weak self] response in
                guard let self else { return }

                self.loadingState = .success
                if response.isClaimed {
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.voucherCode,
                        message: TextsAsset.Account.voucherCodeSuccessful,
                        buttonText: TextsAsset.okay)
                    self.loadSession()
                } else if response.emailRequired == true {
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.voucherCode,
                        message: TextsAsset.Account.emailRequired,
                        buttonText: TextsAsset.okay)
                } else if response.isUsed {
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.voucherCode,
                        message: TextsAsset.Account.voucherUsedMessage,
                        buttonText: TextsAsset.okay)
                } else {
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.voucherCode,
                        message: TextsAsset.Account.invalidVoucherCode,
                        buttonText: TextsAsset.okay)
                }
            })
            .store(in: &cancellables)
    }

    private func calculateEmailStatus(from session: Session) -> AccountEmailStatusType {
        if session.email.isEmpty {
            return .missing
        } else if !session.emailStatus {
            return .unverified
        } else {
            return .verified
        }
    }

    private func logoutUser() {
        sessionManager.logoutUser()
    }

    private func fetchErrorMessage(from error: Error) -> String {
        let errorMessage: String

        if case let Errors.apiError(apiError) = error {
            errorMessage = apiError.errorMessage ?? TextsAsset.unknownAPIError
        } else {
            errorMessage = error.localizedDescription
        }

        return errorMessage
    }
}
