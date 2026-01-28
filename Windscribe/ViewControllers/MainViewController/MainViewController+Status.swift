//
//  MainViewController+Status.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import NetworkExtension
import UIKit

extension MainViewController {
    func checkNetworkState(for appNetwork: AppNetwork) {
        DispatchQueue.main.async {
            UIView.animate(withDuration: 0.25) {
                if self.vpnConnectionViewModel.isDisconnected() {
                    let isOnline = appNetwork.status == .connected
                    if !isOnline {
                        self.connectionStateInfoView.showNoInternetConnection()
                    } else {
                        self.connectionStateInfoView.hideNoInternetConnection()
                    }
                }
            }
            self.updateRefreshControls()
        }
    }
}
