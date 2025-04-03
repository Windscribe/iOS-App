//
//  GeneralHelper.swift
//  Windscribe
//
//  Created by Thomas on 31/07/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import UIKit

enum GeneralOption {
    case locationOrder
    case appearance
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
}

enum GeneralHelper {
    static func getAsset(_ option: GeneralOption) -> String {
        switch option {
        case .locationOrder:
            return ImagesAsset.General.locationOrder
        case .appearance:
            return ImagesAsset.General.appearance
        case .language:
            return ImagesAsset.General.language
        case .appBackground:
            return ImagesAsset.General.appBackground
        case .notification:
            return ImagesAsset.notifications
        case .hapticFeedback:
            return ImagesAsset.General.hapticFeedback
        case .firewall:
            return ImagesAsset.General.firewall
        case .killSwitch:
            return ImagesAsset.General.killSwitch
        case .allowLan:
            return ImagesAsset.General.allowLan
        case .autoConnection:
            return ImagesAsset.General.autoSecureNew
        case .connectionMode:
            return ImagesAsset.General.connectionMode
        case .autoSecure:
            return ImagesAsset.General.autoSecure
        case .preferredProtocol:
            return ImagesAsset.General.preferredProtocol
        case .customBackground:
            return ImagesAsset.General.appBackground
        }
    }

    static func getTitle(_ option: GeneralOption) -> String {
        switch option {
        case .locationOrder:
            return TextsAsset.General.orderLocationsBy
        case .appearance:
            return TextsAsset.General.appearance
        case .language:
            return TextsAsset.General.language
        case .appBackground:
            return "App Background".localize()
        case .notification:
            return TextsAsset.General.pushNotificationSettings
        case .hapticFeedback:
            return TextsAsset.General.hapticFeedback
        case .firewall:
            return TextsAsset.firewall
        case .killSwitch:
            return TextsAsset.killSwitch
        case .allowLan:
            return TextsAsset.allowLan
        case .autoConnection:
            return TextsAsset.autoSecureNew
        case .connectionMode:
            return TextsAsset.General.connectionMode
        case .autoSecure:
            return TextsAsset.General.autoSecure
        case .preferredProtocol:
            return TextsAsset.PreferredProtocol.title
        case .customBackground:
            return TextsAsset.General.customBackground
        }
    }

    static func getDescription(_ option: GeneralOption) -> String {
        switch option {
        case .locationOrder:
            return TextsAsset.PreferencesDescription.locationOrder
        case .appearance:
            return TextsAsset.PreferencesDescription.appearance
        case .language:
            return TextsAsset.PreferencesDescription.language
        case .appBackground:
            return TextsAsset.PreferencesDescription.background
        case .notification:
            return TextsAsset.PreferencesDescription.notificationStats
        case .hapticFeedback:
            return TextsAsset.PreferencesDescription.hapticFeedback
        case .firewall:
            return TextsAsset.firewallDescription
        case .killSwitch:
            return TextsAsset.killSwitchDescription
        case .allowLan:
            return TextsAsset.allowLanDescription
        case .autoConnection:
            return TextsAsset.autoSecureNewDescription
        case .connectionMode:
            return TextsAsset.PreferencesDescription.connectionMode
        case .autoSecure:
            return TextsAsset.PreferencesDescription.autoSecure
        case .preferredProtocol:
            return TextsAsset.PreferredProtocol.newDescription
        case .customBackground:
            return TextsAsset.PreferencesDescription.customBackground
        }
    }
}
