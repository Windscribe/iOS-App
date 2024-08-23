//
//  ServerListRouter.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 22/08/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Foundation
import Swinject

class ServerListRouter: RootRouter {
    func routeTo(to: RouteID, from: UIViewController) {
        switch to {
        case let RouteID.serverListDetail(server):
            let vc = Assembler.resolve(ServerDetailViewController.self)
            vc.server = server
            from.present(vc, animated: true)
        
        default: ()
        }
    }
}
