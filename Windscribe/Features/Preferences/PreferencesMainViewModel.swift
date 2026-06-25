//
//  PreferencesMainViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
enum PreferencesMainActionDisplay: Equatable {
    case email
    case emailGet10GB
    case setupAccountAndLogin
    case setupAccount
    case confirmEmail
    case hideAll
}

@available(iOS 17.0, *)
@Observable
@MainActor
final class PreferencesMainViewModel {
    var actionDisplay: PreferencesMainActionDisplay = .hideAll
    var visibleItems: [PreferencesMainEntryType] {
        let isGhost = sessionProviding.session?.isUserGhost ?? false
        let count = isGhost ? 9 : 10
        return (0..<count).compactMap { rawValue in
            guard let item = PreferencesMainEntryType(rawValue: rawValue) else { return nil }
            if item == .screenTest && !isScreenTestEnabled { return nil }
            return item
        }
    }

    private let accountManaging: AccountManaging
    private let hapticFeedback: HapticFeedbacking
    private let languageStoring: LanguageStoring
    private let logger: LogStoring
    private let sessionProviding: SessionProviding

    private let isScreenTestEnabled = false
    private var hasStarted = false

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
        guard !hasStarted else { return }
        hasStarted = true

        async let language: () = observeLanguage()
        async let session: () = observeSession()

        _ = await (language, session)
    }

    func observeLanguage() async {
        for await _ in languageStoring.languageUpdates {
            updateActionDisplay()
        }
    }

    func observeSession() async {
        for await _ in sessionProviding.sessionUpdates {
            updateActionDisplay()
        }
    }

    func actionSelected() {
        hapticFeedback.run(level: .medium)
    }

    func updateActionDisplay() {
        guard let session = sessionProviding.session else {
            actionDisplay = .hideAll
            return
        }

        if session.isUserPro && !session.hasUserAddedEmail && !session.isUserGhost {
            actionDisplay = .email
        } else if !session.isUserPro && !session.hasUserAddedEmail && !session.isUserGhost {
            actionDisplay = .emailGet10GB
        } else if !session.isUserPro && !session.hasUserAddedEmail && session.isUserGhost {
            actionDisplay = .setupAccountAndLogin
        } else if session.isUserPro && !session.hasUserAddedEmail && session.isUserGhost {
            actionDisplay = .setupAccount
        } else if session.userNeedsToConfirmEmail == true {
            actionDisplay = .confirmEmail
        } else {
            actionDisplay = .hideAll
        }
    }

    func route(for item: PreferencesMainEntryType) -> PreferencesRouteID? {
        if item == .account {
            return dynamicRouteForAccountRow()
        }
        return item.routeID
    }

    func shouldHideRow(item: PreferencesMainEntryType) -> Bool {
        let session = sessionProviding.session
        let isGhost = session?.isUserGhost ?? false
        let isPro = session?.isUserPro ?? false
        return item == .referForData && (isGhost || isPro)
    }

    func logout() {
        logger.logD("PreferencesViewModel", "User tapped logout")
        actionSelected()
        accountManaging.logoutUser()
    }

    private func dynamicRouteForAccountRow() -> PreferencesRouteID {
        let session = sessionProviding.session
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
