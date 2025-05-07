//
//  LoginNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-06.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

class PreferencesNavigationRouter: BaseNavigationRouter {

    typealias Route = PreferencesRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?

    func createView(for route: Route) -> AnyView {
        switch route {
        case .general:
            return AnyView(Assembler.resolve(GeneralSettingsView.self))
        case .account:
            return AnyView(Text("Account"))
        case .connection:
            return AnyView(Text("Connection"))
        case .robert:
            return AnyView(Text("Robert"))
        case .referData:
            return AnyView(Text("Refer Data"))
        case .lookAndFeel:
            return AnyView(Text("Look and Feel"))
        case .help:
            return AnyView(Text("Help"))
        case .about:
            return AnyView(Text("About"))
        }
    }

    func navigate(to destination: Route) {
        activeRoute = destination
    }

    func pop() {
        activeRoute = nil
    }
}
