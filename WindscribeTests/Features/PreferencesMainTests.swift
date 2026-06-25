//
//  PreferencesMainTests.swift
//  WindscribeTests
//
//  Created by Codescribe on 2026-06-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Testing
import Foundation
@testable import Windscribe

@Suite("PreferencesMainViewModel")
@MainActor
struct PreferencesMainViewModelTests {

    @Test("Entries appear in the legacy main-menu order for normal users")
    func entriesOrder() {
        let vm = makeViewModel(session: Self.makeSession())
        #expect(vm.visibleItems == [
            PreferencesMainEntryType.general,
            PreferencesMainEntryType.account,
            PreferencesMainEntryType.connection,
            PreferencesMainEntryType.robert,
            PreferencesMainEntryType.referForData,
            PreferencesMainEntryType.lookAndFeel,
            PreferencesMainEntryType.helpMe,
            PreferencesMainEntryType.about,
            PreferencesMainEntryType.logout
        ])
    }

    @Test("Ghost users do not see the logout row")
    func ghostUserHidesLogout() {
        let vm = makeViewModel(session: Self.makeSession(username: "", isPremium: false, email: ""))
        #expect(!vm.visibleItems.contains(PreferencesMainEntryType.logout))
    }

    @Test("Refer for Data is hidden for ghost and Pro users")
    func referForDataVisibility() {
        let ghost = makeViewModel(session: Self.makeSession(username: "", isPremium: false, email: ""))
        let pro = makeViewModel(session: Self.makeSession(isPremium: true))
        let free = makeViewModel(session: Self.makeSession(isPremium: false))

        #expect(ghost.shouldHideRow(item: PreferencesMainEntryType.referForData))
        #expect(pro.shouldHideRow(item: PreferencesMainEntryType.referForData))
        #expect(!free.shouldHideRow(item: PreferencesMainEntryType.referForData))
    }

    @Test("Account row dynamically routes ghost users")
    func accountRouteForGhostUsers() {
        let ghostFree = makeViewModel(session: Self.makeSession(username: "", isPremium: false, email: ""))
        let ghostProWithoutEmail = makeViewModel(session: Self.makeSession(username: "", isPremium: true, email: ""))
        let normal = makeViewModel(session: Self.makeSession())

        #expect(ghostFree.route(for: PreferencesMainEntryType.account) == PreferencesRouteID.ghostAccount)
        #expect(ghostProWithoutEmail.route(for: PreferencesMainEntryType.account) == PreferencesRouteID.signupGhost)
        #expect(normal.route(for: PreferencesMainEntryType.account) == PreferencesRouteID.account)
    }

    @Test("Action display mirrors legacy session state rules")
    func actionDisplayRules() {
        #expect(makeViewModel(session: nil).actionDisplay == PreferencesMainActionDisplay.hideAll)
        #expect(makeViewModel(session: Self.makeSession(isPremium: true, email: "")).actionDisplay == PreferencesMainActionDisplay.email)
        #expect(makeViewModel(session: Self.makeSession(isPremium: false, email: "")).actionDisplay == PreferencesMainActionDisplay.emailGet10GB)
        #expect(makeViewModel(session: Self.makeSession(username: "", isPremium: false, email: "")).actionDisplay == PreferencesMainActionDisplay.setupAccountAndLogin)
        #expect(makeViewModel(session: Self.makeSession(username: "", isPremium: true, email: "")).actionDisplay == PreferencesMainActionDisplay.setupAccount)
        #expect(makeViewModel(session: Self.makeSession(email: "user@example.com", emailStatus: false)).actionDisplay == PreferencesMainActionDisplay.confirmEmail)
    }

    @Test("Initial row theme starts light until the async theme observer emits")
    func initialThemeStartsLight() {
        let vm = makeViewModel(lookAndFeel: PreferencesMainMockLookAndFeelObserving(isDarkMode: true))
        #expect(vm.isDarkMode == false)
    }

    @Test("Logout logs, haptics, and delegates to AccountManaging")
    func logoutDelegates() {
        let account = PreferencesMainMockAccountManaging()
        let haptic = PreferencesMainMockHapticFeedbacking()
        let logger = PreferencesMainMockLogStoring()
        let vm = makeViewModel(accountManaging: account, hapticFeedback: haptic, logger: logger)

        vm.logout()

        #expect(account.logoutCount == 1)
        #expect(haptic.runLevels == [HapticFeedbackLevel.medium])
        #expect(logger.debugMessages == ["PreferencesViewModel: User tapped logout"])
    }

    private func makeViewModel(
        session: SessionModel? = PreferencesMainViewModelTests.makeSession(),
        accountManaging: PreferencesMainMockAccountManaging = PreferencesMainMockAccountManaging(),
        hapticFeedback: PreferencesMainMockHapticFeedbacking = PreferencesMainMockHapticFeedbacking(),
        logger: PreferencesMainMockLogStoring = PreferencesMainMockLogStoring(),
        lookAndFeel: PreferencesMainMockLookAndFeelObserving = PreferencesMainMockLookAndFeelObserving(),
        languageStoring: PreferencesMainMockLanguageStoring = PreferencesMainMockLanguageStoring()
    ) -> PreferencesMainViewModel {
        PreferencesMainViewModel(
            accountManaging: accountManaging,
            hapticFeedback: hapticFeedback,
            languageStoring: languageStoring,
            logger: logger,
            lookAndFeel: lookAndFeel,
            sessionProviding: PreferencesMainMockSessionProviding(session: session)
        )
    }

    private static func makeSession(username: String = "windscribe",
                                    isPremium: Bool = false,
                                    email: String = "user@example.com",
                                    emailStatus: Bool = true) -> SessionModel {
        SessionModel(
            sessionAuthHash: "hash",
            username: username,
            userId: "1",
            email: email,
            emailStatus: emailStatus,
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

// MARK: - Mocks

final class PreferencesMainMockSessionProviding: SessionProviding, @unchecked Sendable {
    var session: SessionModel?
    private var continuation: AsyncStream<SessionModel?>.Continuation?

    init(session: SessionModel?) {
        self.session = session
    }

    var sessionUpdates: AsyncStream<SessionModel?> {
        AsyncStream { continuation in
            self.continuation = continuation
            continuation.yield(self.session)
        }
    }

    func send(_ session: SessionModel?) {
        self.session = session
        continuation?.yield(session)
    }
}

final class PreferencesMainMockLookAndFeelObserving: LookAndFeelObserving, @unchecked Sendable {
    var isDarkMode: Bool
    var backgroundEffectConnect: BackgroundEffectType = .none
    var backgroundEffectDisconnect: BackgroundEffectType = .none
    var backgroundCustomConnectPath: String?
    var backgroundCustomDisconnectPath: String?
    var backgroundCustomAspectRatio: BackgroundAspectRatioType = .fill

    init(isDarkMode: Bool = false) {
        self.isDarkMode = isDarkMode
    }

    var darkModeUpdates: AsyncStream<Bool> {
        AsyncStream { continuation in
            continuation.yield(self.isDarkMode)
        }
    }
}

final class PreferencesMainMockLanguageStoring: LanguageStoring, @unchecked Sendable {
    var activeLanguage: Languages? = .english
    private(set) var setLanguageCalls: [Languages] = []

    var languageUpdates: AsyncStream<Languages> {
        AsyncStream { continuation in
            continuation.yield(.english)
        }
    }

    func setActiveLanguage(language: Languages) {
        activeLanguage = language
        setLanguageCalls.append(language)
    }
}

final class PreferencesMainMockHapticFeedbacking: HapticFeedbacking, @unchecked Sendable {
    var hapticFeedbackEnabled = false
    private(set) var checkedActionCount = 0
    private(set) var runLevels: [HapticFeedbackLevel] = []

    func checkSettingsAction(action: MenuEntryActionResponseType) {
        checkedActionCount += 1
    }

    func run(level: HapticFeedbackLevel) {
        runLevels.append(level)
    }
}

final class PreferencesMainMockLogStoring: LogStoring, @unchecked Sendable {
    private(set) var debugMessages: [String] = []

    func logI(_ tag: String, _ message: String) { }
    func logE(_ tag: String, _ message: String) { }
    func logD(_ tag: String, _ message: String) {
        debugMessages.append("\(tag): \(message)")
    }
    func getLogData() async throws -> String { "" }
}

final class PreferencesMainMockAccountManaging: AccountManaging, @unchecked Sendable {
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
