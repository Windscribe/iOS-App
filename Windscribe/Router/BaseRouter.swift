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
        let vc = Assembler.resolve(SignUpViewController.self)
        vc.claimGhostAccount = claimGhostAccount

        DispatchQueue.main.async {
            viewController.navigationController?.pushViewController(vc, animated: true)
        }
    }

    func goToWeb(url: String, viewController: WSNavigationViewController, parameters _: [String: Any]?) {
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
}
