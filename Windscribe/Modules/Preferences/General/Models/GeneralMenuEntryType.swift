//
//  GeneralMenuEntryType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 08/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum GeneralMenuEntryType: MenuEntryItemType, Hashable {
    case locationOrder(currentOption: String, options: [String]),
         language(currentOption: String, options: [String]),
         hapticFeedback(isSelected: Bool),
         notification(title: String),
         version(message: String)

    var id: Int {
        switch self {
        case .locationOrder: 1
        case .language: 2
        case .notification: 3
        case .hapticFeedback: 4
        case .version: 5
        }
    }
    var title: String {
        switch self {
        case .locationOrder: TextsAsset.General.orderLocationsBy
        case .language: TextsAsset.General.language
        case .notification: TextsAsset.General.pushNotificationSettings
        case .hapticFeedback: TextsAsset.General.hapticFeedback
        case .version: TextsAsset.General.version
        }
    }
    var icon: String {
        switch self {
        case .locationOrder: ImagesAsset.General.locationOrder
        case .language: ImagesAsset.General.language
        case .notification: ImagesAsset.notifications
        case .hapticFeedback: ImagesAsset.General.hapticFeedback
        case .version: ""
        }
    }
    var message: String? {
        switch self {
        case .locationOrder: TextsAsset.PreferencesDescription.locationOrder
        case .language: TextsAsset.PreferencesDescription.language
        case .notification: TextsAsset.PreferencesDescription.notificationStats
        case .hapticFeedback: TextsAsset.PreferencesDescription.hapticFeedback
        case let .version(message): message
        }
    }
    var mainAction: MenuEntryActionType? {
        switch self {
        case let .locationOrder(currentOption, options): .multiple(currentOption: currentOption, options: options)
        case let .language(currentOption, options): .multiple(currentOption: currentOption, options: options)
        case let .hapticFeedback(isSelected): .single(isSelected: isSelected)
        case let .notification(title): .none(title: title)
        case .version: nil
        }
    }
    var secondaryAction: [MenuEntryActionType] {
        []
    }
}
