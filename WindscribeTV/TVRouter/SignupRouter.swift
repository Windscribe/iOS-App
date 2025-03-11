//
//  SignupRouter.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 30/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

class SignupRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case RouteID.home:
            let vc = Assembler.resolve(MainViewController.self)
            presentAsRoot(vc: vc)
        case .signup:
            let vc = Assembler.resolve(SignUpViewController.self)
            presentAsRoot(vc: vc)
        case RouteID.forgotPassword:
            let vc = Assembler.resolve(ForgotPasswordViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
