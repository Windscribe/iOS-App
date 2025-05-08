//
//  HomeRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-14.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import UIKit

class HomeRouter: BaseRouter, RootRouter {

    func routeTo(to: RouteID, from: WSUIViewController) {
        switch to {
        case RouteID.mainMenu:

            let preferencesView = Assembler.resolve(PreferencesMainCategoryView.self)
            pushViewWithoutNavigationBar(from: from, view: preferencesView, title: TextsAsset.Preferences.title)

        case RouteID.signup:
            goToSignUp(viewController: from, claimGhostAccount: false)
        case let RouteID.protocolSetPreferred(type, delegate, protocolName):
            let vc = Assembler.resolve(ProtocolSetPreferredViewController.self)
            vc.delegate = delegate
            vc.type = type
            vc.protocolName = protocolName
            if type == .fail {
                from.navigationController?.pushViewController(vc, animated: true)
            } else if type == .connected {
                vc.modalPresentationStyle = .fullScreen
                from.present(vc, animated: true)
            }
        case let RouteID.protocolSwitchVC(delegate, type):
            let vc = Assembler.resolve(ProtocolSwitchViewController.self)
            vc.delegate = delegate
            vc.type = type
            from.navigationController?.pushViewController(vc, animated: true)
        case let RouteID.locationPermission(delegate, denied):
            let vc = Assembler.resolve(LocationPermissionInfoViewController.self)
            vc.delegate = delegate
            vc.denied = denied
            vc.modalPresentationStyle = .fullScreen
            vc.modalTransitionStyle = .crossDissolve
            from.present(vc, animated: true, completion: nil)
        case RouteID.trustedNetwork:
            let vc = Assembler.resolve(TrustedNetworkPopupViewController.self)
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            from.present(vc, animated: true, completion: nil)
        case RouteID.shareWithFriends:
            let vc = Assembler.resolve(ShareWithFriendViewController.self)
            from.navigationController?.pushViewController(vc, animated: true)
        case let RouteID.network(network):
            let vc = Assembler.resolve(NetworkViewController.self)
            vc.viewModel.displayingNetwork = network
            from.navigationController?.pushViewController(vc, animated: true)
        default: ()
        }
    }
}
