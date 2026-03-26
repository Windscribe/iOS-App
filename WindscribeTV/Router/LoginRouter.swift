//
//  LoginRouter.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 25/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

class LoginRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case RouteID.home:
            let vc = Assembler.resolve(MainViewController.self)
            let windowProvider: WindowProvider = Assembler.resolve(WindowProvider.self)
            if let window = windowProvider.mainWindow {
                vc.modalPresentationStyle = .fullScreen
                window.rootViewController?.dismiss(animated: false,
                                                   completion: nil)
                UIView.transition(with: window,
                                  duration: 0.3,
                                  options: .transitionCrossDissolve,
                                  animations: {
                                      window.rootViewController = UINavigationController(rootViewController: vc)
                                  }, completion: nil)
            }
        case RouteID.forgotPassword:
            let vc = Assembler.resolve(ForgotPasswordViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
