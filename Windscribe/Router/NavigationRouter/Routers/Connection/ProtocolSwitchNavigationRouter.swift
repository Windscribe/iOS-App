//
//  ProtocolSwitchNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

class ProtocolSwitchNavigationRouter: BaseNavigationRouter {

    typealias Route = ProtocolSwitchRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?
    @Published var protocolName: String = ""
    @Published var viewType: ProtocolViewType = .connected

    func createView(for route: ProtocolSwitchRouteID) -> AnyView {
        switch route {
        case .protocolConnectionResult:
            let context = ProtocolConnectionResultContext()
            context.protocolName = protocolName
            context.viewType = viewType
            return AnyView(
                Assembler.resolve(ProtocolConnectionResultView.self)
                    .environmentObject(context)
            )

        case .protocolConnectionDebug:
            return AnyView(Assembler.resolve(ProtocolConnectionDebugView.self))
        }
    }

    func navigate(to destination: Route) {
        activeRoute = destination
    }

    func navigate(to destination: Route, protocolName: String, viewType: ProtocolViewType) {
        if destination == .protocolConnectionResult {
            self.protocolName = protocolName
            self.viewType = viewType
        }
        navigate(to: destination)
    }

    func pop() {
        activeRoute = nil
        protocolName = ""
        viewType = .connected
    }
}
