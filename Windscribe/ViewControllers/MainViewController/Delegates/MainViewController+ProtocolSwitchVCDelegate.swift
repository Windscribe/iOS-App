//
//  MainViewController+ProtocolSwitchVCDelegate.swift
//  Windscribe
//
//  Created by Thomas on 28/11/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import UIKit

extension MainViewController: ProtocolSwitchVCDelegate {
    func disconnectFromFailOver() {
        connectionStateViewModel.disconnect()
    }

    func protocolSwitchVCCountdownCompleted() {
        if vpnManager.isConnected() && vpnManager.isFromProtocolChange {
            configureVPN()
        } else {
            vpnManager.connectUsingAutomaticMode()
            connectionStateViewModel.startConnecting()
        }
    }
}
