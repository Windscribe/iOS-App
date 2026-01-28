//
//  DiscreetAppIconSelectionViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2026-01-16.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Combine

protocol DiscreetAppIconSelectionViewModel: PreferencesBaseViewModel {
    var iconOptions: [DiscreetAppIconType] { get }
    var selectedIcon: DiscreetAppIconType { get set }

    func iconSelected(_ icon: DiscreetAppIconType)
}

final class DiscreetAppIconSelectionViewModelImpl: PreferencesBaseViewModelImpl, DiscreetAppIconSelectionViewModel {
    @Published var iconOptions: [DiscreetAppIconType] = DiscreetAppIconType.allCases
    @Published var selectedIcon: DiscreetAppIconType = .og


    private let preferences: Preferences

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences) {
        self.preferences = preferences

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)

        loadCurrentIcon()
    }

    private func loadCurrentIcon() {
        if let savedIconValue = preferences.getCustomAppIcon() {
            selectedIcon = DiscreetAppIconType.fromRaw(value: savedIconValue)
        } else {
            selectedIcon = .og
        }
    }

    func iconSelected(_ icon: DiscreetAppIconType) {
        selectedIcon = icon
        saveAndChangeIcon(icon)
    }

    private func saveAndChangeIcon(_ icon: DiscreetAppIconType) {
        preferences.saveCustomAppIcon(value: icon.preferenceValue)

        guard UIApplication.shared.supportsAlternateIcons else {
            logger.logE("DiscreetAppIconSelectionViewModel", "Alternate icons not supported")
            return
        }

        let iconName: String? = icon == .og ? nil : icon.assetCatalogName
        UIApplication.shared.setAlternateIconName(iconName) { [weak self] error in
            if let error = error {
                self?.logger.logE("DiscreetAppIconSelectionViewModel", "Failed to change app icon: \(error.localizedDescription)")
            } else {
                self?.logger.logI("DiscreetAppIconSelectionViewModel", "Successfully changed app icon to: \(icon.preferenceValue)")
            }
        }
    }
}
