//
//  WelcomeRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject

class WelcomeRouter: BaseRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case RouteID.login:
            let vc = Assembler.resolve(LoginViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.signup:
            let vc = Assembler.resolve(SignUpViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.emergency:
            let vc = Assembler.resolve(EmergencyConnectViewController.self)
            vc.modalPresentationStyle = .overCurrentContext
            from.present(vc, animated: true)
        case RouteID.home:
            goToHome()
        default: ()
        }
    }
}
