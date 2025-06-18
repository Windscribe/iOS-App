//
//  PreferencesCategoryViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol PreferencesMainCategoryViewModel: ObservableObject {
    var actionDisplay: ActionDisplay { get set }
    var isDarkMode: Bool { get set }
    var currentLanguage: String? { get set }
    var visibleItems: [PreferenceItemType] { get set }

    func updateActionDisplay()
    func getDynamicRouteForAccountRow() -> PreferencesRouteID
    func shouldHideRow(index: Int) -> Bool
    func logout()
}

final class PreferencesMainCategoryViewModelImpl: PreferencesMainCategoryViewModel {
    @Published var actionDisplay: ActionDisplay = .hideAll
    @Published var isDarkMode: Bool = false
    @Published var currentLanguage: String?
    @Published var visibleItems: [PreferenceItemType] = []

    private var cancellables = Set<AnyCancellable>()

    private let sessionManager: SessionManaging
    private let alertManager: AlertManagerV2
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let languageManager: LanguageManager
    private let preferences: Preferences

    init(
        sessionManager: SessionManaging,
        alertManager: AlertManagerV2,
        logger: FileLogger,
        lookAndFeelRepository: LookAndFeelRepositoryType,
        languageManager: LanguageManager,
        preferences: Preferences
    ) {
        self.sessionManager = sessionManager
        self.alertManager = alertManager
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.languageManager = languageManager
        self.preferences = preferences

        bind()
        reloadItems()
        updateActionDisplay()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("PreferencesViewModel", "darkTheme error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
            })
            .store(in: &cancellables)

        languageManager.activelanguage
            .asPublisher()
            .map { $0.name }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("PreferencesViewModel", "language error: \(error)")
                }
            }, receiveValue: { [weak self] name in
                guard let self = self else { return }
                self.reloadItems()
                self.currentLanguage = name
                self.updateActionDisplay()
            })
            .store(in: &cancellables)
    }

    func updateActionDisplay() {
        guard let session = sessionManager.session else {
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

    func getDynamicRouteForAccountRow() -> PreferencesRouteID {
        let session = sessionManager.session
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

    func reloadItems() {
        let isGhost = sessionManager.session?.isUserGhost ?? false
        let count = isGhost ? 8 : 9
        visibleItems = (0..<count).compactMap { PreferenceItemType(rawValue: $0) }
    }

    func shouldHideRow(index: Int) -> Bool {
        let isGhost = sessionManager.session?.isUserGhost ?? false
        let isPro = sessionManager.session?.isUserPro ?? false
        return index == 4 && (isGhost || isPro)
    }

    func logout() {
        logger.logD("PreferencesViewModel", "User tapped logout")

        HapticFeedbackGenerator.shared.run(level: .medium)

        alertManager.showYesNoAlert(
            title: TextsAsset.Preferences.logout,
            message: TextsAsset.Preferences.logOutAlert
        ) { [weak self] confirmed in
            if confirmed {
                self?.sessionManager.logoutUser()
            }
        }
    }
}
