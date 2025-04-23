//
//  LookAndFeelHelper.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-16.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import UIKit

enum LookFeelOption {
    case appearance
    case appBackground
    case soundNotification
    case version
}

enum LookAndFeelHelper {
    static func getAsset(_ option: LookFeelOption) -> String {
        switch option {
        case .appearance:
            return ImagesAsset.LookFeel.appearance
        case .appBackground:
            return ImagesAsset.LookFeel.appBackground
        case .soundNotification:
            return ImagesAsset.LookFeel.soundNotification
        default:
            return ""
        }
    }

    static func getTitle(_ option: LookFeelOption) -> String {
        switch option {
        case .appearance:
            return TextsAsset.LookFeel.appearanceTitle
        case .appBackground:
            return TextsAsset.LookFeel.appBackgroundTitle
        case .soundNotification:
            return TextsAsset.LookFeel.soundNotificationTitle
        case .version:
            return TextsAsset.LookFeel.versionTitle
        }
    }

    static func getDescription(_ option: LookFeelOption) -> String {
        switch option {
        case .appearance:
            return TextsAsset.LookFeel.appearanceDescription
        case .appBackground:
            return TextsAsset.LookFeel.appBackgroundDescription
        case .soundNotification:
            return TextsAsset.LookFeel.soundNotificationDescription
        default:
            return ""
        }
    }
}
