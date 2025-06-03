//
//  GeneralViewType.swift
//  Windscribe
//
//  Created by Thomas on 31/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

enum GeneralViewType: SelectionViewType {
    case locationOrder
    case language
    case notification
    case hapticFeedback
    case firewall
    case killSwitch
    case allowLan
    case autoConnection
    case connectionMode
    case autoSecure
    case preferredProtocol
    case connectedDNS
    case version

    var asset: String {
        switch self {
        case .locationOrder: ImagesAsset.General.locationOrder
        case .language: ImagesAsset.General.language
        case .notification: ImagesAsset.notifications
        case .hapticFeedback: ImagesAsset.General.hapticFeedback
        case .firewall: ImagesAsset.General.firewall
        case .killSwitch: ImagesAsset.Connection.killSwitch
        case .allowLan: ImagesAsset.Connection.allowLan
        case .autoConnection: ImagesAsset.Connection.autoSecure
        case .connectionMode: ImagesAsset.Connection.connectionMode
        case .autoSecure: ImagesAsset.General.autoSecure
        case .preferredProtocol: ImagesAsset.Connection.preferredProtocol
        case .connectedDNS: ImagesAsset.customDns
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
        case .killSwitch: TextsAsset.Connection.killSwitch
        case .allowLan: TextsAsset.Connection.allowLan
        case .autoConnection: TextsAsset.autoSecureNew
        case .connectionMode: TextsAsset.Connection.connectionMode
        case .autoSecure: TextsAsset.Connection.autoSecure
        case .preferredProtocol: TextsAsset.PreferredProtocol.title
        case .connectedDNS: TextsAsset.Connection.connectedDNS
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
        case .killSwitch: TextsAsset.Connection.killSwitchDescription
        case .allowLan: TextsAsset.Connection.allowLanDescription
        case .autoConnection: TextsAsset.Connection.autoSecureNewDescription
        case .connectionMode: TextsAsset.Connection.connectionMode
        case .autoSecure: TextsAsset.Connection.autoSecure
        case .preferredProtocol: TextsAsset.PreferredProtocol.newDescription
        case .connectedDNS: TextsAsset.Connection.connectedDNSDescription
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
        case .language: .direction
        case .notification: .directionWithoutIcon
        default: .selection
        }
    }
}
