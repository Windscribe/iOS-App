//
//  LoginRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
class LoginRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from _: WSNavigationViewController) {
        switch to {
        case RouteID.home:
            goToHome()
        default: ()
        }
    }
}
