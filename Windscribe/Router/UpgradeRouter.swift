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
        case .enterEmail:
            let enterEmail = Assembler.resolve(EnterEmailView.self)
            pushViewWithoutNavigationBar(from: from, view: enterEmail)
        case .confirmEmail:
            let confirmEmail = Assembler.resolve(ConfirmEmailView.self)
            pushViewWithoutNavigationBar(from: from, view: confirmEmail)
        case let RouteID.signup(claimGhostAccount):
            goToSignUp(viewController: from, claimGhostAccount: claimGhostAccount)
        default: ()
        }
    }
}
