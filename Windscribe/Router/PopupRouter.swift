//
//  PopupRouter.swift
//  Windscribe
//
//  Created by Andre Fonseca on 05/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import SwiftUI
import Swinject

class PopupRouter: BaseRouter, RootRouter {
    func routeTo(to: RouteID, from: WSUIViewController) {
        let vc = resolveViewController(for: to)
        let view = resolveView(for: to)

        if let vc = vc {
            presentViewController(vc, for: to, from: from)
        } else if let view = view {
            presentView(view, for: to, from: from)
        }
    }

    private func resolveViewController(for route: RouteID) -> UIViewController? {
        switch route {
        case let .upgrade(promoCode, pcpID):
            let upgradeVC = Assembler.resolve(PlanUpgradeViewController.self).then {
                $0.promoCode = promoCode
                $0.pcpID = pcpID
            }
            return UINavigationController(rootViewController: upgradeVC)
        default:
            return nil
        }
    }

    private func resolveView(for route: RouteID) -> (any View)? {
        switch route {
        case .bannedAccountPopup:
            let context = AccountStatusContext()
            context.accountStatusType = .banned
            let accountStatusView = Assembler.resolve(AccountStatusView.self).environmentObject(context)
            return DeviceTypeProvider { accountStatusView }

        case .outOfDataAccountPopup:
            let context = AccountStatusContext()
            context.accountStatusType = .outOfData
            let accountStatusView = Assembler.resolve(AccountStatusView.self).environmentObject(context)
            return DeviceTypeProvider { accountStatusView }

        case .proPlanExpireddAccountPopup:
            let context = AccountStatusContext()
            context.accountStatusType = .proPlanExpired
            let accountStatusView = Assembler.resolve(AccountStatusView.self).environmentObject(context)
            return DeviceTypeProvider { accountStatusView }

        case .newsFeedPopup:
            return Assembler.resolve(NewsFeedView.self)

        case .privacyView:
            let privacyInfoView = Assembler.resolve(PrivacyInfoView.self)
            return DeviceTypeProvider { privacyInfoView }

        case .pushNotifications:
            let pushNotificationView = Assembler.resolve(PushNotificationView.self)
            return DeviceTypeProvider { pushNotificationView }

        case let .enterCredentials(config, isUpdating):
            let context = EnterCredentialsContext()
            context.config = config
            context.isUpdating = isUpdating
            return Assembler.resolve(EnterCredentialsView.self).environmentObject(context)

        case .maintenanceLocation(let isStaticIp):
            let context = MaintananceLocationContext()
            context.isStaticIp = isStaticIp
            let maintananceLocationView = Assembler.resolve(MaintananceLocationView.self).environmentObject(context)
            return DeviceTypeProvider { maintananceLocationView }

        case .networkSecurity:
            return Assembler.resolve(NetworkSecurityView.self)

        case .shakeForDataPopUp:
            return Assembler.resolve(ShakeForDataMainView.self)

        case .protocolSwitch(let type, let error):
            let context = ProtocolSwitchContext()
            context.fallbackType = type
            context.error = error
            let protocolSwitchView = Assembler.resolve(ProtocolSwitchView.self).environmentObject(context)
            return DeviceTypeProvider { protocolSwitchView }

        case .protocolConnectionResult(let protocolName, let viewType):
            let context = ProtocolConnectionResultContext()
            context.protocolName = protocolName
            context.viewType = viewType
            let protocolResultView = Assembler.resolve(ProtocolConnectionResultView.self).environmentObject(context)
            return DeviceTypeProvider { protocolResultView }

        case .protocolConnectionDebug:
            let protocolDebugView = Assembler.resolve(ProtocolConnectionDebugView.self)
            return DeviceTypeProvider { protocolDebugView }

        default:
            return nil
        }
    }

    private func presentViewController(_ vc: UIViewController, for route: RouteID, from: WSUIViewController) {
        configureModalPresentation(vc, for: route)

        DispatchQueue.main.async {
            switch route {
            case .upgrade:
                from.present(vc, animated: true)
            default:
                from.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    private func configureModalPresentation(_ vc: UIViewController, for route: RouteID) {
        switch route {
        case .upgrade:
            vc.modalPresentationStyle = .fullScreen
        default:
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .crossDissolve
        }
    }

    private func presentView(_ view: any View, for route: RouteID, from: WSUIViewController) {
        var isTransparentView = true

        switch route {
        case .newsFeedPopup:
            isTransparentView = false
        default:
            isTransparentView = true
        }

        switch route {
        case .shakeForDataPopUp:
            presentViewModallyWithNavigation(from: from, view: view)
        case .networkSecurity:
            pushViewWithoutNavigationBar(from: from, view: view, title: TextsAsset.NetworkSecurity.title)
        default:
            presentViewModally(from: from, view: view, isTransparent: isTransparentView)
        }

    }
}
