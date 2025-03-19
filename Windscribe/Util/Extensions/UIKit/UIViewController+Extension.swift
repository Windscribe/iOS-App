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
#if os(iOS)
        return currentInterfaceOrientation?.isPortrait ?? false
#elseif os(tvOS)
        return false
#endif
    }

    /// Checks if the device is in Landscape mode.
    var isLandscape: Bool {
#if os(iOS)
        return currentInterfaceOrientation?.isLandscape ?? false
#elseif os(tvOS)
        return true
#endif
    }

#if os(iOS)
    /// Gets the current interface orientation safely
    private var currentInterfaceOrientation: UIInterfaceOrientation? {
        return view.window?.windowScene?.interfaceOrientation ??
               UIApplication.shared.connectedScenes
                   .compactMap { ($0 as? UIWindowScene)?.interfaceOrientation }
                   .first
    }
#endif
}

extension UIViewController {

    /// Finding Top View Controller.
    func topMostViewController() -> UIViewController {
        if let presentedViewController = presentedViewController {
            return presentedViewController.topMostViewController()
        }
        if let navigationController = self as? UINavigationController {
            return navigationController.visibleViewController?.topMostViewController() ?? navigationController
        }
        if let tabBarController = self as? UITabBarController {
            return tabBarController.selectedViewController?.topMostViewController() ?? tabBarController
        }
        return self
    }
}

extension UIApplication {

    /// Finding Top View Controller for connected scenes
    func topMostViewController() -> UIViewController? {
        guard let windowScene = connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }

        var topController = rootVC
        while let presentedVC = topController.presentedViewController {
            topController = presentedVC
        }

        return topController
    }
}
