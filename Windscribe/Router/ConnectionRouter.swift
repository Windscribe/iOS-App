//
//  ConnectionRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class ConnectionRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case RouteID.networkSecurity:
            let vc = Assembler.resolve(NetworkSecurityViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case let RouteID.locationPermission(delegate, denied):
            let vc = Assembler.resolve(LocationPermissionDisclosureViewController.self)
            vc.delegate = delegate
            vc.denied = denied
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            from.present(vc, animated: true, completion: nil)
        default: ()
        }
    }
}
