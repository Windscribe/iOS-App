//
//  PreferencesMainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2023-12-19.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Combine
import UIKit

enum PreferencesActionDisplay {
    case email
    case emailGet10GB
    case setupAccountAndLogin
    case setupAccount
    case confirmEmail
    case hideAll
}

protocol PreferencesMainViewModelOld {
    var actionDisplay: CurrentValueSubject<PreferencesActionDisplay, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var currentLanguage: CurrentValueSubject<String?, Never> { get }
    var alertManager: AlertManager { get }
    func getActionButtonDisplay()
    func logoutUser()
    func isUserGhost() -> Bool
    func isUserPro() -> Bool
    func getPreferenceItem(for row: Int) -> PreferenceItemType?
    func getDataLeft() -> String
    func isDarkTheme() -> Bool
}

class PreferencesMainViewModelImpOld: PreferencesMainViewModelOld {
    let actionDisplay = CurrentValueSubject<PreferencesActionDisplay, Never>(.email)
    let isDarkMode: CurrentValueSubject<Bool, Never>
    var currentLanguage = CurrentValueSubject<String?, Never>(nil)

    let userSessionRepository: UserSessionRepository
    let sessionManager: SessionManager
    let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()
    let alertManager: AlertManager
    let preferences: Preferences
    let lookAndFeelRepository: LookAndFeelRepositoryType
    let languageManager: LanguageManager

    init(userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager,
         logger: FileLogger,
         alertManager: AlertManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         preferences: Preferences,
         languageManager: LanguageManager) {
        self.logger = logger
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.alertManager = alertManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.preferences = preferences
        self.languageManager = languageManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        observeLanguage()
    }

    private func observeLanguage() {
        languageManager.activelanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedLanguage in
                self?.currentLanguage.send(updatedLanguage.name)
            }.store(in: &cancellables)
    }

    func getActionButtonDisplay() {
        if userSessionRepository.sessionModel?.isUserPro == true &&
            userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
            userSessionRepository.sessionModel?.isUserGhost == false {
            actionDisplay.send(.email)
            return
        } else if userSessionRepository.sessionModel?.isUserPro == false &&
                    userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
                    userSessionRepository.sessionModel?.isUserGhost == false {
            actionDisplay.send(.emailGet10GB)
            return
        } else if userSessionRepository.sessionModel?.isUserPro == false &&
                    userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
                    userSessionRepository.sessionModel?.isUserGhost == true {
            actionDisplay.send(.setupAccountAndLogin)
            return
        } else if userSessionRepository.sessionModel?.isUserPro == true &&
                    userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
                    userSessionRepository.sessionModel?.isUserGhost == true {
            actionDisplay.send(.setupAccount)
            return
        } else if userSessionRepository.sessionModel?.userNeedsToConfirmEmail == true {
            actionDisplay.send(.confirmEmail)
            return
        } else {
            actionDisplay.send(.hideAll)
            return
        }
    }

    func logoutUser() {
        sessionManager.logoutUser()
    }

    func isUserGhost() -> Bool {
        return userSessionRepository.sessionModel?.isUserGhost ?? false
    }

    func isUserPro() -> Bool {
        return userSessionRepository.sessionModel?.isUserPro ?? false
    }

    func getDataLeft() -> String {
        return userSessionRepository.sessionModel?.getDataLeft() ?? "0 GB"
    }

    func getPreferenceItem(for row: Int) -> PreferenceItemType? {
        .general
    }

    func isDarkTheme() -> Bool {
        return lookAndFeelRepository.isDarkMode
    }
}
