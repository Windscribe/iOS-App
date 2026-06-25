//
//  PreferencesMainEntryType.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI

@available(iOS 17.0, *)
enum PreferencesMainEntryType: Int, MenuCategoryRowType {
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

    func tintColor(_ isDarkMode: Bool) -> Color {
        switch self {
        case .logout:
            .deepOrange
        default:
            .from(.titleColor, isDarkMode)
        }
    }

    func backgroundTintColor(_ isDarkMode: Bool) -> Color {
        switch self {
        case .logout:
            tintColor(isDarkMode).opacity(0.15)
        default:
            .from(.preferencesBackgroundColor, isDarkMode)
        }
    }

    var routeID: PreferencesRouteID? {
        switch self {
        case .general: .general
        case .account: .account
        case .connection: .connection
        case .robert: .robert
        case .referForData: .referData
        case .lookAndFeel: .lookAndFeel
        case .helpMe: .help
        case .about: .about
        case .screenTest: .screenTest
        case .logout: nil
        }
    }
}
