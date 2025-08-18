//
//  ProtocolSwitchRouter.swift
//  Windscribe
//
//  Created by Bushra Sagir on 10/04/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI
import Swinject

class ProtocolSwitchRouter: BaseRouter, RootRouter {
    func routeTo(to: RouteID, from: WSUIViewController) {
        switch to {
        case let RouteID.protocolConnectionResult(protocolName, viewType):
            let router = Assembler.resolve(ProtocolSwitchNavigationRouter.self)
            let view = Assembler.resolve(ProtocolConnectionResultView.self)
            let context = ProtocolConnectionResultContext()
            context.protocolName = protocolName
            context.viewType = viewType

            let hostingController = UIHostingController(rootView:
                view.environmentObject(context)
                    .environmentObject(router)
            )

            if viewType == .fail {
                from.navigationController?.pushViewController(hostingController, animated: true)
            } else {
                hostingController.modalPresentationStyle = .fullScreen
                from.present(hostingController, animated: true)
            }
            return

        case RouteID.protocolConnectionDebug:
            let view = Assembler.resolve(ProtocolConnectionDebugView.self)
            let hostingController = UIHostingController(rootView: view)
            hostingController.modalPresentationStyle = .overFullScreen
            hostingController.modalTransitionStyle = .crossDissolve
            from.present(hostingController, animated: true)
            return

        case let RouteID.protocolSwitch(type, error):
            let context = ProtocolSwitchContext()
            context.fallbackType = type
            context.error = error
            let view = Assembler.resolve(ProtocolSwitchView.self)
            let hostingController = UIHostingController(rootView:
                view.environmentObject(context)
            )
            from.navigationController?.pushViewController(hostingController, animated: true)
            return

        default: return
        }
    }
}
