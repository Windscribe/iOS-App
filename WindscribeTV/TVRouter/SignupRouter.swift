//
//  SignupRouter.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 30/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class SignupRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case RouteID.home:
            let vc = Assembler.resolve(MainViewController.self)
            vc.modalPresentationStyle = .fullScreen
            //vc.appJustStarted = true
            //vc.userJustLoggedIn = true
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
        case RouteID.forgotPassword:
            let vc = Assembler.resolve(ForgotPasswordViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
