//
//  UIScreen+Ext.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-03-08.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension UIScreen {
    static var activeScreen: UIScreen {
        // Try to find an active window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene }).first {
            return windowScene.screen
        }

        // Fallback: When app is backgrounded, scenes can be disconnected
        // Return main screen instead of crashing
        return UIScreen.main
    }

    static var isSmallScreen: Bool {
        return UIScreen.activeScreen.bounds.height <= 640
    }

    class var hasTopNotch: Bool {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first else {
            return false
        }
        return window.safeAreaInsets.top > 24
    }

    class var topSpace: CGFloat {
        if UIScreen.hasTopNotch {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first {
                return window.safeAreaInsets.top
            }
            return 59
        } else if UIDevice.current.isIpad {
            return 20
        }
        return 16
    }
}
