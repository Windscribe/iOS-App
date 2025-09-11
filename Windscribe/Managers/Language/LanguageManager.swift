//
//  LanguageManager.swift
//  Windscribe
//
//  Created by Thomas on 20/04/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Combine
import Foundation
import UIKit

protocol LanguageManager {
    var activelanguage: CurrentValueSubject<Languages, Never> { get }
    func setAppLanguage()
    func setLanguage(language: Languages)
    func getCurrentLanguage() -> Languages
}

class LanguageManagerImpl: LanguageManager {

    var activelanguage = CurrentValueSubject<Languages, Never>(Languages.english)
    private var language = Languages.english
    private var currentLanguage: Languages = .english

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

    private let preference: Preferences
    private let localizationService: LocalizationService

    private var cancellables = Set<AnyCancellable>()

    init(preference: Preferences, localizationService: LocalizationService) {
        self.preference = preference
        self.localizationService = localizationService

        currentLanguage = getCurrentLanguage()
        self.localizationService.updateLanguage(currentLanguage)
        bindData()
    }

    private func bindData() {
        preference.getLanguageManagerSelectedLanguage()
            .toPublisher(initialValue: Languages.english.name)
            .compactMap { (languageName: String?) -> String in
                Languages.allCases.first { $0.name == languageName }?.rawValue ?? Languages.english.rawValue
            }
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure = completion {
                        self?.language = Languages.english
                        self?.activelanguage.send(Languages.english)
                    }
                },
                receiveValue: { [weak self] (languageCode: String) in
                    guard let self = self else { return }
                    self.language = Languages(rawValue: languageCode) ?? Languages.english
                    self.activelanguage.send(self.language)
                    self.currentLanguage = self.getCurrentLanguage()
                    self.localizationService.updateLanguage(self.currentLanguage)
                }
            )
            .store(in: &cancellables)
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

    func setLanguage(language: Languages) {
        preference.setLanguageManagerSelectedLanguage(language: language)
        localizationService.updateLanguage(language)
        activelanguage.send(language)
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
