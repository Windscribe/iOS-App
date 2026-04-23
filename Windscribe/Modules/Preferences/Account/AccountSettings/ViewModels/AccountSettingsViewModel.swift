//
//  AccountSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol AccountSettingsViewModel: PreferencesBaseViewModel {
    var sections: [AccountSectionModel] { get }
    var loadingState: AccountState { get }
    var showUpgradeWithPromo: String? { get }
    var shouldShowUpgradeButton: Bool { get }
    var shouldShowDeleteAccountButton: Bool { get }
    var shouldShowResetPasswordButton: Bool { get }
    var resetPasswordButtonHidden: Bool { get }
    var showPasswordResetSuccess: Bool { get }

    func loadSession()
    func handleRowAction(_ action: AccountRowAction)
    func resetPassword()
    func dismissPasswordResetSuccess()
}

final class AccountSettingsViewModelImpl: PreferencesBaseViewModelImpl, AccountSettingsViewModel {
    @Published var sections: [AccountSectionModel] = []
    @Published var loadingState: AccountState = .initial
    @Published var activeDialog: AccountDialogType?
    @Published var alertMessage: AccountSettingsAlertContent?
    @Published private(set) var accountEmailStatus: AccountEmailStatusType = .unknown
    @Published var showUpgradeWithPromo: String?
    @Published private(set) var shouldShowResetPasswordButton: Bool = false
    @Published private(set) var resetPasswordButtonHidden: Bool = false
    @Published var showPasswordResetSuccess: Bool = false

    // Dependencies
    private let preferences: Preferences
    private let sessionManager: SessionManager
    private let userSessionRepository: UserSessionRepository
    private let apiManager: APIManager
    private let languageManager: LanguageManager

    var shouldShowAddEmailButton: Bool {
        guard let session = userSessionRepository.sessionModel else {
            return false
        }
        return session.email.isEmpty == true && !session.isHashAuth
    }

    // MARK: - Plan Action Buttons - Individual Logic

    var shouldShowUpgradeButton: Bool {
        guard let session = userSessionRepository.sessionModel else {
            return false
        }
        // Show only for non-pro users
        return !session.isUserPro
    }

    var shouldShowDeleteAccountButton: Bool {
        guard let session = userSessionRepository.sessionModel else {
            return false
        }
        // Show only if user has not used any data
        return session.trafficUsed <= 0
    }

