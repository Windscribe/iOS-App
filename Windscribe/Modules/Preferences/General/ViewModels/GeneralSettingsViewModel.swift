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

protocol GeneralSettingsViewModel: ObservableObject {
    var isDarkMode: Bool { get set }
    var entries: [GeneralMenuEntryType] { get set }

    func entrySelected(_ entry: GeneralMenuEntryType, action: MenuEntryActionResponseType)
}

class GeneralSettingsViewModelImpl: GeneralSettingsViewModel {
    @Published var isDarkMode: Bool = false
    @Published var entries: [GeneralMenuEntryType] = []

    private var cancellables = Set<AnyCancellable>()
    private var currentLanguage: String = DefaultValues.language
    private var locationOrder: String = DefaultValues.orderLocationsBy
    private var isHapticFeedbackEnabled = DefaultValues.hapticFeedback
    private var isLocationLoadEnabled = DefaultValues.showServerHealth
    private var notificationsEnabled = false

    // MARK: - Dependencies
    private let logger: FileLogger
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let languageManager: LanguageManager
    private let preferences: Preferences
    private let pushNotificationManager: PushNotificationManagerV2

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         languageManager: LanguageManager,
         preferences: Preferences,
         pushNotificationManager: PushNotificationManagerV2) {
        self.logger = logger
        self.lookAndFeelRepository = lookAndFeelRepository
        self.languageManager = languageManager
        self.preferences = preferences
        self.pushNotificationManager = pushNotificationManager

        bindSubjects()
        reloadItems()
    }

    private func bindSubjects() {
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("GeneralSettingsViewModel", "Theme Adjustment Change error: \(error)")
                }
            }, receiveValue: { [weak self] isDark in
                self?.isDarkMode = isDark
                self?.reloadItems()
            })
            .store(in: &cancellables)

        languageManager.activelanguage
            .asPublisher()
            .map { $0.name }
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("GeneralSettingsViewModel", "Language change error: \(error)")
                }
            }, receiveValue: { [weak self] name in
                self?.currentLanguage = name
                self?.setLocationOrder(with: self?.locationOrder ?? DefaultValues.orderLocationsBy)
                self?.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getShowServerHealth()
            .toPublisher(initialValue: DefaultValues.showServerHealth)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("GeneralSettingsViewModel", "Location Load error: \(error)")
                }
            }, receiveValue: { [weak self] enabled in
                guard let self = self else { return }
                self.isLocationLoadEnabled = enabled ?? DefaultValues.showServerHealth
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getHapticFeedback()
            .toPublisher(initialValue: DefaultValues.hapticFeedback)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("GeneralSettingsViewModel", "Haptic Feedback error: \(error)")
                }
            }, receiveValue: { [weak self] enabled in
                guard let self = self else { return }
                self.isHapticFeedbackEnabled = enabled ?? DefaultValues.hapticFeedback
                self.reloadItems()
            })
            .store(in: &cancellables)

        preferences.getOrderLocationsBy()
            .toPublisher(initialValue: DefaultValues.orderLocationsBy)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("GeneralSettingsViewModel", "Order Location By error: \(error)")
                }
            }, receiveValue: { [weak self] order in
                guard let self = self else { return }
                self.setLocationOrder(with: order ?? DefaultValues.orderLocationsBy)
                self.reloadItems()
            })
            .store(in: &cancellables)
    }

    private func setLocationOrder(with value: String) {
        locationOrder = value.localized
    }

    private func reloadItems() {
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
