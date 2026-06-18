//
//  BaseNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

protocol BaseRouteID: Hashable, Identifiable {}

/// Defines core navigation logic
protocol BaseNavigationRouter: ObservableObject {

    associatedtype Destination: View
    associatedtype Route: BaseRouteID

    /// Creates the appropriate view for the given route
    @ViewBuilder
    func createView(for route: Route) -> Destination

    /// Navigate to a specific route
    func navigate(to destination: Route)

    /// Pop back to the previous screen
    func pop()

    func routeToMainView()
}

extension BaseNavigationRouter {

    func routeToMainView() {
        let mainViewController = Assembler.resolve(MainViewController.self).then {
            $0.modalPresentationStyle = .fullScreen
            $0.appJustStarted = true
            $0.userJustLoggedIn = true
        }

        if let window = Assembler.resolve(WindowProvider.self).mainWindow {
            window.rootViewController?.dismiss(animated: false, completion: nil)

            let navigationController = UINavigationController(rootViewController: mainViewController)

            if #available(iOS 26.0, *) {
                // iOS 26 can assert inside UIKit list metrics while cross-dissolving
                // the window root controller into MainViewController's table views.
                UIView.performWithoutAnimation {
                    window.rootViewController = navigationController
                    window.makeKeyAndVisible()
                }
            } else {
                UIView.transition(
                    with: window,
                    duration: 0.3,
                    options: .transitionCrossDissolve,
                    animations: {
                        window.rootViewController = navigationController
                    },
                    completion: nil)
            }
        }
    }
}
