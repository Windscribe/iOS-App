//
//  PreferencesMainViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class PreferencesMainViewModel {
    var visibleItems: [PreferencesMainEntryType] {
        let isGhost = session?.isUserGhost ?? false
        let count = isGhost ? 9 : 10
        return (0..<count).compactMap { rawValue in
            guard let item = PreferencesMainEntryType(rawValue: rawValue) else { return nil }
            if item == .screenTest && !isScreenTestEnabled { return nil }
            return item
        }
    }

    var actionButtons: [PreferencesAction] = []
    var activeRoute: PreferencesRouteID?
    var showConfirmEmailSheet = false
    var showLogoutConfirmation = false
    private(set) var isLoggingOut = false

    private let accountManaging: AccountManaging
    private let hapticFeedback: HapticFeedbacking
    private let languageStoring: LanguageStoring
    private let logger: LogStoring
    private let sessionProviding: SessionProviding

    private let isScreenTestEnabled = false
    private var isObserving = false
    private var logoutSession: SessionModel?
    private var session: SessionModel? {
        isLoggingOut ? logoutSession : sessionProviding.session
    }

    init(accountManaging: AccountManaging,
         hapticFeedback: HapticFeedbacking,
         languageStoring: LanguageStoring,
         logger: LogStoring,
         sessionProviding: SessionProviding) {
        self.accountManaging = accountManaging
        self.hapticFeedback = hapticFeedback
        self.languageStoring = languageStoring
        self.logger = logger
        self.sessionProviding = sessionProviding

        updateActionDisplay()
    }

    func startObservers() async {
        guard !isLoggingOut, !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let language: () = observeLanguage()
        async let session: () = observeSession()

        _ = await (language, session)
    }

    func observeLanguage() async {
        for await _ in languageStoring.languageUpdates {
            guard !isLoggingOut else { return }
            updateActionDisplay()
        }
    }

    func observeSession() async {
        for await _ in sessionProviding.sessionUpdates {
            guard !isLoggingOut else { return }
            updateActionDisplay()
        }
    }

    func actionSelected() {
        hapticFeedback.run(level: .medium)
    }

    func updateActionDisplay() {
        guard let session else {
            actionButtons = []
            return
        }

        if !session.shouldShowEmailPromo && !session.hasUserAddedEmail && !session.isUserGhost {
            actionButtons = [.email]
        } else if session.shouldShowEmailPromo && !session.hasUserAddedEmail && !session.isUserGhost {
            actionButtons = [.emailGet10GB]
        } else if !session.isUserPro && !session.hasUserAddedEmail && session.isUserGhost {
            actionButtons = [.setupAccountAndLogin, .login]
        } else if session.isUserPro && !session.hasUserAddedEmail && session.isUserGhost {
            actionButtons = [.setupAccount, .login]
        } else if session.userNeedsToConfirmEmail == true {
            actionButtons = [.confirmEmail]
        } else {
            actionButtons = []
        }
    }

    func route(for item: PreferencesMainEntryType) -> PreferencesRouteID? {
        if item == .account {
            return dynamicRouteForAccountRow()
        }
        return item.routeID
    }

    func shouldHideRow(item: PreferencesMainEntryType) -> Bool {
        let isGhost = session?.isUserGhost ?? false
        let isPro = session?.isUserPro ?? false
        return item == .referForData && (isGhost || isPro)
    }

    func handleEntrySelection(_ item: PreferencesMainEntryType) {
        actionSelected()
        if item == .logout {
            showLogoutConfirmation = true
        } else if let route = route(for: item) {
            activeRoute = route
        }
    }

    func handlePrimaryAction(for action: PreferencesAction) {
        actionSelected()
        switch action {
        case .email, .emailGet10GB:
            activeRoute = .enterEmail
        case .setupAccountAndLogin, .setupAccount:
            activeRoute = .signupGhost
        case .confirmEmail:
            showConfirmEmailSheet = true
        case .login:
            activeRoute = .login
        }
    }

    func clearActiveRoute() {
        activeRoute = nil
    }

    func clearEmailSheet() {
        showConfirmEmailSheet = false
    }

    func logout() {
        logger.logD("PreferencesViewModel", "User tapped logout")
        actionSelected()
        logoutSession = sessionProviding.session
        isLoggingOut = true
        accountManaging.logoutUser()
    }

    private func dynamicRouteForAccountRow() -> PreferencesRouteID {
        if session?.isUserGhost == true {
            if session?.isUserPro == true && session?.hasUserAddedEmail == false {
                return .signupGhost
            } else {
                return .ghostAccount
            }
        } else {
            return .account
        }
    }
}
