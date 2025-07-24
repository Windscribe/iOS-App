//
//  AccountRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

class AccountRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case .enterEmail:
            let enterEmail = Assembler.resolve(EnterEmailView.self)
            pushViewWithoutNavigationBar(from: from, view: enterEmail)
        case .confirmEmail:
            let confirmEmail = Assembler.resolve(ConfirmEmailView.self)
            pushViewWithoutNavigationBar(from: from, view: confirmEmail)
        case .upgrade:
            let planUpgradeVC = Assembler.resolve(PlanUpgradeViewController.self)
            let navigationController = UINavigationController(rootViewController: planUpgradeVC)

            DispatchQueue.main.async {
                navigationController.modalPresentationStyle = .fullScreen
                from.present(navigationController, animated: true, completion: nil)
            }
        default: ()
        }
    }

    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case let .upgrade(promoCode, pcpID):
            let planUpgradeVC = Assembler.resolve(PlanUpgradeViewController.self).then {
                $0.promoCode = promoCode
                $0.pcpID = pcpID
            }

            let navigationController = UINavigationController(rootViewController: planUpgradeVC)

            DispatchQueue.main.async {
                navigationController.modalPresentationStyle = .fullScreen
                from.present(navigationController, animated: true, completion: nil)
            }
        default: ()
        }
    }
}
