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
           let window = appDelegate.window {
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
}
