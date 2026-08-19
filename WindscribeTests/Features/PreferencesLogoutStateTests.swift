//
//  PreferencesLogoutStateTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-08-19.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Testing
@testable import Windscribe

@Suite("Preferences logout state")
@MainActor
struct PreferencesLogoutStateTests {
    @Test("Logout freezes session-derived menu state")
    func logoutFreezesSessionDerivedMenuState() async {
        for isPremium in [false, true] {
            let sessionProvider = PreferencesLogoutSessionProvider(
                session: makeSession(isPremium: isPremium)
            )
            let accountManager = PreferencesLogoutAccountManager()
            let viewModel = PreferencesMainViewModel(
                accountManaging: accountManager,
                hapticFeedback: PreferencesLogoutHapticFeedback(),
                languageStoring: PreferencesLogoutLanguageStore(),
                logger: PreferencesLogoutLogger(),
                sessionProviding: sessionProvider
            )
            let visibleItems = viewModel.visibleItems
            let hidesReferForData = viewModel.shouldHideRow(item: .referForData)
            let actionButtons = viewModel.actionButtons

            viewModel.logout()
            sessionProvider.session = nil
            await viewModel.observeSession()

            #expect(viewModel.isLoggingOut)
            #expect(accountManager.logoutCount == 1)
            #expect(viewModel.visibleItems == visibleItems)
            #expect(viewModel.shouldHideRow(item: .referForData) == hidesReferForData)
            #expect(viewModel.actionButtons == actionButtons)
        }
    }

    private func makeSession(isPremium: Bool) -> SessionModel {
        SessionModel(
            sessionAuthHash: "hash",
            username: "windscribe",
            userId: "1",
            email: "user@example.com",
            emailStatus: true,
            trafficUsed: 0,
            trafficMax: 10,
            status: 1,
            billingPlanId: isPremium ? 1 : 0,
            isPremium: isPremium,
            premiumExpiryDate: "",
            regDate: 0,
            lastReset: "",
            locRev: 0,
            locHash: "",
            amneziawgConfigId: "",
            alc: [],
            sipCount: []
        )
    }
}

private final class PreferencesLogoutSessionProvider: SessionProviding, @unchecked Sendable {
    var session: SessionModel?

    init(session: SessionModel?) {
        self.session = session
    }

    var sessionUpdates: AsyncStream<SessionModel?> {
        let session = session
        return AsyncStream { continuation in
            continuation.yield(session)
            continuation.finish()
        }
    }
}

private final class PreferencesLogoutAccountManager: AccountManaging, @unchecked Sendable {
    private(set) var logoutCount = 0

    func refreshSession() async throws { }
    func resendConfirmationEmail() async throws { }
    func addEmail(_ email: String) async throws { }
    func cancelAccount(password: String) async throws { }
    func cancelSSOAccount(ssoToken: String) async throws { }
    func verifyLazyLogin(code: String) async throws { }
    func resetPassword(email: String) async throws -> AccountPasswordResetResult {
        AccountPasswordResetResult(success: true, message: "")
    }
    func keepSessionUpdated() { }
    func logoutUser() { logoutCount += 1 }
}

private final class PreferencesLogoutHapticFeedback: HapticFeedbacking, @unchecked Sendable {
    var hapticFeedbackEnabled = false

    func checkSettingsAction(action: MenuEntryActionResponseType) { }
    func run(level: HapticFeedbackLevel) { }
}

private final class PreferencesLogoutLanguageStore: LanguageStoring, @unchecked Sendable {
    var activeLanguage: Languages? = .english

    var languageUpdates: AsyncStream<Languages> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    func setActiveLanguage(language: Languages) {
        activeLanguage = language
    }
}

private final class PreferencesLogoutLogger: LogStoring, @unchecked Sendable {
    func logI(_ tag: String, _ message: String) { }
    func logE(_ tag: String, _ message: String) { }
    func logD(_ tag: String, _ message: String) { }
    func getLogData() async throws -> String { "" }
}
