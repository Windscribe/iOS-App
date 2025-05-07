//
//	LanguageViewModel.swift
//	Windscribe
//
//	Created by Thomas on 25/04/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol LanguageViewModelType {
    var didUpdateLanguage: (() -> Void)? { get set }
    var isDarkMode: BehaviorSubject<Bool> { get }
    func numberOfRows() -> Int
    func dataForCell(at indexPath: IndexPath) -> LanguageDataCell
    func selectedLanguage(at indexPath: IndexPath)
}

class LanguageViewModel: LanguageViewModelType {
    var didUpdateLanguage: (() -> Void)?
    let isDarkMode: BehaviorSubject<Bool>

    // MARK: - Dependencies

    let languageManager: LanguageManager, preferences: Preferences, disposeBag = DisposeBag()

    var language = Languages.english

    init(languageManager: LanguageManager, preferences: Preferences, lookAndFeelRepo: LookAndFeelRepositoryType) {
        self.languageManager = languageManager
        self.preferences = preferences
        isDarkMode = lookAndFeelRepo.isDarkModeSubject
        load()
    }

    private func load() {
        preferences.getLanguageManagerSelectedLanguage().subscribe(
            onNext: { language in
                self.language = Languages.allCases.first { $0.name == language } ?? Languages.english
                self.didUpdateLanguage?()
            }).disposed(by: disposeBag)
    }

    lazy var dataCells: [LanguageDataCell] = Languages.allCases.map { LanguageDataCell(language: $0) }

    func selectedLanguage(at indexPath: IndexPath) {
        let selectedlLanguage = dataCells[indexPath.row].language
        languageManager.setLanguage(language: selectedlLanguage)
    }

    func dataForCell(at indexPath: IndexPath) -> LanguageDataCell {
        return dataCells[indexPath.row]
    }

    func numberOfRows() -> Int {
        return dataCells.count
    }
}
