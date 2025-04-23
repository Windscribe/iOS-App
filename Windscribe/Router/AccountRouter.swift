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
        case .enterEmailVC:
            let enterEmail = Assembler.resolve(EnterEmailView.self)
            pushViewWithoutNavigationBar(from: from, view: enterEmail)
        case let .confirmEmail(delegate):
            let vc = Assembler.resolve(ConfirmEmailViewController.self)
            vc.dismissDelegate = delegate
            from.present(vc, animated: true)
        case .upgrade:
            let planUpgradeVC = Assembler.resolve(PlanUpgradeViewController.self)
            let navigationController = UINavigationController(rootViewController: planUpgradeVC)

            DispatchQueue.main.async {
                navigationController.modalPresentationStyle = .fullScreen
                from.present(navigationController, animated: true, completion: nil)
            }
        case let .errorPopup(message, dismissAction):
            let errorVC = Assembler.resolve(ErrorPopupViewController.self)
            errorVC.viewModel.setDismissAction(with: dismissAction)
            errorVC.viewModel.setMessage(with: message)
            DispatchQueue.main.async {
                errorVC.modalPresentationStyle = .fullScreen
                from.present(errorVC, animated: true, completion: nil)
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
