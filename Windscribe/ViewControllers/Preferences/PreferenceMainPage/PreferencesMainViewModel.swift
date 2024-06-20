//
//  PreferencesMainViewModel.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2023-12-19.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import UIKit
import RxSwift
protocol PreferencesMainViewModel {

    var actionDisplay: BehaviorSubject<ActionDisplay> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var currentLanguage: BehaviorSubject<String?> { get }
    var alertManager: AlertManagerV2 { get }
    func getActionButtonDisplay()
    func logoutUser()
    func isUserGhost() -> Bool
    func isUserPro() -> Bool
    func getPreferenceItem(for row: Int) -> PreferenceItem?
    func getDataLeft() -> String
    func isDarkTheme() -> Bool
}

enum ActionDisplay {
    case email
    case emailGet10GB
    case setupAccountAndLogin
    case setupAccount
    case confirmEmail
    case hideAll
}

class PreferencesMainViewModelImp: PreferencesMainViewModel {
    let actionDisplay = BehaviorSubject<ActionDisplay>(value: .email)
    let isDarkMode: BehaviorSubject<Bool>
    var currentLanguage: BehaviorSubject<String?> = BehaviorSubject(value: nil)

    let sessionManager: SessionManagerV2
    let logger: FileLogger
    let disposeBag = DisposeBag()
    let alertManager: AlertManagerV2
    let preferences: Preferences
    let themeManager: ThemeManager
    let languageManager: LanguageManagerV2

    init(sessionManager: SessionManagerV2, logger: FileLogger, alertManager: AlertManagerV2, themeManager: ThemeManager, preferences: Preferences, languageManager: LanguageManagerV2) {
        self.logger = logger
        self.sessionManager = sessionManager
        self.alertManager = alertManager
        self.themeManager = themeManager
        self.preferences = preferences
        self.languageManager = languageManager
        isDarkMode = themeManager.darkTheme
        observeLanguage()
    }

    private func observeLanguage() {
        languageManager.activelanguage.subscribe(onNext: { updatedLanguage in
            self.currentLanguage.onNext(updatedLanguage.name)
        }, onError: { _ in }
        ).disposed(by: disposeBag)
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

    func getPreferenceItem(for row: Int) -> PreferenceItem? {
        switch row {
        case 0:
            return PreferenceItem(icon: ImagesAsset.Preferences.general,
                                  title: TextsAsset.Preferences.general)
        case 1:
            return PreferenceItem(icon: ImagesAsset.Preferences.account,
                                  title: TextsAsset.Preferences.account)
        case 3:
            return PreferenceItem(icon: ImagesAsset.Preferences.robert,
                                  title: TextsAsset.Preferences.robert)
        case 2:
            return PreferenceItem(icon: ImagesAsset.Preferences.connection,
                                  title: TextsAsset.Preferences.connection)
        case 4:
            return PreferenceItem(icon: ImagesAsset.Preferences.advanceParams,
                                  title: TextsAsset.Preferences.advanceParameters)
        case 5:
            return PreferenceItem(icon: ImagesAsset.Servers.fav,
                                  title: TextsAsset.Preferences.referForData)
        case 6:
            return PreferenceItem(icon: ImagesAsset.Preferences.helpMe,
                                  title: TextsAsset.Preferences.helpMe)
        case 7:
            return PreferenceItem(icon: ImagesAsset.Preferences.about,
                                  title: TextsAsset.Preferences.about)
        case 8:
            return PreferenceItem(icon: ImagesAsset.Preferences.logoutRed,
                                  title: TextsAsset.Preferences.logout)
        default: break
        }
        return nil
    }

    func isDarkTheme() -> Bool {
        return themeManager.getIsDarkTheme()
    }

}
