//
//  UpgradeRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class UpgradeRouter: BaseRouter, RootRouter {
    func routeTo(to: RouteID, from: WSUIViewController) {
        switch to {
        case RouteID.enterEmail:
            let vc = Assembler.resolve(EnterEmailViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case let RouteID.confirmEmail(delegate):
            let vc = Assembler.resolve(ConfirmEmailViewController.self)
            vc.dismissDelegate = delegate
            from.present(vc, animated: true)
        case let RouteID.signup(claimGhostAccount):
            goToSignUp(viewController: from, claimGhostAccount: claimGhostAccount)
        default: ()
        }
    }
}
