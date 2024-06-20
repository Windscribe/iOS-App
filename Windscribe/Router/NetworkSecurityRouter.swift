//
//  NetworkSecurityRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class NetworkSecurityRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case let RouteID.network(network):
            let vc = Assembler.resolve(NetworkViewController.self)
            vc.viewModel.displayingNetwork = network
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
