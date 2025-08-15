//
//  LoginNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-25.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

class AuthenticationNavigationRouter: BaseNavigationRouter {

    typealias Route = AuthenticationRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?

    @Published var shouldNavigateToSignup = false
    @Published var shouldNavigateToLogin = false
    @Published var shouldNavigateToEmergency = false
    @Published var shouldNavigateToEnterEmail = false
    @Published var shouldNavigateToRestrictiveNetwork = false

    func createView(for route: Route) -> AnyView {
        switch route {
        case .login:
            return AnyView(Assembler.resolve(LoginView.self))
        case .signup(let claimGhostAccount):
            let context = SignupFlowContext()
            context.isFromGhostAccount = claimGhostAccount

            return AnyView(
                Assembler.resolve(SignUpView.self)
                    .environmentObject(context)
            )
        case .emergency:
            return AnyView(Assembler.resolve(EmergencyConnectView.self))
        case .enterEmail:
            return AnyView(Assembler.resolve(EnterEmailView.self))
        case .restrictiveNetwork:
            return AnyView(Assembler.resolve(RestrictiveNetworkView.self))

        default:
            fatalError("Unsupported route: \(route)")
        }
    }

    /// Navigate to a specific route
    func navigate(to destination: Route) {
        activeRoute = destination
    }

    /// Pop back to the previous screen
    func pop() {
        activeRoute = nil
    }
}
