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
        switch to {
        case .bannedAccountPopup:
            vc = Assembler.resolve(BannedAccountPopupViewController.self)
        case .outOfDataAccountPopup:
            vc = Assembler.resolve(OutOfDataAccountPopupViewController.self)
        case .proPlanExpireddAccountPopup:
            vc = Assembler.resolve(ProPlanExpiredPopupViewController.self)
        case let .errorPopup(message, dismissAction):
            let errorVC = Assembler.resolve(ErrorPopupViewController.self)
            errorVC.viewModel.setDismissAction(with: dismissAction)
            errorVC.viewModel.setMessage(with: message)
            vc = errorVC
        case .newsFeedPopup:
            vc = Assembler.resolve(NewsFeedViewController.self)
        case .setPreferredProtocolPopup:
            vc = Assembler.resolve(SetPreferredProtocolPopupViewController.self)
        case let .privacyView(completionHandler):
            let privacyVC: PrivacyViewController = Assembler.resolve(PrivacyViewController.self)
            privacyVC.closeCompletion = completionHandler
            vc = privacyVC
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
            vc = Assembler.resolve(PushNotificationViewController.self)
        case let .enterCredentials(config, isUpdating):
            let credentialsVC = Assembler.resolve(EnterCredentialsViewController.self)
            credentialsVC.viewModel.setup(with: config, isUpdating: isUpdating)
            vc = credentialsVC
        case let .infoPrompt(title, actionValue, justDismissOnAction, delegate):
            let infoPromptVC = Assembler.resolve(InfoPromptViewController.self)
            infoPromptVC.viewModel.setInfo(title: title,
                                           actionValue: actionValue,
                                           justDismissOnAction: justDismissOnAction,
                                           delegate: delegate)
            vc = infoPromptVC
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
            vc = Assembler.resolve(NetworkViewController.self)
        default: return
        }

        if let vc = vc {
            // Presentation Style
            switch to {
            case .networkSecurity:
                vc.modalTransitionStyle = .coverVertical
            case .errorPopup:
                vc.modalPresentationStyle = .fullScreen
            case .maintenanceLocation:
                vc.modalPresentationStyle = .overFullScreen
            case .infoPrompt,
                 .shakeForDataView,
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
                case .setPreferredProtocolPopup,
                        .newsFeedPopup,
                        .privacyView,
                        .infoPrompt,
                        .enterCredentials,
                        .shakeForDataPopUp,
                        .pushNotifications,
                        .maintenanceLocation:
                    from.present(vc, animated: true, completion: nil)
                case .shakeForDataView,
                     .shakeForDataResult:
                    from.navigationController?.pushViewController(vc, animated: true)
                    from.navigationController?.viewControllers = [vc]
                case .upgrade:
                    from.present(vc, animated: true)
                default:
                    from.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}
