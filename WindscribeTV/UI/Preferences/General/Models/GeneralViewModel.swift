//
//    GeneralViewModel.swift
//    Windscribe
//
//    Created by Thomas on 18/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Combine
import Foundation
import RxSwift
import UIKit

protocol GeneralViewModelType {
    var hapticFeedback: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var languageUpdatedTrigger: PublishSubject<Void> { get }
    var lookAndFeelRepository: LookAndFeelRepositoryType { get }
    func didSelectedLocationOrder(value: String)
    func updateHapticFeedback()
    func askForPushNotificationPermission()
    func getCurrentLocationOrder() -> String
    func getCurrentLanguage() -> String
    func getVersion() -> String
    func getHapticFeedback() -> Bool
    func selectLanguage(with value: String)
}

class GeneralViewModel: GeneralViewModelType {
    // MARK: - Dependencies

    let lookAndFeelRepository: LookAndFeelRepositoryType
    private let preferences: Preferences
    private let languageManager: LanguageManager
    private let pushNotificationManager: PushNotificationManager

    // MARK: - State

    let disposeBag = DisposeBag()
    private var cancellables = Set<AnyCancellable>()
    let hapticFeedback = BehaviorSubject<Bool>(value: DefaultValues.hapticFeedback)

    let locationOrderBy = BehaviorSubject<String>(value: DefaultValues.orderLocationsBy)
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)
    let languageUpdatedTrigger = PublishSubject<Void>()

    // MARK: - Data

    init(preferences: Preferences,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         languageManager: LanguageManager,
         pushNotificationManager: PushNotificationManager) {
        self.preferences = preferences
        self.lookAndFeelRepository = lookAndFeelRepository
        self.languageManager = languageManager
        self.pushNotificationManager = pushNotificationManager
        load()
    }

    private func load() {
        preferences.getHapticFeedback().sink { [weak self] data in
            self?.hapticFeedback.onNext(data ?? DefaultValues.hapticFeedback)
        }.store(in: &cancellables)

        preferences.getOrderLocationsBy().sink { [weak self] data in
            self?.locationOrderBy.onNext(data ?? DefaultValues.orderLocationsBy)
        }.store(in: &cancellables)

        lookAndFeelRepository.isDarkModeSubject.sink { [weak self] data in
            self?.isDarkMode.onNext(data)
        }.store(in: &cancellables)

        languageManager.activelanguage.sink { [weak self] _ in
            self?.languageUpdatedTrigger.onNext(())
        }.store(in: &cancellables)
    }

    func updateHapticFeedback() {
        try? preferences.saveHapticFeedback(haptic: !hapticFeedback.value())
    }

    func didSelectedLocationOrder(value: String) {
        guard let valueToSave = TextsAsset.General.getValue(displayText: value) else { return }
        preferences.saveOrderLocationsBy(order: valueToSave)
    }

    func didSelectedAppearance(value: String) {
        guard let valueToSave = TextsAsset.General.getValue(displayText: value) else { return }
        preferences.saveDarkMode(darkMode: valueToSave == DefaultValues.appearance)
    }

    func getCurrentLocationOrder() -> String {
        return preferences.getOrderLocationsBySync() ?? DefaultValues.orderLocationsBy
    }

    func getCurrentApperance() -> String {
        if let isDarkMode = try? isDarkMode.value(), !isDarkMode {
            return "Light"
        }
        return DefaultValues.appearance
    }

    func getCurrentLanguage() -> String {
        return languageManager.getCurrentLanguage().name
    }

    func selectLanguage(with value: String) {
        if let language = TextsAsset.General.languagesList.first(where: { $0.name == value }) {
            languageManager.setLanguage(language: language)
        }
    }

    func getHapticFeedback() -> Bool {
        return (try? hapticFeedback.value()) ?? DefaultValues.hapticFeedback
    }

    func updateHapticFeedback(_ status: Bool) {
        preferences.saveHapticFeedback(haptic: status)
    }

    func getVersion() -> String {
        guard let releaseNumber = Bundle.main.releaseVersionNumber, let buildNumber = Bundle.main.buildVersionNumber else { return "" }
        return "v\(releaseNumber) (\(buildNumber))"
    }

    func askForPushNotificationPermission() {
        pushNotificationManager.askForPushNotificationPermission()
    }
}
