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
        return UIApplication.shared.delegate?.window??.safeAreaInsets.top ?? 0 > 24
    }
}

var topSpace: CGFloat {
    if UIScreen.hasTopNotch {
        return 0
    }

    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
       let statusBarHeight = windowScene.statusBarManager?.statusBarFrame.height {
        return statusBarHeight
    }

    return 0
}
