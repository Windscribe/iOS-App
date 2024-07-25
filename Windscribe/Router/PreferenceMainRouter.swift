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
            let vc = Assembler.resolve(GhostAccountViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
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
            let vc = Assembler.resolve(ConfirmEmailViewController.self)
            vc.dismissDelegate = delegate
            from.present(vc, animated: true)
        case RouteID.enterEmail:
            let vc = Assembler.resolve(EnterEmailViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case RouteID.login:
            let vc = Assembler.resolve(LoginViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
