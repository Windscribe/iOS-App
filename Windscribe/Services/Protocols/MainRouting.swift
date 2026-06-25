//
//  MainRouting.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import SwiftUI
import UIKit
import Swinject

/// Main-app transition surface for authentication screens.
protocol MainRouting: Sendable {
    @MainActor func routeToMainView()
    @MainActor func restrictiveNetworkView() -> AnyView
}

/// Adapter wrapping the legacy root-controller transition.
final class LegacyMainRouter: MainRouting, @unchecked Sendable {
    @MainActor
    func routeToMainView() {
        let mainViewController = Assembler.resolve(MainViewController.self).then {
            $0.modalPresentationStyle = .fullScreen
            $0.appJustStarted = true
            $0.userJustLoggedIn = true
        }

        if let window = Assembler.resolve(WindowProvider.self).mainWindow {
            window.rootViewController?.dismiss(animated: false, completion: nil)

            UIView.transition(
                with: window,
                duration: 0.3,
                options: .transitionCrossDissolve,
                animations: {
                    window.rootViewController = UINavigationController(rootViewController: mainViewController)
                },
                completion: nil
            )
        }
    }

    @MainActor
    func restrictiveNetworkView() -> AnyView {
        AnyView(Assembler.resolve(RestrictiveNetworkView.self))
    }
}
