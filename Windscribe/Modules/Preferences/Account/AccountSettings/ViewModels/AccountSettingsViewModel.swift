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

protocol AccountSettingsViewModel: PreferencesBaseViewModel {
    var sections: [AccountSectionModel] { get }
    var loadingState: AccountState { get }

    func loadSession()
    func handleRowAction(_ action: AccountRowAction)
}

final class AccountSettingsViewModelImpl: PreferencesBaseViewModelImpl, AccountSettingsViewModel {
    @Published var sections: [AccountSectionModel] = []
    @Published var loadingState: AccountState = .initial
    @Published var activeDialog: AccountDialogType?
    @Published var alertMessage: AccountSettingsAlertContent?
    @Published private(set) var accountEmailStatus: AccountEmailStatusType = .unknown

    // Dependencies
    private let preferences: Preferences
    private let sessionManager: SessionManager
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let languageManager: LanguageManager

    private let disposeBag = DisposeBag()

    var shouldShowAddEmailButton: Bool {
        guard let session = localDatabase.getSessionSync() else {
            return false
        }
        return session.email.isEmpty == true
    }

    var shouldShowPlanActionButtons: Bool {
        accountEmailStatus == .missing || accountEmailStatus == .unverified
    }

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         preferences: Preferences,
         sessionManager: SessionManager,
         apiManager: APIManager,
         localDatabase: LocalDatabase,
         languageManager: LanguageManager,
         logger: FileLogger,
         hapticFeedbackManager: HapticFeedbackManager) {
        self.preferences = preferences
        self.sessionManager = sessionManager
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.languageManager = languageManager

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        NotificationCenter.default.publisher(for: Notifications.sessionUpdated)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self, let updatedSession = self.sessionManager.session else { return }
                self.buildSections(from: updatedSession)
                self.accountEmailStatus = self.calculateEmailStatus(from: updatedSession)
            }
            .store(in: &cancellables)
    }

    override func reloadItems() { }

    func loadSession() {
        loadingState = .loading(isFullScreen: true)

        // Set initial state for session from the local database
        if let session = localDatabase.getSessionSync() {
            self.accountEmailStatus = self.calculateEmailStatus(from: session)
            self.buildSections(from: session)
        }

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let session = try await apiManager.getSession(nil)
                await MainActor.run {
                    self.accountEmailStatus = self.calculateEmailStatus(from: session)
                    self.buildSections(from: session)
                    self.loadingState = .success
                    self.localDatabase.saveSession(session: session).disposed(by: self.disposeBag)
                }
            } catch {
                await MainActor.run {
                    guard let session = self.localDatabase.getSessionSync() else {
                        self.loadingState = .error(error.localizedDescription)
                        self.logger.logE("AccountViewModel", "Failed to load session: \(error)")
                        return
                    }
                    self.accountEmailStatus = self.calculateEmailStatus(from: session)
                    self.buildSections(from: session)
                    self.loadingState = .success
                }
            }
        }
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
                value: getUserTypeDisplayText(from: session)
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
        actionSelected()
    }

    private func resendConfirmationEmail() {
        loadingState = .loading(isFullScreen: false)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await apiManager.confirmEmail()
                await MainActor.run {
                    self.loadingState = .success
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.ConfirmationEmailSentAlert.title,
                        message: TextsAsset.ConfirmationEmailSentAlert.message,
                        buttonText: TextsAsset.okay
                    )
                }
            } catch {
                await MainActor.run {
                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.ConfirmationEmailSentAlert.title,
                        message: error.localizedDescription,
                        buttonText: TextsAsset.okay
                    )
                }
            }
        }
    }

    func confirmCancelAccount(password: String) {
        loadingState = .loading(isFullScreen: false)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await apiManager.cancelAccount(password: password)
                await MainActor.run {
                    self.loadingState = .success
                    self.logoutUser()
                }
            } catch {
                await MainActor.run {
                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.error,
                        message: self.fetchErrorMessage(from: error),
                        buttonText: TextsAsset.okay)
                }
            }
        }
    }

    func verifyLazyLogin(code: String) {
        loadingState = .loading(isFullScreen: false)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                _ = try await apiManager.verifyTvLoginCode(code: code)
                await MainActor.run {
                    self.loadingState = .success
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.Account.lazyLogin,
                        message: TextsAsset.Account.lazyLoginSuccess,
                        buttonText: TextsAsset.okay)
                }
            } catch {
                await MainActor.run {
                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.error,
                        message: self.fetchErrorMessage(from: error),
                        buttonText: TextsAsset.okay)
                }
            }
        }
    }

    func verifyVoucher(code: String) {
        loadingState = .loading(isFullScreen: false)

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let response = try await apiManager.claimVoucherCode(code: code)
                await MainActor.run {
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
                            message: TextsAsset.Account.voucherAlreadyMessage,
                            buttonText: TextsAsset.okay)
                    } else {
                        self.alertMessage = AccountSettingsAlertContent(
                            title: TextsAsset.voucherCode,
                            message: TextsAsset.Account.invalidVoucherCode,
                            buttonText: TextsAsset.okay)
                    }
                }
            } catch {
                await MainActor.run {
                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.voucherCode,
                        message: self.fetchErrorMessage(from: error),
                        buttonText: TextsAsset.okay)
                }
            }
        }
    }

    private func getUserTypeDisplayText(from session: Session) -> String {
        if session.isUserPro {
            return session.isUserUnlimited ? TextsAsset.unlimited : TextsAsset.pro
        } else {
            return session.isUserCustom ? TextsAsset.General.custom : TextsAsset.Account.freeAccountDescription
        }
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
