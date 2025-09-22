//
//  GeneralSettingsViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UserNotifications
import UIKit

protocol GeneralSettingsViewModel: PreferencesBaseViewModel {
    var entries: [GeneralMenuEntryType] { get set }

    func entrySelected(_ entry: GeneralMenuEntryType, action: MenuEntryActionResponseType)
}

class GeneralSettingsViewModelImpl: PreferencesBaseViewModelImpl, GeneralSettingsViewModel {
    @Published var entries: [GeneralMenuEntryType] = []

    private var currentLanguage: String = DefaultValues.language
    private var locationOrder: String = DefaultValues.orderLocationsBy
    private var isHapticFeedbackEnabled = DefaultValues.hapticFeedback
    private var isLocationLoadEnabled = DefaultValues.showServerHealth
    private var notificationsEnabled = false

    // MARK: - Dependencies
    private let languageManager: LanguageManager
    private let preferences: Preferences
    private let pushNotificationManager: PushNotificationManager

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         languageManager: LanguageManager,
         preferences: Preferences,
         pushNotificationManager: PushNotificationManager) {

        self.languageManager = languageManager
        self.preferences = preferences
        self.pushNotificationManager = pushNotificationManager

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)
    }

    override func bindSubjects() {
        super.bindSubjects()

        languageManager.activelanguage
            .map { $0.name }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] name in
                self?.currentLanguage = name
                self?.setLocationOrder(with: self?.locationOrder ?? DefaultValues.orderLocationsBy)
                self?.reloadItems()
            }
            .store(in: &cancellables)

        preferences.getShowServerHealth()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                self.isLocationLoadEnabled = enabled ?? DefaultValues.showServerHealth
                self.reloadItems()
            }
            .store(in: &cancellables)

        preferences.getHapticFeedback()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self = self else { return }
                self.isHapticFeedbackEnabled = enabled ?? DefaultValues.hapticFeedback
                self.reloadItems()
            }
            .store(in: &cancellables)

        preferences.getOrderLocationsBy()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] order in
                guard let self = self else { return }
                self.setLocationOrder(with: order ?? DefaultValues.orderLocationsBy)
                self.reloadItems()
            }
            .store(in: &cancellables)
    }

    private func setLocationOrder(with value: String) {
        locationOrder = value.localized
    }

    override func reloadItems() {
        let orderPreferences = zip(TextsAsset.orderPreferences,
                                        Fields.orderPreferences)
            .map { MenuOption(title: $0, fieldKey: $1) }
        let languages = TextsAsset.General.languages
            .map { MenuOption(title: $0, fieldKey: $0) }

        entries = [
            .locationOrder(currentOption: locationOrder, options: orderPreferences),
            .language(currentOption: currentLanguage, options: languages),
            .locationLoad(isSelected: isLocationLoadEnabled),
            .hapticFeedback(isSelected: isHapticFeedbackEnabled),
            .notification(title: TextsAsset.General.openSettings),
            .version(message: getVersion())
        ]
    }

    private func didSelectedLocationOrder(value: String) {
        preferences.saveOrderLocationsBy(order: value)
    }

    private func selectLanguage(with value: String) {
        if let language = TextsAsset.General.languagesList.first(where: { $0.name == value }) {
            languageManager.setLanguage(language: language)
        }
    }

    private func pushNotificationSettingsPressed() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .denied:
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    DispatchQueue.main.async {
                        UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                    }
                }
            case .notDetermined:
                self.pushNotificationManager.askForPushNotificationPermission()
            default:
                break
            }
        }
    }

    private func getVersion() -> String {
        guard let releaseNumber = Bundle.main.releaseVersionNumber, let buildNumber = Bundle.main.buildVersionNumber else { return "" }
        return "v\(releaseNumber) (\(buildNumber))"
    }

    func entrySelected(_ entry: GeneralMenuEntryType, action: MenuEntryActionResponseType) {
        actionSelected(action)

        switch entry {
        case .hapticFeedback:
            if case .toggle(let isSelected, _) = action {
                preferences.saveHapticFeedback(haptic: isSelected)
            }
        case .locationLoad:
            if case .toggle(let isSelected, _) = action {
                preferences.saveShowServerHealth(show: isSelected)
            }
        case .locationOrder:
            if case .multiple(let currentOption, _) = action {
                didSelectedLocationOrder(value: currentOption)
            }
        case .language:
            if case .multiple(let currentOption, _) = action {
                selectLanguage(with: currentOption)
            }
        case .notification:
            pushNotificationSettingsPressed()
        case .version: break
        }
    }
}
