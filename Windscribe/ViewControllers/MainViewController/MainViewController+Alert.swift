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
}
