//
//  Router.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 25/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import UIKit

protocol RootRouter {
    func routeTo(to: RouteID, from: UIViewController)
}

extension RootRouter {
    func presentAsRoot(vc: UIViewController) {
        vc.modalPresentationStyle = .fullScreen
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           let window = appDelegate.window
        {
            window.rootViewController?.dismiss(animated: false,
                                               completion: nil)
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                                  window.rootViewController = UINavigationController(rootViewController: vc)
                              }, completion: nil)
        }
    }

    func presentInNavigationController(vc: UIViewController, from: UIViewController) {
        let navigationController = UINavigationController()
        navigationController.setViewControllers([vc], animated: false)
        from.present(navigationController, animated: true)
    }

    func presentWithPossibleNavigation(vc: UIViewController, from: UIViewController, shouldBeRoot: Bool = true) {
        if let navigationVC = from.navigationController, shouldBeRoot {
            navigationVC.setViewControllers([vc], animated: true)
        } else {
            from.present(vc, animated: true)
        }
    }
}
