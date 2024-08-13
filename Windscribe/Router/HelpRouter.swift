//
//  HelpRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
class HelpRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case RouteID.viewLog:
            let vc = Assembler.resolve(ViewLogViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.submitTicket:
            let vc = Assembler.resolve(SubmitTicketViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.advanceParams:
            let vc = Assembler.resolve(AdvanceParamsViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
