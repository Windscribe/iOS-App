//
//  BaseNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI

/// Defines core navigation logic
protocol BaseNavigationRouter: ObservableObject {
    associatedtype Destination: View

    var activeRoute: NavigationRouteID? { get set }

    /// Creates the appropriate view for the given route
    @ViewBuilder
    func createView(for route: NavigationRouteID) -> Destination

    /// Navigate to a specific route
    func navigate(to destination: NavigationRouteID)

    /// Pop back to the previous screen
    func pop()
}
