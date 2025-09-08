//
//  MainViewController+Alert.swift
//  Windscribe
//
//  Created by Thomas on 23/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import UIKit

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
        Task {
            let shouldShow = await referAndShareManager.checkAndShowDialogFirstTime()
            if shouldShow {
                await MainActor.run {
                    self.router?.routeTo(to: RouteID.shareWithFriends, from: self)
                }
            }
        }
    }

    func displayReviewConfirmationAlert() {
        let cancelAction = UIAlertAction(title: TextsAsset.RateUs.maybeLater, style: .cancel, handler: nil)

        let showAction = UIAlertAction(title: TextsAsset.RateUs.action, style: .default, handler: { [weak self] _ in
            self?.vpnConnectionViewModel.appReviewManager.openAppStoreForReview()
        })

        AlertManager.shared.showAlert(
            title: TextsAsset.RateUs.title,
            message: TextsAsset.RateUs.description,
            actions: [showAction, cancelAction])
    }
}
