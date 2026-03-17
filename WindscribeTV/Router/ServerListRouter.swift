//
//  ServerListRouter.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 22/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

class ServerListRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case let RouteID.locationListDetail(location, delegate):
            let vc = Assembler.resolve(ServerDetailViewController.self)
            vc.location = location
            vc.delegate = delegate
            from.navigationController?.pushViewController(vc, animated: true)

        default: ()
        }
    }
}
