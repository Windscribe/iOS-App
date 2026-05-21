//
//  GeneralViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 07/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

@available(iOS 17.0, *)
@Observable
@MainActor
final class GeneralViewModel {

    // MARK: - State (read by the view)
    private var currentLanguage: String
    private var locationOrder: String = DefaultValues.orderLocationsBy
    private var isHapticFeedbackEnabled = DefaultValues.hapticFeedback
    private var isLocationLoadEnabled = DefaultValues.showServerNetLoad
    private var hasStarted = false

    // MARK: - Dependencies
    private let hapticFeedback: HapticFeedbacking
    private let languageStoring: LanguageStoring
    private let preferencesReading: PreferencesReading
    private let preferencesWriting: PreferencesWriting
    private let pushNotifications: PushNotificationManaging

    var entries: [GeneralMenuEntryType] {
        let orderPreferences = zip(TextsAsset.orderPreferences,
                                   Fields.orderPreferences)
            .map { MenuOption(title: $0, fieldKey: $1) }
        let languages = TextsAsset.General.languages
            .map { MenuOption(title: $0, fieldKey: $0) }

        return [
            .locationOrder(currentOption: locationOrder, options: orderPreferences),
            .language(currentOption: currentLanguage, options: languages),
            .locationLoad(isSelected: isLocationLoadEnabled),
            .hapticFeedback(isSelected: isHapticFeedbackEnabled),
            .notification(title: TextsAsset.General.openSettings),
            .version(message: getVersion())
        ]
    }

    init(hapticFeedback: HapticFeedbacking,
         languageStoring: LanguageStoring,
         preferencesReading: PreferencesReading,
         preferencesWriting: PreferencesWriting,
         pushNotifications: PushNotificationManaging) {

        self.hapticFeedback = hapticFeedback
        self.languageStoring = languageStoring
        self.preferencesReading = preferencesReading
        self.preferencesWriting = preferencesWriting
        self.pushNotifications = pushNotifications

        currentLanguage = languageStoring.activeLanguage?.name ?? DefaultValues.language
        locationOrder = preferencesReading.locationOrder ?? DefaultValues.orderLocationsBy
        isHapticFeedbackEnabled = preferencesReading.isHapticFeedbackEnabled
        isLocationLoadEnabled = preferencesReading.isLocationLoadEnabled
    }

    func startObservers() async {
        guard !hasStarted else { return }
        hasStarted = true

        async let language: () = observeLanguage()
        async let locationLoad: () = observeLocationLoadEnabled()
        async let haptic: () = observeHapticFeedbackEnabled()
        async let order: () = observeLocationOrderBy()

        _ = await (language, locationLoad, haptic, order)
    }

    func observeLanguage() async {
        for await language in languageStoring.languageUpdates {
            currentLanguage = language.name
        }
    }

    func observeLocationLoadEnabled() async {
        for await enabled in preferencesReading.locationLoadUpdates {
            isLocationLoadEnabled = enabled
        }
    }

    func observeHapticFeedbackEnabled() async {
        for await enabled in preferencesReading.hapticFeedbackUpdates {
            isHapticFeedbackEnabled = enabled
        }
    }

    func observeLocationOrderBy() async {
        for await orderBy in preferencesReading.locationOrderUpdates {
            locationOrder = orderBy
        }
    }

    // MARK: - Actions (called by the view)

    func entrySelected(_ entry: GeneralMenuEntryType, action: MenuEntryActionResponseType) {
        hapticFeedback.checkSettingsAction(action: action)

        switch entry {
        case .hapticFeedback:
            if case .toggle(let isSelected, _) = action {
                preferencesWriting.saveHapticFeedback(haptic: isSelected)
            }
        case .locationLoad:
            if case .toggle(let isSelected, _) = action {
                preferencesWriting.saveShowServerNetLoad(show: isSelected)
            }
        case .locationOrder:
            if case .multiple(let currentOption, _) = action {
                preferencesWriting.saveOrderLocationsBy(order: currentOption)
            }
        case .language:
            if case .multiple(let currentOption, _) = action {
                if let language = TextsAsset.General.languagesList.first(where: { $0.name == currentOption }) {
                    languageStoring.setActiveLanguage(language: language)
                }
            }
        case .notification:
            Task { await pushNotifications.handleSettingsTap() }
        default:
            break
        }
    }

    // MARK: - Private helpers

    private func getVersion() -> String {
        guard let releaseNumber = Bundle.main.releaseVersionNumber,
              let buildNumber = Bundle.main.buildVersionNumber else { return "" }
        return "v\(releaseNumber) (\(buildNumber))"
    }
}
