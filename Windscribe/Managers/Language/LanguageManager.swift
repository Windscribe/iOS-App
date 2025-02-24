//
//  LanguageManager.swift
//  Windscribe
//
//  Created by Thomas on 20/04/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

class LanguageManager: LanguageManagerV2 {
    private let preference: Preferences
    private let disposeBag = DisposeBag()
    var activelanguage = BehaviorSubject(value: Languages.english)
    private var language = Languages.english
    var currentLanguage: Languages = .english
    init(preference: Preferences) {
        self.preference = preference
        currentLanguage = getCurrentLanguage()
        bindData()
    }

    private func bindData() {
        preference.getLanguageManagerSelectedLanguage()
            .flatMap { languageName in
                Single.just(Languages.allCases.first { $0.name == languageName }?.rawValue ?? Languages.english.rawValue)
            }.subscribe(onNext: { languageCode in
                self.language = Languages(rawValue: languageCode) ?? Languages.english
                self.activelanguage.onNext(self.language)
                self.currentLanguage = self.getCurrentLanguage()
            }, onError: { _ in
                self.language = Languages.english
                self.activelanguage.onNext(Languages.english)
            }).disposed(by: disposeBag)
    }

    func getCurrentLanguage() -> Languages {
        currentLanguage = language
        return currentLanguage
    }

    func setCurrentLanguage() -> Languages {
        guard let currentLang = preference.getSelectedLanguage() else {
            return Languages.english
        }
        return Languages(rawValue: currentLang) ?? .english
    }

    lazy var supportedLanguages: [String] = Languages.allCases.map { $0.rawValue }

    var defaultLanguage: Languages {
        get {
            guard let defaultLanguage = preference.getDefaultLanguage() else {
                return Languages.english
            }
            return Languages(rawValue: defaultLanguage)!
        }
        set {
            let defaultLanguage = preference.getDefaultLanguage()

            guard defaultLanguage == nil else {
                setLanguage(language: getCurrentLanguage())
                return
            }
            preference.saveDefaultLanguage(language: newValue.rawValue)
            setLanguage(language: newValue)
        }
    }

    var deviceLanguage: Languages? {
        guard let deviceLanguage = Bundle.main.preferredLocalizations.first else {
            return nil
        }
        return Languages(rawValue: deviceLanguage)
    }

    func setLanguage(language: Languages) {
        preference.setLanguageManagerSelectedLanguage(language: language)
    }

    func setAppLanguage() {
        if (preference.getLanguageManagerLanguage()) != nil {
            return
        }
        if currentLanguage != Languages.english {
            return
        }
        if let appLanguage = Bundle.main.preferredLocalizations.first {
            if let language = Languages(rawValue: appLanguage) {
                setLanguage(language: language)
                return
            }
        }
        let systemLanguage: String?
        if #available(iOS 16.0, *) {
            systemLanguage = Locale.current.language.languageCode?.identifier
        } else {
            systemLanguage = Locale.current.languageCode
        }

        guard let systemLanguage = systemLanguage else {
            setLanguage(language: Languages.english)
            return
        }
        if let language = preference.getAppleLanguage(), language.uppercased() == systemLanguage.uppercased() {
            if let language = Languages(rawValue: language.lowercased()) {
                setLanguage(language: language)
            }
        } else {
            preference.saveLanguage(language: systemLanguage.uppercased())
            preference.saveAppleLanguage(languge: systemLanguage.uppercased())
            if let language = Languages(rawValue: systemLanguage.lowercased()) {
                setLanguage(language: language)
            }
        }
        defaultLanguage = .english
    }
}
