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
    case robert
    case connection
    case referForData
    case helpMe
    case about
    case logout

    var title: String {
        switch self {
        case .general:
            TextsAsset.Preferences.general
        case .account:
            TextsAsset.Preferences.account
        case .robert:
            TextsAsset.Preferences.robert
        case .connection:
            TextsAsset.Preferences.connection
        case .referForData:
            TextsAsset.Preferences.referForData
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
        case .robert:
            UIImage(named: ImagesAsset.Preferences.robert)
        case .connection:
            UIImage(named: ImagesAsset.Preferences.connection)
        case .referForData:
            UIImage(named: ImagesAsset.favEmpty)
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
