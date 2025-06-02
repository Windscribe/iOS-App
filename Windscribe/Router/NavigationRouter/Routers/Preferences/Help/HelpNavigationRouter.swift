//
//  HelpNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

class HelpNavigationRouter: BaseNavigationRouter {

    typealias Route = HelpRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?

    func createView(for route: HelpRouteID) -> AnyView {
        switch route {
        case .sendTicket:
            return AnyView(Assembler.resolve(SendTicketView.self))
        case .advancedParameters:
            return AnyView(Assembler.resolve(AdvancedParametersView.self))
        case .debugLog:
            return AnyView(Assembler.resolve(DebugLogView.self))
        }
    }

    func navigate(to destination: Route) {
        if let navVC = UIApplication.shared.topMostViewController()?.navigationController {
            navVC.topViewController?.navigationItem.backBarButtonItem =
                UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        }

        activeRoute = destination
    }

    func pop() {
        activeRoute = nil
    }
}
