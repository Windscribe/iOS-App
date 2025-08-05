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

    // MARK: - Private Methods

    private func resolveViewController(for route: RouteID) -> UIViewController? {
        switch route {
        case .shakeForDataPopUp:
            return UINavigationController(
                rootViewController: Assembler.resolve(ShakeForDataPopupViewController.self))
        case .shakeForDataView:
            return Assembler.resolve(ShakeForDataViewController.self)
        case let .shakeForDataResult(shakeCount):
            let shakeResultsVC = Assembler.resolve(ShakeForDataResultViewController.self)
            shakeResultsVC.viewModel.setup(with: shakeCount)
            return shakeResultsVC
        case .shakeLeaderboards:
            return Assembler.resolve(ViewLeaderboardViewController.self)
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
            return Assembler.resolve(AccountStatusView.self).environmentObject(context)

        case .outOfDataAccountPopup:
            let context = AccountStatusContext()
            context.accountStatusType = .outOfData
            return Assembler.resolve(AccountStatusView.self).environmentObject(context)

        case .proPlanExpireddAccountPopup:
            let context = AccountStatusContext()
            context.accountStatusType = .proPlanExpired
            return Assembler.resolve(AccountStatusView.self).environmentObject(context)

        case .newsFeedPopup:
            return Assembler.resolve(NewsFeedView.self)

        case .privacyView:
            return Assembler.resolve(PrivacyInfoView.self)

        case .pushNotifications:
            return Assembler.resolve(PushNotificationView.self)

        case let .enterCredentials(config, isUpdating):
            let context = EnterCredentialsContext()
            context.config = config
            context.isUpdating = isUpdating
            return Assembler.resolve(EnterCredentialsView.self).environmentObject(context)

        case .maintenanceLocation(let isStaticIp):
            let context = MaintananceLocationContext()
            context.isStaticIp = isStaticIp
            return Assembler.resolve(MaintananceLocationView.self).environmentObject(context)

        case .networkSecurity:
            return Assembler.resolve(NetworkSecurityView.self)

        default:
            return nil
        }
    }

    private func presentViewController(_ vc: UIViewController, for route: RouteID, from: WSUIViewController) {
        configureModalPresentation(vc, for: route)

        DispatchQueue.main.async {
            switch route {
            case .shakeForDataPopUp:
                from.present(vc, animated: true, completion: nil)
            case .shakeForDataView, .shakeForDataResult:
                from.navigationController?.pushViewController(vc, animated: true)
                from.navigationController?.viewControllers = [vc]
            case .upgrade:
                from.present(vc, animated: true)
            default:
                from.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    private func configureModalPresentation(_ vc: UIViewController, for route: RouteID) {
        switch route {
        case .shakeForDataView, .shakeForDataResult:
            vc.modalPresentationStyle = .overCurrentContext
            vc.modalTransitionStyle = .coverVertical
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
        case .newsFeedPopup, .networkSecurity:
            isTransparentView = false
        default:
            isTransparentView = true
        }

        presentViewModally(from: from, view: view, isTransparent: isTransparentView)
    }
}
