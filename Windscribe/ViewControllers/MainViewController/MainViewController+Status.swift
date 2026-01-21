//
//  MainViewController+Status.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import NetworkExtension
import RxSwift
import UIKit

extension MainViewController {
    func updateConnectedState() {
        let state = vpnConnectionViewModel.connectedState.value
        animateConnectedState(with: state, animated: false)
    }

    func animateConnectedState(with info: ConnectionStateInfo, animated: Bool = true) {
        DispatchQueue.main.async {
            let duration = (animated &&  info.state != .automaticFailed) ? 0.25 : 0.0
            UIView.animate(withDuration: duration) {
                if info.state == .disconnected {
                    let isOnline = self.viewModel.appNetwork.value.status == .connected
                    if !isOnline {
                        self.connectionStateInfoView.showNoInternetConnection()
                    }
                }
            }
            self.updateRefreshControls()
        }
    }
}
