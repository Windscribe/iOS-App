//
//  GeneralHelper.swift
//  Windscribe
//
//  Created by Thomas on 31/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

enum SelectionViewType {
    case locationOrder
    case language
    case appBackground
    case notification
    case hapticFeedback
    case firewall
    case killSwitch
    case allowLan
    case autoConnection
    case connectionMode
    case autoSecure
    case preferredProtocol
    case customBackground
    case connectedDNS
    case exportLocations
    case importLocations
    case appearance
    case soundNotification
    case version

    var asset: String {
        switch self {
        case .locationOrder: ImagesAsset.General.locationOrder
        case .language: ImagesAsset.General.language
        case .appBackground: ImagesAsset.LookFeel.appBackground
        case .notification: ImagesAsset.notifications
        case .hapticFeedback: ImagesAsset.General.hapticFeedback
        case .firewall: ImagesAsset.General.firewall
        case .killSwitch: ImagesAsset.General.killSwitch
        case .allowLan: ImagesAsset.General.allowLan
        case .autoConnection: ImagesAsset.General.autoSecureNew
        case .connectionMode: ImagesAsset.General.connectionMode
        case .autoSecure: ImagesAsset.General.autoSecure
        case .preferredProtocol: ImagesAsset.General.preferredProtocol
        case .customBackground: ImagesAsset.General.appBackground
        case .connectedDNS: ImagesAsset.customDns
        case .exportLocations: ImagesAsset.Servers.serversAll
        case .importLocations: ImagesAsset.Servers.allSelected
        case .appearance: ImagesAsset.LookFeel.appearance
        case .soundNotification: ImagesAsset.LookFeel.soundNotification
        default: ""
        }
    }

    var title: String {
        switch self {
        case .locationOrder: TextsAsset.General.orderLocationsBy
        case .language: TextsAsset.General.language
        case .notification: TextsAsset.General.pushNotificationSettings
        case .hapticFeedback: TextsAsset.General.hapticFeedback
        case .firewall: TextsAsset.firewall
        case .killSwitch: TextsAsset.killSwitch
        case .allowLan: TextsAsset.allowLan
        case .autoConnection: TextsAsset.autoSecureNew
        case .connectionMode: TextsAsset.General.connectionMode
        case .autoSecure: TextsAsset.General.autoSecure
        case .preferredProtocol: TextsAsset.PreferredProtocol.title
        case .customBackground: TextsAsset.General.customBackground
        case .connectedDNS: TextsAsset.connectedDNS
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
        case .locationOrder: TextsAsset.PreferencesDescription.locationOrder
        case .language: TextsAsset.PreferencesDescription.language
        case .notification: TextsAsset.PreferencesDescription.notificationStats
        case .hapticFeedback: TextsAsset.PreferencesDescription.hapticFeedback
        case .firewall: TextsAsset.firewallDescription
        case .killSwitch: TextsAsset.killSwitchDescription
        case .allowLan: TextsAsset.allowLanDescription
        case .autoConnection: TextsAsset.autoSecureNewDescription
        case .connectionMode: TextsAsset.PreferencesDescription.connectionMode
        case .autoSecure: TextsAsset.PreferencesDescription.autoSecure
        case .preferredProtocol: TextsAsset.PreferredProtocol.newDescription
        case .customBackground: TextsAsset.PreferencesDescription.customBackground
        case .connectedDNS: TextsAsset.connectedDNSDescription
        case .exportLocations: TextsAsset.CustomLocationNames.exportLocationsDesc
        case .importLocations: TextsAsset.CustomLocationNames.importLocationsDesc
        case .appBackground: TextsAsset.LookFeel.appBackgroundDescription
        case .appearance: TextsAsset.LookFeel.appearanceDescription
        case .soundNotification: TextsAsset.LookFeel.soundNotificationDescription
        case .version: ""
        }
    }

    var listOption: [String] {
        switch self {
        case .locationOrder: TextsAsset.orderPreferences
        case .language: TextsAsset.General.languages
        case .connectionMode: TextsAsset.connectionModes
        case .connectedDNS: TextsAsset.connectedDNSOptions
        default:
            []
        }
    }

    var type: SelectableViewType {
        switch self {
        case .language, .exportLocations, .importLocations: .direction
        case .notification: .directionWithoutIcon
        default: .selection
        }
    }
}
