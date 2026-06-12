//
//  ConnectionsNavigationRouter.swift
//  Windscribe
//
//  Created by Andre Fonseca on 30/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

class ConnectionsNavigationRouter: BaseNavigationRouter {
    typealias Route = ConnectionsRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?

    func createView(for route: ConnectionsRouteID) -> AnyView {
        if #available(iOS 17.0, *) {
            return newCreateView(for: route)
        } else {
            return oldCreateView(for: route)
        }
    }

    private func oldCreateView(for route: ConnectionsRouteID) -> AnyView {
        switch route {
        case .networkOptions:
            return AnyView(Assembler.resolve(NetworkSecurityView.self))
        case .networkSettings(network: let network):
            return AnyView(Assembler.resolve(NetworkSettingsView.self)
                .environmentObject(NetworkFlowContext(displayNetwork: network)))
        case .antiCensorshipOptions:
            return AnyView(Assembler.resolve(AntiCensorshipOptionsView.self))
        }
    }

    @available(iOS 17.0, *)
    private func newCreateView(for route: ConnectionsRouteID) -> AnyView {
        switch route {
        case .networkOptions:
            return AnyView(NetworkOptionsScreen())
        case .networkSettings(network: let network):
            return AnyView(Assembler.resolve(NetworkSettingsView.self)
                .environmentObject(NetworkFlowContext(displayNetwork: network)))
        case .antiCensorshipOptions:
            return AnyView(AntiCensorshipScreen())
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
