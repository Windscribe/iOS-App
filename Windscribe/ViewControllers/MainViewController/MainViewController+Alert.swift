//
//  MainViewController+Alert.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import Swinject

extension MainViewController {
    func displayConnectingAlert() {
        AlertManager.shared.showSimpleAlert(
            viewController: self,
            title: TextsAsset.ConnectingAlert.title,
            message: TextsAsset.ConnectingAlert.message,
            buttonText: TextsAsset.okay
        )
    }

    func displayDisconnectingAlert() {
        AlertManager.shared.showSimpleAlert(
            viewController: self,
            title: TextsAsset.DisconnectingAlert.title,
            message: TextsAsset.DisconnectingAlert.message,
            buttonText: TextsAsset.okay
        )
    }

    func displayInternetConnectionLostAlert() {
        AlertManager.shared.showSimpleAlert(
            viewController: self,
            title: TextsAsset.NoInternetAlert.title,
            message: TextsAsset.NoInternetAlert.message,
            buttonText: TextsAsset.okay
        )
    }

    func checkAndShowShareDialogIfNeed() {
        ReferAndShareManager.shared.checkAndShowDialogFirstTime {
            self.router?.routeTo(to: RouteID.shareWithFriends, from: self)
        }
    }

    func displayReviewConfirmationAlert() {
        let cancelAction = UIAlertAction(title: "Not Now", style: .cancel, handler: nil)

        let showAction = UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
            self?.vpnConnectionViewModel.appReviewManager.openAppStoreForReview()
        })

        AlertManager.shared.showAlert(
            title: "Enjoying Windscribe?",
            message: "Do you want to rate it on the App Store? Your feedback is very important to us!",
            actions: [showAction, cancelAction])
    }
}
