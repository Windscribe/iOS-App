//
//  EmailRouter.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-04-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class EmailRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case let RouteID.confirmEmail(delegate):
            let vc = Assembler.resolve(ConfirmEmailViewController.self)
            vc.dismissDelegate = delegate
            from.present(vc, animated: true)
        default: ()
        }
    }
}
