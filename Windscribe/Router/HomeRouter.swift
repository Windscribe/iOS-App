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
        case RouteID.locationPermission:
            let locationPermissionView = Assembler.resolve(LocationPermissionInfoView.self)

            presentViewModally(from: from, view: locationPermissionView)
        case RouteID.trustedNetwork:
            let vc = Assembler.resolve(TrustedNetworkPopupViewController.self)
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
            from.present(vc, animated: true, completion: nil)
        case RouteID.shareWithFriends:
            let referForDataView = Assembler.resolve(ReferForDataSettingsView.self)
            pushViewWithoutNavigationBar(from: from, view: referForDataView, title: "")
        case let RouteID.network(network):
            let networkView = Assembler.resolve(NetworkSettingsView.self)
                .environmentObject(NetworkFlowContext(displayNetwork: network))
            pushViewWithoutNavigationBar(from: from, view: networkView, title: TextsAsset.NetworkDetails.title)
        default: ()
        }
    }
}
