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

    func createView(for route: PreferencesRouteID) -> AnyView {
        switch route {
        case .general:
            return AnyView(Assembler.resolve(GeneralSettingsView.self))
        case .account:
            return AnyView(Assembler.resolve(AccountSettingsView.self))
        case .connection:
            return AnyView(Assembler.resolve(ConnectionSettingsView.self))
        case .robert:
            return AnyView(Assembler.resolve(RobertSettingsView.self))
        case .referData:
            return AnyView(Assembler.resolve(ReferForDataSettingsView.self))
        case .lookAndFeel:
            return AnyView(Assembler.resolve(LookAndFeelSettingsView.self))
        case .help:
            return AnyView(Assembler.resolve(HelpSettingsView.self))
        case .about:
            return AnyView(Assembler.resolve(AboutSettingsView.self))
        case .ghostAccount:
            return AnyView(Assembler.resolve(GhostAccountView.self))
        case .enterEmail:
            return AnyView(Assembler.resolve(EnterEmailView.self))
        case .login:
            return AnyView(Assembler.resolve(LoginView.self))
        case .signupGhost:
            let context = SignupFlowContext()
            context.isFromGhostAccount = true
            return AnyView(Assembler.resolve(SignUpView.self).environmentObject(context))
        case .confirmEmail:
            return AnyView(Assembler.resolve(ConfirmEmailView.self))
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
