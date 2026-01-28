//
//  LookAndFeelNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2026-01-16.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

enum LookAndFeelRouteID: BaseRouteID {
    case discreetAppIconSelection

    var id: Int {
        switch self {
        case .discreetAppIconSelection: return 1
        }
    }
}

class LookAndFeelNavigationRouter: BaseNavigationRouter {
    typealias Route = LookAndFeelRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?

    func createView(for route: LookAndFeelRouteID) -> AnyView {
        switch route {
        case .discreetAppIconSelection:
            return AnyView(Assembler.resolve(DiscreetAppIconSelectionView.self))
        }
    }

    func navigate(to destination: Route) {
        activeRoute = destination
    }

    func pop() {
        activeRoute = nil
    }
}
