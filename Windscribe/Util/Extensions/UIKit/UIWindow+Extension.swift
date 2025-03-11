//
//  UIWindow+Ext.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-01-31.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import UIKit

extension UIWindow {
    /// Computed property to get the currently visible (active) view controller
    var activeViewController: UIViewController? {
        guard let rootViewController = self.rootViewController else { return nil }
        return getTopViewController(from: rootViewController)
    }

    /// Recursive function to traverse the view controller hierarchy
    private func getTopViewController(from viewController: UIViewController) -> UIViewController {
        if let presentedViewController = viewController.presentedViewController {
            return getTopViewController(from: presentedViewController)
        } else if let navigationController = viewController as? UINavigationController {
            return getTopViewController(from: navigationController.visibleViewController ?? navigationController)
        } else if let tabBarController = viewController as? UITabBarController {
            return getTopViewController(from: tabBarController.selectedViewController ?? tabBarController)
        }
        return viewController
    }
}
