//
//  LookAndFeelViewType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/04/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum LookAndFeelViewType: SelectionViewType {
    case appBackground
    case exportLocations
    case importLocations
    case appearance
    case soundNotification
    case version

    var asset: String {
        switch self {
        case .appBackground: ImagesAsset.LookFeel.appBackground
        case .exportLocations: ImagesAsset.Servers.serversAll
        case .importLocations: ImagesAsset.Servers.allSelected
        case .appearance: ImagesAsset.LookFeel.appearance
        case .soundNotification: ImagesAsset.LookFeel.soundNotification
        case .version: ""
        }
    }

    var title: String {
        switch self {
        case .exportLocations: TextsAsset.CustomLocationNames.exportLocations
        case .importLocations: TextsAsset.CustomLocationNames.importLocations
        case .appBackground: TextsAsset.LookFeel.appBackgroundTitle
        case .appearance: TextsAsset.LookFeel.appearanceTitle
        case .soundNotification: TextsAsset.LookFeel.soundNotificationTitle
        case .version: TextsAsset.LookFeel.versionTitle
        }
    }

    var description: String {
        switch self {
        case .exportLocations: TextsAsset.CustomLocationNames.exportLocationsDesc
        case .importLocations: TextsAsset.CustomLocationNames.importLocationsDesc
        case .appBackground: TextsAsset.LookFeel.appBackgroundDescription
        case .appearance: TextsAsset.LookFeel.appearanceDescription
        case .soundNotification: TextsAsset.LookFeel.soundNotificationDescription
        case .version: ""
        }
    }

    var listOption: [String] {
        if self == .appearance {
            return TextsAsset.appearances
        }
        return []
    }

    var type: SelectableViewType {
        switch self {
        case .exportLocations, .importLocations: .direction
        default: .selection
        }
    }
}