    init(lookAndFeelRepository: LookAndFeelRepositoryType,
         preferences: Preferences,
         sessionManager: SessionManager,
         userSessionRepository: UserSessionRepository,
         apiManager: APIManager,
         languageManager: LanguageManager,
         logger: FileLogger,
         hapticFeedbackManager: HapticFeedbackManager) {
        self.preferences = preferences
        self.sessionManager = sessionManager
        self.userSessionRepository = userSessionRepository
        self.apiManager = apiManager
        self.languageManager = languageManager

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        userSessionRepository.sessionModelSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] sessionModel in
                guard let self = self, let updatedSession = sessionModel else { return }
                self.buildSections(from: updatedSession)
                self.accountEmailStatus = self.calculateEmailStatus(from: updatedSession)
                self.loadingState = .success
            }
            .store(in: &cancellables)
    }

    override func reloadItems() { }

    func loadSession() {
        loadingState = .loading(isFullScreen: true)

        // Set initial state for session from the local database
        if let session = userSessionRepository.sessionModel {
            self.accountEmailStatus = self.calculateEmailStatus(from: session)
            self.buildSections(from: session)
        }

        Task { @MainActor [weak self] in
            guard let self = self else { return }
            do {
                try await self.sessionManager.updateSession()
            } catch {
                await MainActor.run {
                    guard let session = self.userSessionRepository.sessionModel else {
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

    private func infoRows(from session: SessionModel) -> [AccountRowModel] {
        var infoRows: [AccountRowModel] = [
            .init(
                type: .textRow(
                    title: session.isHashAuth ? TextsAsset.Authentication.hash : TextsAsset.Authentication.username,
                    value: session.username,
                ),
                action: nil,
                copyable: true
            )
        ]

        guard !session.isHashAuth else { return infoRows }

        if session.email.isEmpty {
            infoRows.append(.init(
                type: .textRow(
                    title: TextsAsset.email,
                    value: TextsAsset.General.none,
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

        return infoRows
    }

    private func planRows(from session: SessionModel) -> [AccountRowModel] {
        var planRows: [AccountRowModel] = []

        if session.isUserPro {
            planRows.append(.init(
                type: .textImageRow(
                    title: TextsAsset.Account.plan,
                    imageName: ImagesAsset.proUserIcon
                ),
                action: nil
            ))
        } else {
            planRows.append(.init(
                type: .textRow(
                    title: TextsAsset.Account.plan,
                    value: getUserTypeDisplayText(from: session)
                ),
                action: nil
            ))
        }

        planRows.append(.init(
            type: .textRow(
                title: session.isPremium ? TextsAsset.Account.expiryDate : TextsAsset.Account.resetDate,
                value: session.isPremium ? session.premiumExpiryDate : session.getNextReset()
            ),
            action: nil
        ))

        if !session.isUserPro {
            planRows.append(.init(
                type: .textRow(
                    title: TextsAsset.Account.dataLeft,
                    value: "\(session.getDataLeft())/\(session.getDataMax())"
                ),
                action: nil
            ))
        }

        return planRows
    }

    private func otherRows(from session: SessionModel) -> [AccountRowModel] {
        let otherRows: [AccountRowModel] = [
            .init(type: .navigation(title: TextsAsset.Account.lazyLogin,
                                    subtitle: TextsAsset.Account.lazyLoginDescription),
                  action: .openLazyLogin)
        ]
        return otherRows
    }

    private func buildSections(from session: SessionModel) {
        sections = [
            .init(type: .info, items: infoRows(from: session)),
            .init(type: .plan, items: planRows(from: session)),
            .init(type: .other, items: otherRows(from: session))
        ]

        // Check if user logged in via SSO and has verified email for Reset Password button
        let ssoProvider = preferences.getSSOProvider()
        shouldShowResetPasswordButton = (ssoProvider == "apple" || ssoProvider == "google") && !session.email.isEmpty && session.emailStatus
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

    func dismissPasswordResetSuccess() {
        showPasswordResetSuccess = false
    }

    func resetPassword() {
        loadingState = .loading(isFullScreen: false)

        Task { [weak self] in
            guard let self = self else { return }

            // Get email from session
            guard let session = userSessionRepository.sessionModel,
                  !session.email.isEmpty else {
                await MainActor.run {
                    self.loadingState = .error("Email not found")
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.error,
                        message: TextsAsset.Account.resetPasswordEmailRequired,
                        buttonText: TextsAsset.okay
                    )
                }
                return
            }

            do {
                let response = try await apiManager.resetPassword(email: session.email)

                await MainActor.run {
                    if response.success {
                        // Password reset successful
                        self.loadingState = .success

                        // Hide button after successful reset (session-based)
                        self.resetPasswordButtonHidden = true

                        // Show custom success popup
                        self.showPasswordResetSuccess = true
                    } else {
                        // API returned failure (e.g., rate limiting, banned account)
                        self.loadingState = .error(response.message)
                        self.alertMessage = AccountSettingsAlertContent(
                            title: TextsAsset.error,
                            message: response.message,
                            buttonText: TextsAsset.okay
                        )
                    }
                }
            } catch {
                // Network or parsing error
                await MainActor.run {
                    self.loadingState = .error(error.localizedDescription)
                    self.alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.error,
                        message: self.fetchErrorMessage(from: error),
                        buttonText: TextsAsset.okay
                    )
                }
            }
        }
    }

    private func getUserTypeDisplayText(from session: SessionModel) -> String {
        if session.isUserPro {
            return session.isUserUnlimited ? TextsAsset.unlimited : TextsAsset.pro
        } else {
            return session.isUserCustom ? TextsAsset.General.custom : TextsAsset.Account.freeAccountDescription
        }
    }

    private func calculateEmailStatus(from session: SessionModel) -> AccountEmailStatusType {
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
