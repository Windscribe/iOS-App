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
        var vc: UIViewController?

        var view: (any View)?

        switch to {
        case .bannedAccountPopup:
            vc = Assembler.resolve(BannedAccountPopupViewController.self)
        case .outOfDataAccountPopup:
            vc = Assembler.resolve(OutOfDataAccountPopupViewController.self)
        case .proPlanExpireddAccountPopup:
            vc = Assembler.resolve(ProPlanExpiredPopupViewController.self)
        case .newsFeedPopup:
            view = Assembler.resolve(NewsFeedView.self)
        case .privacyView:
            let privacyInfoView = Assembler.resolve(PrivacyInfoView.self)
            let hostingController = UIHostingController(rootView: privacyInfoView)
            hostingController.modalPresentationStyle = .overCurrentContext
            hostingController.modalTransitionStyle = .crossDissolve
            hostingController.view.backgroundColor = UIColor.clear // Critical for transparency
            from.present(hostingController, animated: true, completion: nil)
            return
        case .shakeForDataPopUp:
            vc = UINavigationController(rootViewController: Assembler.resolve(ShakeForDataPopupViewController.self))
        case .shakeForDataView:
            vc = Assembler.resolve(ShakeForDataViewController.self)
        case let .shakeForDataResult(shakeCount):
            let shakeResultsVC = Assembler.resolve(ShakeForDataResultViewController.self)
            shakeResultsVC.viewModel.setup(with: shakeCount)
            vc = shakeResultsVC
        case .shakeLeaderboards:
            vc = Assembler.resolve(ViewLeaderboardViewController.self)
        case .pushNotifications:
            let pushNotificationView = Assembler.resolve(PushNotificationView.self)
            presentViewModally(from: from, view: pushNotificationView)
            return
        case let .enterCredentials(config, isUpdating):
            let context = EnterCredentialsContext()
            context.config = config
            context.isUpdating = isUpdating

            let enterCredentialsView = Assembler.resolve(EnterCredentialsView.self)
                .environmentObject(context)

            presentViewModally(from: from, view: enterCredentialsView)
            return
        case .maintenanceLocation(let isStaticIp):
            vc = Assembler.resolve(PopUpMaintenanceLocationVC.self)
            (vc as? PopUpMaintenanceLocationVC)?.isStaticIp = isStaticIp
        case let .upgrade(promoCode, pcpID):
            let upgradeVC = Assembler.resolve(PlanUpgradeViewController.self).then {
                $0.promoCode = promoCode
                $0.pcpID = pcpID
            }
            vc = UINavigationController(rootViewController: upgradeVC)
        case .rateUsPopUp:
            let logger = Assembler.resolve(FileLogger.self)
            logger.logD(self, "Not implemented")
        case .networkSecurity:
            view = Assembler.resolve(NetworkSecurityView.self)
        default: return
        }

        if let vc = vc {
            switch to {
            case .networkSecurity:
                vc.modalTransitionStyle = .coverVertical
            case .maintenanceLocation:
                vc.modalPresentationStyle = .overFullScreen
            case .shakeForDataView,
                 .shakeForDataResult:
                vc.modalPresentationStyle = .overCurrentContext
                vc.modalTransitionStyle = .coverVertical
            case .upgrade:
                vc.modalPresentationStyle = .fullScreen
            default:
                vc.modalPresentationStyle = .overCurrentContext
                vc.modalTransitionStyle = .crossDissolve
            }
            DispatchQueue.main.async {
                // Pushing animated or not
                switch to {
                case let .bannedAccountPopup(pushAnimated):
                    from.navigationController?.pushViewController(vc, animated: pushAnimated)
                case .privacyView, .enterCredentials, .shakeForDataPopUp, .pushNotifications, .maintenanceLocation:
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
        } else if let view = view {
            let hostingController = UIHostingController(rootView: AnyView(view))
            hostingController.modalPresentationStyle = .fullScreen
            from.present(hostingController, animated: true, completion: nil)
        }
    }
}
