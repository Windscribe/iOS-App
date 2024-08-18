//
//  HomeRouter.swift
//  WindscribeTV
//
//  Created by Ginder Singh on 2024-08-18.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
class HomeRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
            case RouteID.preferences:
                let vc = Assembler.resolve(PreferencesMainViewController.self)
                from.present(vc, animated: true)
            default: ()
        }
    }
}
