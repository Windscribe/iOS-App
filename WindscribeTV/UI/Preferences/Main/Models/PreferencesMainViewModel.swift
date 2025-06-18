//
//  PreferencesMainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2023-12-19.
//  Copyright © 2023 Windscribe. All rights reserved.
//

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
    var isDarkMode: BehaviorSubject<Bool> { get }
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
    let isDarkMode: BehaviorSubject<Bool>
    var currentLanguage: BehaviorSubject<String?> = BehaviorSubject(value: nil)

    let sessionManager: SessionManaging
    let logger: FileLogger
    let disposeBag = DisposeBag()
    let alertManager: AlertManagerV2
    let preferences: Preferences
    let lookAndFeelRepository: LookAndFeelRepositoryType
    let languageManager: LanguageManager

    init(sessionManager: SessionManaging, logger: FileLogger, alertManager: AlertManagerV2, lookAndFeelRepository: LookAndFeelRepositoryType, preferences: Preferences, languageManager: LanguageManager) {
        self.logger = logger
        self.sessionManager = sessionManager
        self.alertManager = alertManager
        self.lookAndFeelRepository = lookAndFeelRepository
        self.preferences = preferences
        self.languageManager = languageManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        observeLanguage()
    }

    private func observeLanguage() {
        languageManager.activelanguage.subscribe(onNext: { [weak self] updatedLanguage in
            self?.currentLanguage.onNext(updatedLanguage.name)
        }, onError: { _ in }).disposed(by: disposeBag)
    }

    func getActionButtonDisplay() {
        if sessionManager.session?.isUserPro == true &&
            sessionManager.session?.hasUserAddedEmail == false &&
            sessionManager.session?.isUserGhost == false {
            actionDisplay.onNext(.email)
            return
        } else if sessionManager.session?.isUserPro == false &&
            sessionManager.session?.hasUserAddedEmail == false &&
            sessionManager.session?.isUserGhost == false {
            actionDisplay.onNext(.emailGet10GB)
            return
        } else if sessionManager.session?.isUserPro == false &&
            sessionManager.session?.hasUserAddedEmail == false &&
            sessionManager.session?.isUserGhost == true {
            actionDisplay.onNext(.setupAccountAndLogin)
            return
        } else if sessionManager.session?.isUserPro == true &&
            sessionManager.session?.hasUserAddedEmail == false &&
            sessionManager.session?.isUserGhost == true {
            actionDisplay.onNext(.setupAccount)
            return
        } else if sessionManager.session?.userNeedsToConfirmEmail == true {
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
        return sessionManager.session?.isUserGhost ?? false
    }

    func isUserPro() -> Bool {
        return sessionManager.session?.isUserPro ?? false
    }

    func getDataLeft() -> String {
        return sessionManager.session?.getDataLeft() ?? "0 GB"
    }

    func getPreferenceItem(for row: Int) -> PreferenceItemType? {
        .general
    }

    func isDarkTheme() -> Bool {
        return lookAndFeelRepository.isDarkMode
    }
}
