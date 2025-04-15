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
    @Published var activeRoute: NavigationRouteID?
    @Published var shouldNavigateToSignup = false
    @Published var shouldNavigateToLogin = false
    @Published var shouldNavigateToEmergency = false

    @ViewBuilder
    func createView(for route: NavigationRouteID) -> some View {
        switch route {
        case .login:
            Assembler.resolve(LoginView.self)
        case .signup(let claimGhostAccount):
            getSignupView(claimGhostAccount: claimGhostAccount)
        case .emergency:
            Assembler.resolve(EmergencyConnectView.self)

        default:
            fatalError("Unsupported route: \(route)")
        }
    }

    private func getSignupView(claimGhostAccount: Bool) -> some View {
        let context = SignupFlowContext()
        context.isFromGhostAccount = claimGhostAccount

        return AnyView(
            Assembler.resolve(SignUpView.self)
                .environmentObject(context)
        )
    }

    /// Navigate to a specific route
    func navigate(to destination: NavigationRouteID) {
        activeRoute = destination
    }

    /// Pop back to the previous screen
    func pop() {
        activeRoute = nil
    }

    func routeToMainView() {
        let mainViewController = Assembler.resolve(MainViewController.self).then {
            $0.modalPresentationStyle = .fullScreen
            $0.appJustStarted = true
            $0.userJustLoggedIn = true
        }

        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {
            window.rootViewController?.dismiss(animated: false, completion: nil)

            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    window.rootViewController = UINavigationController(rootViewController: mainViewController)
                },
                completion: nil)
        }
    }
}
