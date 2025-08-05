//
//  ShakeForDataNavigationRouter.swift
//  Windscribe
//
//  Created by Andre Fonseca on 17/07/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

class ShakeForDataNavigationRouter: BaseNavigationRouter {
    typealias Route = ShakeForDataRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?
    private var currentScore: Int = 0

    func createView(for route: ShakeForDataRouteID) -> AnyView {
        switch route {
        case .leaderboard:
            return AnyView(Assembler.resolve(ShakeForDataLeaderboardView.self))
        case .shakeGame:
            return AnyView(Assembler.resolve(ShakeForDataGameView.self))
        case .results:
            return AnyView(Assembler.resolve(ShakeForDataResultsView.self))
        }
    }

    func navigate(to destination: Route) {
        if let navVC = UIApplication.shared.topMostViewController()?.navigationController {
            switch destination {
            case .shakeGame, .results:
                navVC.navigationItem.backBarButtonItem = nil
            default:
                navVC.topViewController?.navigationItem.backBarButtonItem =
                    UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            }
        }
        activeRoute = destination
    }

    func pop() {
        activeRoute = nil
    }

    func dismiss() {
        if let navVC = UIApplication.shared.topMostViewController()?.navigationController {
            navVC.dismiss(animated: true)
        }
    }
}
