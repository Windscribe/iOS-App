//
//  AccountManaging.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-09.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

struct AccountPasswordResetResult: Sendable {
    let success: Bool
    let message: String
}

/// Account actions needed by the Neo Account preferences screen.
protocol AccountManaging: Sendable {
    func refreshSession() async throws
    func resendConfirmationEmail() async throws
    func addEmail(_ email: String) async throws
    func cancelAccount(password: String) async throws
    func verifyLazyLogin(code: String) async throws
    func resetPassword(email: String) async throws -> AccountPasswordResetResult
    func keepSessionUpdated()
    func logoutUser()
}

/// Adapter over legacy account/session services.
///
/// The wrapped legacy protocols are not fully Sendable yet; this adapter is
/// retained at the composition seam and only exposes async account actions.
final class LegacyAccountManager: AccountManaging, @unchecked Sendable {
    private let sessionManager: SessionManager
    private let apiManager: APIManager

    init(sessionManager: SessionManager, apiManager: APIManager) {
        self.sessionManager = sessionManager
        self.apiManager = apiManager
    }

    func refreshSession() async throws {
        try await sessionManager.updateSession()
    }

    func resendConfirmationEmail() async throws {
        _ = try await apiManager.confirmEmail()
    }

    func addEmail(_ email: String) async throws {
        _ = try await apiManager.addEmail(email: email)
    }

    func cancelAccount(password: String) async throws {
        _ = try await apiManager.cancelAccount(password: password)
    }

    func verifyLazyLogin(code: String) async throws {
        _ = try await apiManager.verifyTvLoginCode(code: code)
    }

    func resetPassword(email: String) async throws -> AccountPasswordResetResult {
        let response = try await apiManager.resetPassword(email: email)
        return AccountPasswordResetResult(success: response.success, message: response.message)
    }

    func keepSessionUpdated() {
        sessionManager.keepSessionUpdated()
    }

    func logoutUser() {
        sessionManager.logoutUser()
    }
}
