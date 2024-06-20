//
//  GeneralRouter.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-03-13.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class GeneralRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case .language:
            let vc = Assembler.resolve(LanguageViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
