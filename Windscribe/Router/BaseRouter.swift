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
    func goToSignUp(viewController: WSUIViewController, claimGhostAccount: Bool = false) {
        let context = SignupFlowContext()
        context.isFromGhostAccount = claimGhostAccount

        let signUpView =  Assembler.resolve(SignUpView.self)
            .environmentObject(context)

        pushViewWithoutNavigationBar(from: viewController, view: signUpView)
    }

    func dismissPopup(navigationVC: UINavigationController?) {
        navigationVC?.popToRootViewController(animated: true)
    }

    func pushViewWithoutNavigationBar<V: View>(from viewController: WSUIViewController, view: V, title: String? = nil) {
        let hostingController = RoutedHostingController(rootView: view)
        if let title = title {
            hostingController.title = title

            let backItem = UIBarButtonItem(title: "", style: .plain, target: nil, action: nil)
            viewController.navigationItem.backBarButtonItem = backItem
        }

        hostingController.onPop = { [weak viewController] in
            viewController?.changeNavigationBarStyle(isHidden: true)
        }

        viewController.navigationController?.pushViewController(hostingController, animated: true)

        viewController.changeNavigationBarStyle(isHidden: false)
        viewController.navigationController?.navigationBar.setNeedsLayout()
    }

    func presentViewModally<V: View>(from viewController: WSUIViewController, view: V, isTransparent: Bool = false) {
        let hostingController = UIHostingController(rootView: view)

        if isTransparent {
            hostingController.modalPresentationStyle = .overCurrentContext
            hostingController.modalTransitionStyle = .crossDissolve
            hostingController.view.backgroundColor = UIColor.clear
        } else {
            hostingController.modalPresentationStyle = .fullScreen
        }

        viewController.present(hostingController, animated: true)
    }
}
