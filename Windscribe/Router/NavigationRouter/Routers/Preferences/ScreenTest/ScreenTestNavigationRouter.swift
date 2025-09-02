//
//  ScreenTestNavigationRouter.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-08-19.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import SwiftUI
import Swinject

class ScreenTestNavigationRouter: BaseNavigationRouter {

    typealias Route = ScreenTestRouteID
    typealias Destination = AnyView

    @Published var activeRoute: Route?

    func createView(for route: ScreenTestRouteID) -> AnyView {
        switch route {
        case .accountStateBanned:
            let context = AccountStatusContext()
            context.accountStatusType = .banned
            let accountStatusView = Assembler.resolve(AccountStatusView.self).environmentObject(context)
            return AnyView(DeviceTypeProvider { accountStatusView })
        case .accountStateOOD:
            let context = AccountStatusContext()
            context.accountStatusType = .outOfData
            let accountStatusView = Assembler.resolve(AccountStatusView.self).environmentObject(context)
            return AnyView(DeviceTypeProvider { accountStatusView })
        case .accountStatePlan:
            let context = AccountStatusContext()
            context.accountStatusType = .proPlanExpired
            let accountStatusView = Assembler.resolve(AccountStatusView.self).environmentObject(context)
            return AnyView(DeviceTypeProvider { accountStatusView })
        case .enterCredentials:
            let context = EnterCredentialsContext()
            context.config = nil
            context.isUpdating = false
            let enterCredentialsView = Assembler.resolve(EnterCredentialsView.self).environmentObject(context)
            return AnyView(DeviceTypeProvider { enterCredentialsView })
        case .locationPermission:
            let locationPermissionView = Assembler.resolve(LocationPermissionInfoView.self)
            return AnyView(DeviceTypeProvider { locationPermissionView })
        case .maintenanceLocation:
            let context = MaintananceLocationContext()
            context.isStaticIp = false
            let maintananceLocationView = Assembler.resolve(MaintananceLocationView.self).environmentObject(context)
            return AnyView(DeviceTypeProvider { maintananceLocationView })
        case .privacyInformation:
            let privacyInfoView = Assembler.resolve(PrivacyInfoView.self)
            return AnyView(DeviceTypeProvider { privacyInfoView })
        case .pushNotification:
            let pushNotificationView = Assembler.resolve(PushNotificationView.self)
            return AnyView(DeviceTypeProvider { pushNotificationView })
        case .shakeForData:
            let shakeForDataMainView = Assembler.resolve(ShakeForDataMainView.self)
            return AnyView(DeviceTypeProvider {
                NavigationView {
                    shakeForDataMainView
                        .navigationBarHidden(true)
                }
                .navigationViewStyle(StackNavigationViewStyle())
            })
        case .restrictiveNetwork:
            let restrictiveNetworkView = Assembler.resolve(RestrictiveNetworkView.self)
            return AnyView(DeviceTypeProvider { restrictiveNetworkView })
        case .preferredProtocol:
            let context = ProtocolConnectionResultContext()
            context.protocolName = TextsAsset.iKEv2.localized
            context.viewType = .connected
            return AnyView(
                Assembler.resolve(ProtocolConnectionResultView.self)
                    .environmentObject(context)
            )
        }
    }

    func navigate(to destination: Route) {
        activeRoute = destination
    }

    func pop() {
        activeRoute = nil
    }
}
