//
//  PreferencesMainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2023-12-19.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Combine
import RxSwift
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
    var actionDisplay: BehaviorSubject<PreferencesActionDisplay> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var currentLanguage: BehaviorSubject<String?> { get }
    var alertManager: AlertManagerV2 { get }
    func getActionButtonDisplay()
    func logoutUser()
    func isUserGhost() -> Bool
    func isUserPro() -> Bool
    func getPreferenceItem(for row: Int) -> PreferenceItemType?
    func getDataLeft() -> String
    func isDarkTheme() -> Bool
}

class PreferencesMainViewModelImpOld: PreferencesMainViewModelOld {
    let actionDisplay = BehaviorSubject<PreferencesActionDisplay>(value: .email)
    let isDarkMode: CurrentValueSubject<Bool, Never>
    var currentLanguage: BehaviorSubject<String?> = BehaviorSubject(value: nil)

    let userSessionRepository: UserSessionRepository
    let sessionManager: SessionManager
    let logger: FileLogger
    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    let alertManager: AlertManagerV2
    let preferences: Preferences
    let lookAndFeelRepository: LookAndFeelRepositoryType
    let languageManager: LanguageManager

    init(userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager,
         logger: FileLogger,
         alertManager: AlertManagerV2,
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
                self?.currentLanguage.onNext(updatedLanguage.name)
            }.store(in: &cancellables)
    }

    func getActionButtonDisplay() {
        if userSessionRepository.sessionModel?.isUserPro == true &&
            userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
            userSessionRepository.sessionModel?.isUserGhost == false {
            actionDisplay.onNext(.email)
            return
        } else if userSessionRepository.sessionModel?.isUserPro == false &&
                    userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
                    userSessionRepository.sessionModel?.isUserGhost == false {
            actionDisplay.onNext(.emailGet10GB)
            return
        } else if userSessionRepository.sessionModel?.isUserPro == false &&
                    userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
                    userSessionRepository.sessionModel?.isUserGhost == true {
            actionDisplay.onNext(.setupAccountAndLogin)
            return
        } else if userSessionRepository.sessionModel?.isUserPro == true &&
                    userSessionRepository.sessionModel?.hasUserAddedEmail == false &&
                    userSessionRepository.sessionModel?.isUserGhost == true {
            actionDisplay.onNext(.setupAccount)
            return
        } else if userSessionRepository.sessionModel?.userNeedsToConfirmEmail == true {
            actionDisplay.onNext(.confirmEmail)
            return
        } else {
            actionDisplay.onNext(.hideAll)
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
