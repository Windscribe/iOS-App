//
//    GeneralViewModel.swift
//    Windscribe
//
//    Created by Thomas on 18/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Combine
import Foundation
import UIKit

protocol GeneralViewModelType {
    var hapticFeedback: CurrentValueSubject<Bool, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var languageUpdatedTrigger: PassthroughSubject<Void, Never> { get }
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

    private var cancellables = Set<AnyCancellable>()
    let hapticFeedback = CurrentValueSubject<Bool, Never>(DefaultValues.hapticFeedback)

    let locationOrderBy = CurrentValueSubject<String, Never>(DefaultValues.orderLocationsBy)
    let isDarkMode = CurrentValueSubject<Bool, Never>(DefaultValues.darkMode)
    let languageUpdatedTrigger = PassthroughSubject<Void, Never>()

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
            self?.hapticFeedback.send(data ?? DefaultValues.hapticFeedback)
        }.store(in: &cancellables)

        preferences.getOrderLocationsBy().sink { [weak self] data in
            self?.locationOrderBy.send(data ?? DefaultValues.orderLocationsBy)
        }.store(in: &cancellables)

        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] data in
                self?.isDarkMode.send(data)
            }.store(in: &cancellables)

        languageManager.activelanguage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.languageUpdatedTrigger.send(())
            }.store(in: &cancellables)
    }

    func updateHapticFeedback() {
        preferences.saveHapticFeedback(haptic: !hapticFeedback.value)
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
        if !isDarkMode.value {
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
        return hapticFeedback.value
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
