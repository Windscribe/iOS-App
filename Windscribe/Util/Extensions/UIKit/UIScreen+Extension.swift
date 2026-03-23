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
    static var isSmallScreen: Bool {
        return UIScreen.main.bounds.height <= 640
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
