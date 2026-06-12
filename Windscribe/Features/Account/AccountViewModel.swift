//
//  AccountViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-09.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class AccountViewModel {

    // MARK: - State (read by the view)
    var sections: [AccountSectionModel] = []
    var loadingState: AccountState = .initial
    var alertMessage: AccountSettingsAlertContent?
    var accountEmailStatus: AccountEmailStatusType = .unknown
    var shouldShowResetPasswordButton = false
    var resetPasswordButtonHidden = false
    var showPasswordResetSuccess = false

    private var hasStarted = false

    var shouldShowAddEmailButton: Bool {
        guard let session = sessionProvider.session else { return false }
        return session.email.isEmpty && !session.isHashAuth
    }

    var shouldShowUpgradeButton: Bool {
        guard let session = sessionProvider.session else { return false }
        return !session.isUserPro
    }

    var shouldShowDeleteAccountButton: Bool {
        guard let session = sessionProvider.session else { return false }
        return session.trafficUsed <= 0
    }

    // MARK: - Dependencies (injected via init — protocols only)
    private let hapticFeedback: any HapticFeedbacking
    private let sessionProvider: any SessionProviding
    private let accountManager: any AccountManaging
    private let preferencesReading: any PreferencesReading
    private let logger: any LogStoring

    // MARK: - Init

    init(hapticFeedback: any HapticFeedbacking,
         sessionProvider: any SessionProviding,
         accountManager: any AccountManaging,
         preferencesReading: any PreferencesReading,
         logger: any LogStoring) {
        self.hapticFeedback = hapticFeedback
        self.sessionProvider = sessionProvider
        self.accountManager = accountManager
        self.preferencesReading = preferencesReading
        self.logger = logger

        if let session = sessionProvider.session {
            update(from: session)
        }
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !hasStarted else { return }
        hasStarted = true

        async let session: () = observeSession()

        _ = await (session)
    }

    func loadSession() async {
        loadingState = .loading(isFullScreen: true)

        if let session = sessionProvider.session {
            update(from: session)
        }

        do {
            try await accountManager.refreshSession()
            if let session = sessionProvider.session {
                update(from: session)
                loadingState = .success
            }
        } catch {
            guard let session = sessionProvider.session else {
                loadingState = .error(error.localizedDescription)
                logger.logE("AccountViewModel", "Failed to load session: \(error)")
                return
            }
            update(from: session)
            loadingState = .success
        }
    }

    func observeSession() async {
        for await session in sessionProvider.sessionUpdates {
            guard let session else { continue }
            update(from: session)
            if loadingState == .initial || loadingState == .loading(isFullScreen: true) {
                loadingState = .success
            }
        }
    }

    // MARK: - Actions (called by the view)

    func actionSelected() {
        hapticFeedback.run(level: .medium)
    }

    func handleRowAction(_ action: AccountRowAction) {
        actionSelected()

        switch action {
        case .resendEmail:
            resendConfirmationEmail()
        default:
            break
        }
    }

    func resendConfirmationEmail() {
        loadingState = .loading(isFullScreen: false)

        Task {
            do {
                try await accountManager.resendConfirmationEmail()
                loadingState = .success
                alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.ConfirmationEmailSentAlert.title,
                    message: TextsAsset.ConfirmationEmailSentAlert.message,
                    buttonText: TextsAsset.okay
                )
            } catch {
                loadingState = .error(error.localizedDescription)
                alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.ConfirmationEmailSentAlert.title,
                    message: fetchErrorMessage(from: error),
                    buttonText: TextsAsset.okay
                )
            }
        }
    }

    func confirmCancelAccount(password: String) {
        loadingState = .loading(isFullScreen: false)

        Task {
            do {
                try await accountManager.cancelAccount(password: password)
                loadingState = .success
                accountManager.logoutUser()
            } catch {
                loadingState = .error(error.localizedDescription)
                alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.error,
                    message: fetchErrorMessage(from: error),
                    buttonText: TextsAsset.okay
                )
            }
        }
    }

    func verifyLazyLogin(code: String) {
        loadingState = .loading(isFullScreen: false)

        Task {
            do {
                try await accountManager.verifyLazyLogin(code: code)
                loadingState = .success
                alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.Account.lazyLogin,
                    message: TextsAsset.Account.lazyLoginSuccess,
                    buttonText: TextsAsset.okay
                )
            } catch {
                loadingState = .error(error.localizedDescription)
                alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.error,
                    message: fetchErrorMessage(from: error),
                    buttonText: TextsAsset.okay
                )
            }
        }
    }

    func resetPassword() {
        loadingState = .loading(isFullScreen: false)

        Task {
            guard let session = sessionProvider.session, !session.email.isEmpty else {
                loadingState = .error(TextsAsset.Account.resetPasswordEmailRequired)
                alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.error,
                    message: TextsAsset.Account.resetPasswordEmailRequired,
                    buttonText: TextsAsset.okay
                )
                return
            }

            do {
                let response = try await accountManager.resetPassword(email: session.email)
                if response.success {
                    loadingState = .success
                    resetPasswordButtonHidden = true
                    showPasswordResetSuccess = true
                } else {
                    loadingState = .error(response.message)
                    alertMessage = AccountSettingsAlertContent(
                        title: TextsAsset.error,
                        message: response.message,
                        buttonText: TextsAsset.okay
                    )
                }
            } catch {
                loadingState = .error(error.localizedDescription)
                alertMessage = AccountSettingsAlertContent(
                    title: TextsAsset.error,
                    message: fetchErrorMessage(from: error),
                    buttonText: TextsAsset.okay
                )
            }
        }
    }

    func dismissPasswordResetSuccess() {
        showPasswordResetSuccess = false
    }

    // MARK: - Private helpers

    private func update(from session: SessionModel) {
        sections = [
            .init(type: .info, items: infoRows(from: session)),
            .init(type: .plan, items: planRows(from: session)),
            .init(type: .other, items: otherRows())
        ]
        accountEmailStatus = calculateEmailStatus(from: session)

        let ssoProvider = preferencesReading.ssoProvider
        shouldShowResetPasswordButton = (ssoProvider == "apple" || ssoProvider == "google") && !session.email.isEmpty && session.emailStatus
    }

    private func infoRows(from session: SessionModel) -> [AccountRowModel] {
        var infoRows: [AccountRowModel] = [
            .init(
                type: .textRow(
                    title: session.isHashAuth ? TextsAsset.Authentication.hash : TextsAsset.Authentication.username,
                    value: session.username
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
                    value: TextsAsset.General.none
                ),
                action: nil
            ))
        } else if !session.emailStatus {
            infoRows.append(.init(
                type: .confirmEmail(email: session.email),
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

    private func otherRows() -> [AccountRowModel] {
        [
            .init(type: .navigation(title: TextsAsset.Account.lazyLogin,
                                    subtitle: TextsAsset.Account.lazyLoginDescription),
                  action: .openLazyLogin)
        ]
    }

    private func getUserTypeDisplayText(from session: SessionModel) -> String {
        if session.isUserPro {
            return session.isUserUnlimited ? TextsAsset.unlimited : TextsAsset.pro
        }
        return session.isUserCustom ? TextsAsset.General.custom : TextsAsset.Account.freeAccountDescription
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

    private func fetchErrorMessage(from error: Error) -> String {
        if case let Errors.apiError(apiError) = error {
            return apiError.errorMessage ?? TextsAsset.unknownAPIError
        }
        return error.localizedDescription
    }
}
