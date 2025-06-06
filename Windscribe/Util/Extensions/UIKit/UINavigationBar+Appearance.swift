//
//  UINavigationBar+Appearance.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-06-05.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

extension UINavigationBar {
    static func setStyleNavigationBackButton(isDarkMode: Bool) {
        let titleColor = UIColor(.from(.titleColor, isDarkMode))
        let navigationBarBackgroundColor = UIColor(.from(.screenBackgroundColor, isDarkMode))

        let appearance = UINavigationBarAppearance().then {
            $0.configureWithOpaqueBackground()
            $0.backgroundColor = navigationBarBackgroundColor
            $0.titleTextAttributes = [.foregroundColor: titleColor]
            $0.shadowColor = .clear
        }

        let backButtonAppearance = UIBarButtonItemAppearance().then {
            $0.normal.titleTextAttributes = [.foregroundColor: UIColor.clear]
            $0.highlighted.titleTextAttributes = [.foregroundColor: UIColor.clear]
        }

        appearance.backButtonAppearance = backButtonAppearance

        if let backImage = UIImage(named: "back_chevron") {
            appearance.setBackIndicatorImage(backImage, transitionMaskImage: backImage)
        }

        UINavigationBar.appearance().do {
            $0.tintColor = titleColor
            $0.isTranslucent = false
            $0.standardAppearance = appearance
            $0.scrollEdgeAppearance = appearance
            $0.compactAppearance = appearance
            $0.compactScrollEdgeAppearance = appearance
        }

        UIBarButtonItem.appearance().tintColor = titleColor
    }
}
