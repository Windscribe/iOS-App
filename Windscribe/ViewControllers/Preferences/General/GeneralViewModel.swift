//
//	GeneralViewModel.swift
//	Windscribe
//
//	Created by Thomas on 18/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol GeneralViewModelType {
    var hapticFeedback: BehaviorSubject<Bool> { get }
    var showServerHealth: BehaviorSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var languageUpdatedTrigger: PublishSubject<()> { get }
    var themeManager: ThemeManager {get}
    func didSelectedLocationOrder(value: String)
    func didSelectedLatencyDisplay(value: String)
    func didSelectedAppearance(value: String)
    func updateShowServerHealth()
    func updateHapticFeedback()
    func askForPushNotificationPermission()
    func getCurrentLocationOrder() -> String
    func getCurrentDisplayLatency() -> String
    func getCurrentApperance() -> String
    func getCurrentLanguage() -> String
    func getVersion() -> String
    func getServerHealth() -> Bool
    func getHapticFeedback() -> Bool
    func selectLanguage(with value: String)
}

class GeneralViewModel: GeneralViewModelType {
    // MARK: - Dependencies
    let preferences: Preferences
    let themeManager: ThemeManager
    let languageManager: LanguageManagerV2
    let pushNotificationManager: PushNotificationManagerV2

    // MARK: - State

    let disposeBag = DisposeBag()
    let hapticFeedback = BehaviorSubject<Bool>(value: DefaultValues.hapticFeedback)
    let showServerHealth = BehaviorSubject<Bool>(value: DefaultValues.showServerHealth)
    let locationOrderBy = BehaviorSubject<String>(value: DefaultValues.orderLocationsBy)
    let latencyType = BehaviorSubject<String>(value: DefaultValues.latencyType)
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)
    let languageUpdatedTrigger = PublishSubject<()>()

    // MARK: - Data
    init(preferences: Preferences, themeManager: ThemeManager, languageManager: LanguageManagerV2, pushNotificationManager: PushNotificationManagerV2) {
        self.preferences = preferences
        self.themeManager = themeManager
        self.languageManager = languageManager
        self.pushNotificationManager = pushNotificationManager
        self.load()
    }

    private func load() {
        preferences.getHapticFeedback().subscribe { [weak self] data in
            self?.hapticFeedback.onNext(data ?? DefaultValues.hapticFeedback)
        }.disposed(by: disposeBag)

        preferences.getShowServerHealth().subscribe { [weak self] data in
            self?.showServerHealth.onNext(data ?? DefaultValues.showServerHealth)
        }.disposed(by: disposeBag)

        preferences.getOrderLocationsBy().subscribe { [weak self] data in
            self?.locationOrderBy.onNext(data ?? DefaultValues.orderLocationsBy)
        }.disposed(by: disposeBag)

        preferences.getLatencyType().subscribe { [weak self] data in
            self?.latencyType.onNext(data)
        }.disposed(by: disposeBag)

        themeManager.darkTheme.subscribe { [weak self] data in
            self?.isDarkMode.onNext(data)
        }.disposed(by: disposeBag)

        languageManager.activelanguage.subscribe { [weak self] _ in
            self?.languageUpdatedTrigger.onNext(())
        }.disposed(by: disposeBag)
    }

    func updateHapticFeedback() {
        try? self.preferences.saveHapticFeedback(haptic: !hapticFeedback.value())
    }

    func updateShowServerHealth() {
        try? self.preferences.saveShowServerHealth(show: !showServerHealth.value())

    }

    func didSelectedLocationOrder(value: String) {
        guard let valueToSave = TextsAsset.General.getValue(displayText: value) else { return }
        self.preferences.saveOrderLocationsBy(order: valueToSave)
    }

    func didSelectedAppearance(value: String) {
        guard let valueToSave = TextsAsset.General.getValue(displayText: value) else { return }
        preferences.saveAppearance(appearance: valueToSave)
        preferences.saveDarkMode(darkMode: valueToSave == DefaultValues.appearance)
    }

    func didSelectedLatencyDisplay(value: String) {
        guard let valueToSave = TextsAsset.General.getValue(displayText: value) else { return }
        preferences.saveLatencyType(latencyType: valueToSave)
    }

    func getCurrentLocationOrder() -> String {
        return (try? locationOrderBy.value()) ?? DefaultValues.orderLocationsBy
    }

    func getCurrentDisplayLatency() -> String {
        return (try? latencyType.value()) ?? DefaultValues.latencyType
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
        if let language = TextsAsset.General.languagesList.first(where: { $0.name == value}) {
            languageManager.setLanguage(language: language)
        }
    }

    func getServerHealth() -> Bool {
        return (try? showServerHealth.value()) ?? DefaultValues.showServerHealth
    }

    func getHapticFeedback() -> Bool {
        return (try? hapticFeedback.value()) ?? DefaultValues.hapticFeedback

    }

    func updateHapticFeedback(_ status: Bool) {
        self.preferences.saveHapticFeedback(haptic: status)
    }

    func updateServerHealth(_ status: Bool) {
        self.preferences.saveShowServerHealth(show: status)
    }

    func getVersion() -> String {
        guard let releaseNumber = Bundle.main.releaseVersionNumber, let buildNumber = Bundle.main.buildVersionNumber else { return ""}
        return "v\(releaseNumber) (\(buildNumber))"
    }

    func askForPushNotificationPermission() {
        pushNotificationManager.askForPushNotificationPermission()
    }
}
