//
//  WelcomeRouter.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 25/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

class WelcomeRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case RouteID.login:
            let vc = Assembler.resolve(LoginViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.signup:
            let vc = Assembler.resolve(SignUpViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.home:
            let vc = Assembler.resolve(MainViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
