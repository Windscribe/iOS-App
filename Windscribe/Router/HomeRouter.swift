//
//  HomeRouter.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-14.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI
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
        case let RouteID.protocolConnectionResult(protocolName, viewType):
            let router = Assembler.resolve(ProtocolSwitchNavigationRouter.self)
            let view = Assembler.resolve(ProtocolConnectionResultView.self)
            let context = ProtocolConnectionResultContext()
            context.protocolName = protocolName
            context.viewType = viewType

            let hostingController = UIHostingController(rootView:
                view.environmentObject(context)
                    .environmentObject(router)
            )

            if viewType == .fail {
                from.navigationController?.pushViewController(hostingController, animated: true)
            } else if viewType == .connected {
                hostingController.modalPresentationStyle = .fullScreen
                from.present(hostingController, animated: true)
            }
            return

        case let RouteID.protocolSwitch(type, error):
            let context = ProtocolSwitchContext()
            context.fallbackType = type
            context.error = error
            let view = Assembler.resolve(ProtocolSwitchView.self)
            let hostingController = UIHostingController(rootView:
                view.environmentObject(context)
            )
            from.navigationController?.pushViewController(hostingController, animated: true)
            return
        case RouteID.locationPermission:
            let locationPermissionView = Assembler.resolve(LocationPermissionInfoView.self)
            presentViewModally(from: from, view: DeviceTypeProvider { locationPermissionView })
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
