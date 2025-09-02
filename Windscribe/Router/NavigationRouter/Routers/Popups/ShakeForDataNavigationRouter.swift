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
        // Configure navigation items if we have a navigation controller
        if let navVC = findNavigationController() {
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
        if let navVC = findNavigationController() {
            navVC.dismiss(animated: true)
        } else if let topVC = UIApplication.shared.topMostViewController(), topVC.presentingViewController != nil {
            topVC.dismiss(animated: true)
        }
    }

    // MARK: - Private Helper Methods

    private func findNavigationController() -> UINavigationController? {
        guard let topVC = UIApplication.shared.topMostViewController() else { return nil }

        // First try the standard approach
        if let navVC = topVC.navigationController {
            return navVC
        }

        // If no navigation controller found, check if we're in a presented context (like fullScreenCover)
        if let presentingVC = topVC.presentingViewController, let navVC = presentingVC.navigationController {
            return navVC
        }

        // Last resort: check if the top view controller itself is a navigation controller
        return topVC as? UINavigationController
    }
}
