//
//  Color+Theme.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/06/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

enum MenuColorsType {
    case backgroundColor
    case iconColor
    case titleColor
    case separatorColor
    case infoColor
    case screenBackgroundColor
    case allowedColor(isEnabled: Bool)
    case actionBackgroundColor
    case dark
    case popUpBackgroundColor
    case captchaBackgroundColor
}

enum MainColorsType {
    case iconColor
    case gradientStartColor
    case gradientEndColor
    case gradientBorderColor
    case infoColor
    case backgroundColor
    case textColor
    case pressStateColor
    case locationColor
    case loadCircleColor
    case placeholderColor
}

extension Color {
    static func from(_ colorType: MenuColorsType,_ isDarkMode: Bool) -> Color {
        switch colorType {
        case .backgroundColor:
            return isDarkMode ? .white.opacity(0.05) : .nightBlue.opacity(0.1)
        case .iconColor,
                .titleColor:
            return isDarkMode ? .white : .nightBlue
        case .separatorColor,
                .screenBackgroundColor,
                .actionBackgroundColor:
            return isDarkMode ? .nightBlue : .white
        case .infoColor:
            return .infoGrey
        case .dark:
            return isDarkMode ? .black : .infoGrey
        case .allowedColor(let isEnabled):
            if isEnabled {
                return .positiveGreen
            } else {
                return .infoGrey
            }
        case .popUpBackgroundColor:
            return isDarkMode ? .grayishDarkColor : .white
        case .captchaBackgroundColor:
            return isDarkMode ? .deepSlate : .white
        }
    }
}

extension UIColor {
    static func from(_ colorType: MainColorsType,_ isDarkMode: Bool) -> UIColor {
        switch colorType {
        case .iconColor, .textColor:
            return isDarkMode ? .white : .nightBlue
        case .gradientStartColor:
            return isDarkMode ? .nightBlueOpacity(opacity: 0.3) : .white
        case .gradientEndColor:
            return isDarkMode ? .nightBlue : .whiteWithOpacity(opacity: 0.9)
        case .backgroundColor:
            return isDarkMode ? .nightBlue : .white
        case .gradientBorderColor:
            return isDarkMode ? .whiteWithOpacity(opacity: 0.1) :
                .nightBlueOpacity(opacity: 0.1)
        case .infoColor:
            return isDarkMode ? .whiteWithOpacity(opacity: 0.7) : .infoGray
        case .pressStateColor:
            return isDarkMode ? .whiteWithOpacity(opacity: 0.05) : .nightBlueOpacity(opacity: 0.05)
        case .locationColor:
            return isDarkMode ? .white : .infoGray
        case .loadCircleColor:
            return isDarkMode ? .whiteWithOpacity(opacity: 0.1) :
                .nightBlueOpacity(opacity: 0.2)
        case .placeholderColor:
            return isDarkMode ? .whiteWithOpacity(opacity: 0.5) :
                .nightBlueOpacity(opacity: 0.5)
        }
    }
}
