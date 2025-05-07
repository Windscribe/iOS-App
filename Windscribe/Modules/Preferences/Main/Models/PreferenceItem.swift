//
//  PreferenceItem.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

enum PreferenceItemType: Int, Identifiable, CaseIterable {
    case general
    case account
    case connection
    case robert
    case referForData
    case lookAndFeel
    case helpMe
    case about
    case logout

    var title: String {
        switch self {
        case .general:
            TextsAsset.Preferences.general
        case .account:
            TextsAsset.Preferences.account
        case .connection:
            TextsAsset.Preferences.connection
        case .robert:
            TextsAsset.Preferences.robert
        case .referForData:
            TextsAsset.Preferences.referForData
        case .lookAndFeel:
            TextsAsset.Preferences.lookFeel
        case .helpMe:
            TextsAsset.Preferences.helpMe
        case .about:
            TextsAsset.Preferences.about
        case .logout:
            TextsAsset.Preferences.logout
        }
    }

    var imageName: String {
        switch self {
        case .general:
            ImagesAsset.Preferences.general
        case .account:
            ImagesAsset.Preferences.account
        case .connection:
            ImagesAsset.Preferences.connection
        case .robert:
            ImagesAsset.Preferences.robert
        case .referForData:
            ImagesAsset.favEmpty
        case .lookAndFeel:
            ImagesAsset.Preferences.lookFeel
        case .helpMe:
            ImagesAsset.Preferences.helpMe
        case .about:
            ImagesAsset.Preferences.about
        case .logout:
            ImagesAsset.Preferences.logoutRed
        }
    }

    var tint: UIColor? {
        switch self {
        case .logout:
                .backgroundRed
        default:
            nil
        }
    }

    var id: Int { rawValue }
}

extension PreferenceItemType {
    var routeID: PreferencesRouteID? {
        switch self {
        case .general: return .general
        case .account: return .account
        case .connection: return .connection
        case .robert: return .robert
        case .referForData: return .referData
        case .lookAndFeel: return .lookAndFeel
        case .helpMe: return .help
        case .about: return .about
        case .logout: return nil
        }
    }
}
