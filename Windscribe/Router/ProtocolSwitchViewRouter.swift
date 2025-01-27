//
//  ProtocolSwitchViewRouter.swift
//  Windscribe
//
//  Created by Bushra Sagir on 10/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject

class ProtocolSwitchViewRouter: BaseRouter, RootRouter {
    func routeTo(to: RouteID, from: WSUIViewController) {
        switch to {
        case let RouteID.sendDebugLogCompleted(delegate):
            let vc = Assembler.resolve(SendDebugLogCompletedViewController.self)
            vc.delegate = delegate
            vc.modalPresentationStyle = .overFullScreen
            vc.modalTransitionStyle = .crossDissolve
            from.present(vc, animated: true)
        case let RouteID.protocolSetPreferred(type, delegate, protocolName):
            let vc = Assembler.resolve(ProtocolSetPreferredViewController.self)
            vc.delegate = delegate
            vc.type = type
            vc.protocolName = protocolName
            if type == .fail {
                from.navigationController?.pushViewController(vc, animated: true)
            } else {
                vc.modalPresentationStyle = .fullScreen
                from.present(vc, animated: true)
            }
        default: return
        }
    }
}
