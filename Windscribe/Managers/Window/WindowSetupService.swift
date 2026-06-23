//
//  WindowSetupService.swift
//  Windscribe
//
//  Created by Anthony on 2026-03-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Combine
import RealmSwift
import SwiftUI
import Swinject
import UIKit

class WindowSetupServiceImpl: WindowSetupService {
    private var splashView: LoadingSplashView?
    private var cancellables = Set<AnyCancellable>()

    // .container singleton: resolve .userScope deps live so they can't go stale across a userScope reset.
    private var userSessionRepository: UserSessionRepository { Assembler.resolve(UserSessionRepository.self) }
    private var lookAndFeelRepository: LookAndFeelRepositoryType { Assembler.resolve(LookAndFeelRepositoryType.self) }

    func configureWindow(_ window: UIWindow) {
        bindThemeChange()

        window.backgroundColor = UIColor(.from(.actionBackgroundColor, lookAndFeelRepository.isDarkMode))
        window.rootViewController = UIViewController()
        window.makeKeyAndVisible()

        if userSessionRepository.sessionAuth != nil {
            let splash = LoadingSplashView(frame: window.bounds)
            window.addSubview(splash)
            self.splashView = splash
        }

        DispatchQueue.global(qos: .userInitiated).async {
            _ = try? Realm()

            DispatchQueue.main.async {
                let welcomeView = self.setUpWelcomeView()
                self.presentMainView(with: welcomeView, on: window)
            }
        }
    }

    private func bindThemeChange() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { isDark in
                UINavigationBar.setStyleNavigationBackButton(isDarkMode: isDark)
            }.store(in: &cancellables)
    }

    private func presentMainView<T: View>(with view: T, on window: UIWindow) {
        let rootViewController: UIViewController

        if userSessionRepository.sessionAuth != nil {
            let mainViewController = Assembler.resolve(MainViewController.self).then {
                $0.appJustStarted = true
            }
            rootViewController = UINavigationController(rootViewController: mainViewController).then {
                $0.view.backgroundColor = UIColor(.from(.screenBackgroundColor, lookAndFeelRepository.isDarkMode))
                $0.overrideUserInterfaceStyle = lookAndFeelRepository.isDarkMode ? .dark : .light
            }
        } else {
            let rootView = DeviceTypeProvider { view }
            rootViewController = UIHostingController(rootView: rootView).then {
                $0.view.backgroundColor = UIColor(.from(.screenBackgroundColor, lookAndFeelRepository.isDarkMode))
                $0.overrideUserInterfaceStyle = lookAndFeelRepository.isDarkMode ? .dark : .light
            }
        }

        window.rootViewController = rootViewController

        if let splash = self.splashView {
            window.bringSubviewToFront(splash)
        }

        Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { [weak self] _ in
            self?.hideSplashView()
        }
    }

    private func hideSplashView() {
        UIView.animate(withDuration: 0.5, animations: {
            self.splashView?.layer.opacity = 0
        }, completion: { _ in
            self.splashView?.removeFromSuperview()
            self.splashView = nil
        })
    }

    private func setUpWelcomeView() -> any View {
        return Assembler.resolve(WelcomeView.self)
    }
}
