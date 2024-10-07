//
//  PopupRouter.swift
//  Windscribe
//
//  Created by Andre Fonseca on 05/04/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import SwiftUI

class PopupRouter: BaseRouter, RootRouter {
    func routeTo(to: RouteID, from: WSUIViewController) {
        var vc: UIViewController?
        switch to {
        case .bannedAccountPopup:
            vc = Assembler.resolve(BannedAccountPopupViewController.self)
        case .outOfDataAccountPopup:
            vc = Assembler.resolve(OutOfDataAccountPopupViewController.self)
        case .proPlanExpireddAccountPopup:
            vc = Assembler.resolve(ProPlanExpireddAccountPopupViewController.self)
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
        case .maintenanceLocation:
            vc = Assembler.resolve(PopUpMaintenanceLocationVC.self)
        case let .upgrade(promoCode, pcpID):
            let upgradeVC = Assembler.resolve(UpgradeViewController.self)
            upgradeVC.promoCode = promoCode
            upgradeVC.pcpID = pcpID
            vc = upgradeVC

        case .rateUsPopUp:
            if #available(iOS 16.0, *) {
                let viewModel = Assembler.resolve(RateUsPopupModelType.self)
                let ratingView = RateUsPopupView(viewModel: viewModel, onDismiss: {
                    for child in from.children {
                        if child is UIHostingController<RateUsPopupView> {
                            child.willMove(toParent: nil) // Notify the child that it will be removed
                            child.view.removeFromSuperview()
                            child.removeFromParent()
                        }
                    }
                })

                let hostingController = UIHostingController(rootView: ratingView)
                hostingController.modalPresentationStyle = .overFullScreen
                hostingController.modalTransitionStyle = .coverVertical

                // Add the hosting controller as a child
                from.addChild(hostingController)
                from.view.addSubview(hostingController.view)

                // Set up constraints for the hosting controller's view
                hostingController.view.translatesAutoresizingMaskIntoConstraints = false
                NSLayoutConstraint.activate([
                    hostingController.view.leadingAnchor.constraint(equalTo: from.view.leadingAnchor),
                    hostingController.view.trailingAnchor.constraint(equalTo: from.view.trailingAnchor),
                    hostingController.view.topAnchor.constraint(equalTo: from.view.topAnchor),
                    hostingController.view.bottomAnchor.constraint(equalTo: from.view.bottomAnchor)
                ])

                hostingController.didMove(toParent: from)
            }

            // vc = Assembler.resolve(RateUsPopupViewController.self)

        default: return
        }

        if let vc = vc {
            // Presentation Style
            switch to {
            case .errorPopup:
                vc.modalPresentationStyle = .fullScreen
            case .maintenanceLocation:
                vc.modalPresentationStyle = .overFullScreen
            case .infoPrompt,
                    .shakeForDataView,
                    .shakeForDataResult:
                vc.modalPresentationStyle = .overCurrentContext
                vc.modalTransitionStyle = .coverVertical
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
                        .pushNotifications,
                        .shakeForDataPopUp,
                        .maintenanceLocation:
                    from.present(vc, animated: true, completion: nil)
                case .shakeForDataView,
                        .shakeForDataResult:
                    from.navigationController?.pushViewController(vc, animated: true)
                    from.navigationController?.viewControllers = [vc]
                default:
                    from.navigationController?.pushViewController(vc, animated: true)
                }
            }
        }
    }
}
