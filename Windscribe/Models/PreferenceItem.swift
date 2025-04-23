//
//  PreferenceItem.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit

enum PreferenceItemType: Int {
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

    var icon: UIImage? {
        switch self {
        case .general:
            UIImage(named: ImagesAsset.Preferences.general)
        case .account:
            UIImage(named: ImagesAsset.Preferences.account)
        case .connection:
            UIImage(named: ImagesAsset.Preferences.connection)
        case .robert:
            UIImage(named: ImagesAsset.Preferences.robert)
        case .referForData:
            UIImage(named: ImagesAsset.favEmpty)
        case .lookAndFeel:
            UIImage(named: ImagesAsset.Preferences.lookFeel)
        case .helpMe:
            UIImage(named: ImagesAsset.Preferences.helpMe)
        case .about:
            UIImage(named: ImagesAsset.Preferences.about)
        case .logout:
            UIImage(named: ImagesAsset.Preferences.logoutRed)
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
}
