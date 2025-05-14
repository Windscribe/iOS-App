//
//  Color+Ext.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-16.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import UIKit
import SwiftUI

extension UIColor {
    // Login
    static let gray = UIColor(
        red: 2 / 255.0,
        green: 13 / 255.0,
        blue: 28 / 255.0,
        alpha: 1.0
    )

    static func grayWithOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0, alpha: opacity)
    }

    static let buttonGray = UIColor(red: 54 / 255.0, green: 71 / 255.0, blue: 96 / 255.0, alpha: 1.0)

    // Main View
    static let lightMidnight = UIColor(red: 20 / 255.0, green: 27 / 255.0, blue: 35 / 255.0, alpha: 1.0)
    static let seaGreen = UIColor(red: 97 / 255.0, green: 255 / 255.0, blue: 138 / 255.0, alpha: 1.0)
    static func seaGreen(opacity: CGFloat) -> UIColor {
        return UIColor(red: 85 / 255.0, green: 255 / 255.0, blue: 138 / 255.0, alpha: opacity)
    }
    static let actionGreen = UIColor(red: 59 / 255.0, green: 255 / 255.0, blue: 239 / 255.0, alpha: 1.0)

    static func actionGreenWithOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 59 / 255.0, green: 255 / 255.0, blue: 239 / 255.0, alpha: opacity)
    }

    static let lowGreen = UIColor(red: 160 / 255.0, green: 254 / 255.0, blue: 218 / 255.0, alpha: 1.0)
    static let brightBlue = UIColor(red: 0 / 255.0, green: 106 / 255.0, blue: 255 / 255.0, alpha: 1.0)
    static let failRed = UIColor(red: 249 / 255.0, green: 76 / 255.0, blue: 67 / 255.0, alpha: 1.0)
    static let midnight = UIColor(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0, alpha: 1.0)
    static func midnightWithOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0, alpha: opacity)
    }

    static func blackWithOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 0 / 255.0, green: 0 / 255.0, blue: 0 / 255.0, alpha: opacity)
    }

    static let seperatorGray = UIColor(red: 26 / 255.0, green: 33 / 255.0, blue: 42 / 255.0, alpha: 1.0)
    static let seperatorWhite = UIColor(red: 242 / 255.0, green: 242 / 255.0, blue: 242 / 255.0, alpha: 1.0)

    // Connection Gradients
    static let connectedStartBlue = UIColor(red: 0 / 255.0, green: 106 / 255.0, blue: 255 / 255.0, alpha: 1.0)
    static let connectedEndBlue = UIColor(red: 0 / 255.0, green: 105 / 255.0, blue: 253 / 255.0, alpha: 0.0)
    static let connectingStartBlue = UIColor(red: 26 / 255.0, green: 56 / 255.0, blue: 128 / 255.0, alpha: 1.0)
    static let connectingEndBlue = UIColor(red: 26 / 255.0, green: 56 / 255.0, blue: 128 / 255.0, alpha: 0.0)
    static let disconnectedStartBlack = UIColor(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0, alpha: 1.0)
    static let disconnectedEndBlack = UIColor(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0, alpha: 0.0)

    // Failed connection
    static let failedConnectionYellow = UIColor(red: 255 / 255.0, green: 239 / 255.0, blue: 2 / 255.0, alpha: 10.0)
    static let autoModeSelectorYellow = UIColor(red: 45 / 255.0, green: 44 / 255.0, blue: 30 / 255.0, alpha: 10.0)

    // Account View
    static let unconfirmedYellow = UIColor(red: 255 / 255.0, green: 239 / 255.0, blue: 2 / 255.0, alpha: 1.0)
    static func unconfirmedYellow(opacity: CGFloat) -> UIColor {
        return UIColor(red: 255 / 255.0, green: 239 / 255.0, blue: 2 / 255.0, alpha: opacity)
    }

    // Notifications View
    static func whiteWithOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 255 / 255.0, green: 255 / 255.0, blue: 255 / 255.0, alpha: opacity)
    }

    // UpgradeView Gradients
    static let startBlue = UIColor(red: 24 / 255.0, green: 53 / 255.0, blue: 122 / 255.0, alpha: 1.0)
    static let endBlue = UIColor(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0, alpha: 1.0)

    // Background Gray
    static let backgroundGray = UIColor(red: 216 / 255.0, green: 216 / 255.0, blue: 216 / 255.0, alpha: 1.0)

    // Dark Mode
    static let darkBlack = UIColor(red: 12 / 255.0, green: 19 / 255.0, blue: 29 / 255.0, alpha: 1.0)

    static let navyBlue = UIColor(red: 26/255.0, green: 56/255.0, blue: 128/255.0, alpha: 1.0)

    // Shake For Data
    static let backgroundBlue = UIColor(red: 0 / 255.0, green: 106 / 255.0, blue: 255 / 255.0, alpha: 1.0)
    static let backgroundOrange = UIColor(red: 255 / 255.0, green: 142 / 255.0, blue: 0 / 255.0, alpha: 1.0)
    static let backgroundRed = UIColor(red: 255 / 255.0, green: 59 / 255.0, blue: 59 / 255.0, alpha: 1.0)

    // Mail
    static let pumpkinOrange = UIColor(red: 242 / 255.0, green: 139 / 255.0, blue: 0 / 255.0, alpha: 1.0)
    static func pumpkinOrangeWithOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 242 / 255.0, green: 139 / 255.0, blue: 0 / 255.0, alpha: opacity)
    }

    // Plan Upgrade - Subscription Views
    static let planUpgradeBackground = UIColor(red: 9 / 255.0, green: 14 / 255.0, blue: 25 / 255.0, alpha: 1.0)
    static let planUpgradeSelectionHighlight = UIColor(red: 202 / 255.0, green: 223 / 255.0, blue: 242 / 255.0, alpha: 1.0)
    static let planUpgradeSelectionShadow = UIColor(red: 0 / 255.0, green: 221 / 255.0, blue: 255 / 255.0, alpha: 0.53)
}

