//
//  GhostAccountRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import UIKit
import Swinject

class GhostAccountRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case RouteID.signup:
            goToSignUp(viewController: from)
        case RouteID.upgrade:
            let planUpgradeVC = Assembler.resolve(PlanUpgradeViewController.self)
            let upgradeNavigationViewController = UINavigationController(rootViewController: planUpgradeVC).then{
                $0.modalPresentationStyle = .fullScreen
            }
            from.present(upgradeNavigationViewController, animated: true)
        case RouteID.login:
            let vc = Assembler.resolve(LoginViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
