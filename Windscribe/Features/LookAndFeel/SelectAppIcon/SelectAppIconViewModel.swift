//
//  SelectAppIconViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 03/06/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation
import UIKit

@available(iOS 17.0, *)
@Observable
@MainActor
final class SelectAppIconViewModel {
    var iconOptions: [DiscreetAppIconType] = DiscreetAppIconType.allCases
    var selectedIcon: DiscreetAppIconType = .og

    private let logger: any LogStoring
    private let preferencesReading: PreferencesReading
    private let preferencesWriting: PreferencesWriting

    init(logger: LogStoring,
         preferencesReading: PreferencesReading,
         preferencesWriting: PreferencesWriting) {
        self.preferencesReading = preferencesReading
        self.preferencesWriting = preferencesWriting
        self.logger = logger

        loadCurrentIcon()
    }

    private func loadCurrentIcon() {
        if let savedIconValue = preferencesReading.getCustomAppIcon() {
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
        preferencesWriting.saveCustomAppIcon(value: icon.preferenceValue)

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
