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
        viewModel.showSimpleAlert(
            viewController: self,
            title: TextsAsset.ConnectingAlert.title,
            message: TextsAsset.ConnectingAlert.message,
            buttonText: TextsAsset.okay
        )
    }

    func displayDisconnectingAlert() {
        viewModel.showSimpleAlert(
            viewController: self,
            title: TextsAsset.DisconnectingAlert.title,
            message: TextsAsset.DisconnectingAlert.message,
            buttonText: TextsAsset.okay
        )
    }

    func displayInternetConnectionLostAlert() {
        viewModel.showSimpleAlert(
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

    func showUpdateAvailableAlert(model: CheckUpdateModel) {
        let updateAction = UIAlertAction(title: TextsAsset.UpdateAlert.updateNow, style: .default) { _ in
            if let url = URL(string: Links.itmsLink),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }
        let version = model.latestVersion ?? ""

        // Force-update variant: undismissable. Single "Update Now" action that
        // opens the App Store. If the user dismisses by backgrounding the app
        // without actually updating, MainViewController's foreground observer
        // re-presents this alert because viewModel.pendingForceUpdate is still set.
        if model.force {
            let forceMessage = version.isEmpty
                ? TextsAsset.UpdateAlert.forceMessage
                : String(format: TextsAsset.UpdateAlert.forceMessageWithVersion, version)
            viewModel.showAlert(
                title: TextsAsset.UpdateAlert.forceTitle,
                message: forceMessage,
                actions: [updateAction])
            return
        }

        let laterAction = UIAlertAction(title: TextsAsset.UpdateAlert.updateLater, style: .cancel, handler: nil)
        let message = version.isEmpty
            ? TextsAsset.UpdateAlert.message
            : String(format: TextsAsset.UpdateAlert.messageWithVersion, version)
        viewModel.showAlert(
            title: TextsAsset.UpdateAlert.title,
            message: message,
            actions: [updateAction, laterAction])
    }

    func displayReviewConfirmationAlert() {
        let cancelAction = UIAlertAction(title: TextsAsset.RateUs.maybeLater, style: .cancel, handler: nil)

        let showAction = UIAlertAction(title: TextsAsset.RateUs.action, style: .default, handler: { [weak self] _ in
            self?.vpnConnectionViewModel.appReviewManager.openAppStoreForReview()
        })

        viewModel.showAlert(
            title: TextsAsset.RateUs.title,
            message: TextsAsset.RateUs.description,
            actions: [showAction, cancelAction])
    }
}
