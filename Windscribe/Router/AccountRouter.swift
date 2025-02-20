//
//  AccountRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class AccountRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case .enterEmailVC:
            let vc = Assembler.resolve(EnterEmailViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case let .confirmEmail(delegate):
            let vc = Assembler.resolve(ConfirmEmailViewController.self)
            vc.dismissDelegate = delegate
            from.present(vc, animated: true)
        case .upgrade:
            let vc = Assembler.resolve(UpgradeViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
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

    func routeTo(to: RouteID, from: WSUIViewController) {
        switch to {
        case let .upgrade(promoCode, pcpID):
            let vc = Assembler.resolve(UpgradeViewController.self)
            vc.promoCode = promoCode
            vc.pcpID = pcpID
            if let navigationVC = from.navigationController {
                navigationVC.pushViewController(vc, animated: true)
            } else {
                from.present(vc, animated: true)
            }
        default: ()
        }
    }

    func routeToPayments(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case let .upgrade(promoCode, pcpID):
            let vc = Assembler.resolve(UpgradeViewController.self)
            vc.promoCode = promoCode
            vc.pcpID = pcpID
            DispatchQueue.main.async {
             vc.modalPresentationStyle = .fullScreen
                from.present(vc, animated: true, completion: nil)
            }
        default: ()
        }
    }
}
