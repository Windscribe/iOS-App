//
//  BaseRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-15.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import SafariServices
import Swinject
import SwiftUI

class BaseRouter: NSObject, SFSafariViewControllerDelegate {
    func goToHome() {
        let vc = Assembler.resolve(MainViewController.self)
        vc.modalPresentationStyle = .fullScreen
        vc.appJustStarted = true
        vc.userJustLoggedIn = true
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate, let window = appDelegate.window {
            window.rootViewController?.dismiss(animated: false,
                                               completion: nil)
            UIView.transition(with: window,
                              duration: 0.3,
                              options: .transitionCrossDissolve,
                              animations: {
                                  window.rootViewController = UINavigationController(rootViewController: vc)
                              }, completion: nil)
        }
    }

    func goToSignUp(viewController: WSUIViewController, claimGhostAccount: Bool = false) {
        let context = SignupFlowContext()
        context.isFromGhostAccount = claimGhostAccount

        let signUpView =  Assembler.resolve(SignUpView.self)
            .environmentObject(context)

        pushViewWithoutNavigationBar(from: viewController, view: signUpView)
    }

    func goToLogin(viewController: WSUIViewController) {
        let loginView = Assembler.resolve(LoginView.self)

        pushViewWithoutNavigationBar(from: viewController, view: loginView)
    }

    func goToWeb(url: String, viewController: WSNavigationViewController) {
        let safariVC = SFSafariViewController(url: URL(string: url)!)
        safariVC.preferredBarTintColor = UIColor.black
        viewController.present(safariVC, animated: true, completion: nil)
        safariVC.delegate = self
    }

    func dismissPopup(action: ConfirmEmailAction, navigationVC: UINavigationController?) {
        switch action {
        case .dismiss:
            navigationVC?.popToRootViewController(animated: true)
            return
        case .enterEmail:
            let vc = Assembler.resolve(EnterEmailViewController.self)
            navigationVC?.pushViewController(vc, animated: true)
        }
    }

    func pushViewWithoutNavigationBar<V: View>(from viewController: WSUIViewController, view: V, title: String? = nil) {
        let hostingController = RoutedHostingController(rootView: view)
        if let title = title {
            hostingController.title = title
        }

        viewController.navigationItem.backBarButtonItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
        viewController.navigationController?.navigationBar.tintColor = .white

        hostingController.onPop = { [weak viewController] in
            viewController?.changeNavigationBarStyle(isHidden: true)
        }

        viewController.navigationController?.pushViewController(hostingController, animated: true)

        viewController.changeNavigationBarStyle(isHidden: false)
    }

    func presentConfirmEmail(from presentingVC: UIViewController) {
        let confirmEmailView = Assembler.resolve(ConfirmEmailView.self)

        let vc = UIHostingController(rootView: confirmEmailView)

        if #available(iOS 16.0, *) {
            if let sheet = vc.sheetPresentationController {
                sheet.detents = [
                    .custom { context in
                        return context.maximumDetentValue * 0.65
                    }
                ]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 24
            }
            vc.modalPresentationStyle = .pageSheet
        } else {
            vc.modalPresentationStyle = .automatic
        }

        presentingVC.present(vc, animated: true)
    }

}
