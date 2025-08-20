//
//  PreferenceItem.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-01.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import SwiftUI

enum PreferenceItemType: Int, MenuCategoryRowType {
    case general
    case account
    case connection
    case robert
    case referForData
    case lookAndFeel
    case helpMe
    case about
    case screenTest
    case logout

    var id: Int { rawValue }
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
        case .screenTest:
            "Screen Test"
        case .logout:
            TextsAsset.Preferences.logout
        }
    }

    var imageName: String? {
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
        case .screenTest:
            ImagesAsset.Preferences.screenTest
        case .logout:
            ImagesAsset.Preferences.logout
        }
    }

    var actionImageName: String? {
        switch self {
        case .logout:
            nil
        default:
            ImagesAsset.serverWhiteRightArrow
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

    func tintColor(_ isDarkMode: Bool) -> Color {
        switch self {
        case .logout: .orangeYellow
        default: .from(.titleColor, isDarkMode)
        }
    }
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
        case .screenTest: return .screenTest
        case .logout: return nil
        }
    }
}
