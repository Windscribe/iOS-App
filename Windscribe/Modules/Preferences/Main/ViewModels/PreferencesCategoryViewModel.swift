//
//  PreferencesCategoryViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol PreferencesMainCategoryViewModel: PreferencesBaseViewModel {
    var actionButtons: [PreferencesAction] { get set }
    var currentLanguage: String? { get set }
    var visibleItems: [PreferenceItemType] { get set }
    var isScreenTestEnabled: Bool { get }

    func updateActionDisplay()
    func getDynamicRouteForAccountRow() -> PreferencesRouteID
    func shouldHideRow(index: Int) -> Bool
    func logout()
}

final class PreferencesMainCategoryViewModelImpl: PreferencesBaseViewModelImpl, PreferencesMainCategoryViewModel {
    @Published var actionButtons: [PreferencesAction] = []
    @Published var currentLanguage: String?
    @Published var visibleItems: [PreferenceItemType] = []

    var isScreenTestEnabled: Bool = false

    private let sessionManager: SessionManager
    private let userSessionRepository: UserSessionRepository
    private let alertManager: AlertManager
    private let languageManager: LanguageManager
    private let preferences: Preferences
    private var isLoggingOut = false
    private var logoutSession: SessionModel?
    private var session: SessionModel? {
        isLoggingOut ? logoutSession : userSessionRepository.sessionModel
    }

    init(
        sessionManager: SessionManager,
        userSessionRepository: UserSessionRepository,
        alertManager: AlertManager,
        logger: FileLogger,
        lookAndFeelRepository: LookAndFeelRepositoryType,
        languageManager: LanguageManager,
        preferences: Preferences,
        hapticFeedbackManager: HapticFeedbackManager
    ) {
        self.sessionManager = sessionManager
        self.userSessionRepository = userSessionRepository
        self.alertManager = alertManager
        self.languageManager = languageManager
        self.preferences = preferences

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)

        updateActionDisplay()
    }

    override func bindSubjects() {
        super.bindSubjects()

        languageManager.activelanguage
            .map { $0.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                guard let self = self else { return }
                self.reloadItems()
                self.currentLanguage = name
                self.updateActionDisplay()
            }
            .store(in: &cancellables)
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

    func getDynamicRouteForAccountRow() -> PreferencesRouteID {
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

    override func reloadItems() {
        let isGhost = session?.isUserGhost ?? false
        let count = isGhost ? 9 : 10
        visibleItems = (0..<count).compactMap {
            let item = PreferenceItemType(rawValue: $0)!
            if item == .screenTest && !isScreenTestEnabled { return nil }
            return item
        }
    }

    func shouldHideRow(index: Int) -> Bool {
        let isGhost = session?.isUserGhost ?? false
        let isPro = session?.isUserPro ?? false
        return index == 4 && (isGhost || isPro)
    }

    func logout() {
        logger.logD("PreferencesViewModel", "User tapped logout")

        actionSelected()

        alertManager.showYesNoAlert(
            title: TextsAsset.Preferences.logout,
            message: TextsAsset.Preferences.logOutAlert
        ) { [weak self] confirmed in
            guard confirmed, let self else { return }
            self.logoutSession = self.userSessionRepository.sessionModel
            self.isLoggingOut = true
            self.cancellables.removeAll()
            self.sessionManager.logoutUser()
        }
    }
}
