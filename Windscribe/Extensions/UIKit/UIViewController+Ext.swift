//
//  UIViewController+ext.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-02-14.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit

extension UIViewController {

    /// Checks if the current device has a regular size class (typically iPads).
    var isRegularSizeClass: Bool {
        return traitCollection.horizontalSizeClass == .regular
    }

    /// Checks if the device is in Portrait mode.
    var isPortrait: Bool {
        return currentInterfaceOrientation?.isPortrait ?? false
    }

    /// Checks if the device is in Landscape mode.
    var isLandscape: Bool {
        return currentInterfaceOrientation?.isLandscape ?? false
    }

    /// Gets the current interface orientation safely
    private var currentInterfaceOrientation: UIInterfaceOrientation? {
        return view.window?.windowScene?.interfaceOrientation ??
               UIApplication.shared.connectedScenes
                   .compactMap { ($0 as? UIWindowScene)?.interfaceOrientation }
                   .first
    }
}
