//
//  MenuThemeManagerRepository.swift
//  Windscribe
//
//  Created by Andre Fonseca on 02/06/2025.
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
            return isDarkMode ? .infoGrey : .darkInfoColor
        case .dark:
            return isDarkMode ? .black : .infoGrey
        case .allowedColor(let isEnabled):
             if isEnabled {
                 return .eletricBlue
            } else {
                return isDarkMode ? .infoGrey : .darkInfoColor
            }
        }
    }
}
