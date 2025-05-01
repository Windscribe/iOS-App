//
//  PreferenceMainRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-13.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit
import SwiftUI

class PreferenceMainRouter: BaseRouter, NavigationRouter {
    func routeTo(to: RouteID, from: WSNavigationViewController) {
        switch to {
        case RouteID.advanceParams:
            let vc = Assembler.resolve(AdvanceParamsViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.help:
            let vc = Assembler.resolve(HelpViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case let RouteID.signup(claimGhostAccount):
            goToSignUp(viewController: from, claimGhostAccount: claimGhostAccount)
        case RouteID.general:
            let vc = Assembler.resolve(GeneralViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.ghostAccount:
            let ghostView = Assembler.resolve(GhostAccountView.self)
            pushViewWithoutNavigationBar(from: from, view: ghostView)
        case RouteID.account:
            let vc = Assembler.resolve(AccountViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.robert:
            let vc = Assembler.resolve(RobertViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.about:
            let vc = Assembler.resolve(AboutViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.shareWithFriends:
            let vc = Assembler.resolve(ShareWithFriendViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.connection:
            let vc = Assembler.resolve(ConnectionViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case let RouteID.confirmEmail(delegate):
//            let vc = Assembler.resolve(ConfirmEmailViewController.self)
//            vc.dismissDelegate = delegate
//            from.present(vc, animated: true)

            presentConfirmEmail(from: from)
        case RouteID.enterEmail:
            let enterEmail = Assembler.resolve(EnterEmailView.self)
            pushViewWithoutNavigationBar(from: from, view: enterEmail)
        case RouteID.login:
            goToLogin(viewController: from)
        case RouteID.lookFeel:
            let vc = Assembler.resolve(LookAndFeelViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