extension Color {
    // News Feed
    static let newsFeedButtonActionColor = Color(red: 85 / 255.0, green: 255 / 255.0, blue: 138 / 255.0)
    static let newsFeedDetailExpandedBackgroundColor = Color(red: 32 / 255.0, green: 34 / 255.0, blue: 40 / 255.0)
    static let newsFeedDetailBackgroundColor = Color(red: 24 / 255.0, green: 27 / 255.0, blue: 33 / 255.0)
    static let newsFeedSeperatorColor = Color(red: 11 / 255.0, green: 15 / 255.0, blue: 22 / 255.0)

    // Welcome
    static let welcomeButtonTextColor = Color(red: 131 / 255.0, green: 141 / 255.0, blue: 155 / 255.0)
    static let welcomeEmergencyButtonColor = Color(red: 97 / 255.0, green: 255 / 255.0, blue: 138 / 255.0)

    // Login - Register
    static let loginRegisterFailedField = Color(red: 249 / 255.0, green: 76 / 255.0, blue: 67 / 255.0)
    static let loginRegisterEnabledButtonColor = Color(red: 85 / 255.0, green: 255 / 255.0, blue: 138 / 255.0)
    static let loginRegisterBackgroundColor = Color(red: 11 / 255.0, green: 15 / 255.0, blue: 22 / 255.0)

    // General Usage Colors
    static let lightMidnight = Color(red: 20 / 255.0, green: 27 / 255.0, blue: 35 / 255.0)
    static let midnight = Color(red: 2 / 255.0, green: 13 / 255.0, blue: 28 / 255.0)

    static let nightBlue = Color(red: 5 / 255.0, green: 10 / 255.0, blue: 17 / 255.0)
    static let unconfirmedYellow = Color(red: 255 / 255.0, green: 239 / 255.0, blue: 2 / 255.0)
    static let seaGreen = Color(red: 97 / 255.0, green: 255 / 255.0, blue: 138 / 255.0)
}

// New Memefication Colors

extension UIColor {
    // Night Blue
    static let nightBlue = UIColor(red: 5 / 255.0, green: 10 / 255.0, blue: 17 / 255.0, alpha: 1.0)

    static func nightBlueOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 5 / 255.0, green: 10 / 255.0, blue: 17 / 255.0, alpha: opacity)
    }

    // Cyber Blue
    static let cyberBlue = UIColor(red: 59 / 255.0, green: 255 / 255.0, blue: 239 / 255.0, alpha: 1.0)

    static func cyberBlueWithOpacity(opacity: CGFloat) -> UIColor {
        return UIColor(red: 59 / 255.0, green: 255 / 255.0, blue: 239 / 255.0, alpha: opacity)
    }
}
