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
        case .confirmEmail:
            let confirmEmail = Assembler.resolve(ConfirmEmailView.self)
            pushViewWithoutNavigationBar(from: from, view: confirmEmail)
        default: ()
        }
    }
}
