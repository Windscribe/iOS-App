//
//  TVWindowSetupService.swift
//  WindscribeTV
//
//  Created by Anthony on 2026-03-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Swinject
import UIKit

class TVWindowSetupServiceImpl: WindowSetupService {
    private let preferences: Preferences

    init(preferences: Preferences) {
        self.preferences = preferences
    }

    func configureWindow(_ window: UIWindow) {
        window.backgroundColor = UIColor.black

        if preferences.getSessionAuthHash() != nil {
            if preferences.getLoginDate() == nil {
                preferences.saveLoginDate(date: Date())
            }
            let mainViewController = Assembler.resolve(MainViewController.self)
            let viewController = UINavigationController(rootViewController: mainViewController)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = viewController
            }, completion: nil)
        } else {
            let welcomeVC = Assembler.resolve(WelcomeViewController.self)
            let viewController = UINavigationController(rootViewController: welcomeVC)
            UIView.transition(with: window, duration: 0.3, options: .transitionCrossDissolve, animations: {
                window.rootViewController = viewController
            }, completion: nil)
        }

        window.makeKeyAndVisible()
    }
}
