//
//  ProtocolSwitchDelegateViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 16/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ProtocolSwitchDelegateViewModelType: ProtocolSwitchVCDelegate {
    var configureVPNTrigger: PublishSubject<Void> { get }
}

class ProtocolSwitchDelegateViewModel: ProtocolSwitchDelegateViewModelType {
    var configureVPNTrigger = PublishSubject<Void>()

    var vpnManager: VPNManager
    var connectionStateManager: ConnectionStateManagerType

    init(vpnManager: VPNManager, connectionStateManager: ConnectionStateManagerType) {
        self.vpnManager = vpnManager
        self.connectionStateManager = connectionStateManager
    }
}

extension ProtocolSwitchDelegateViewModel: ProtocolSwitchVCDelegate {
    func disconnectFromFailOver() {
        connectionStateManager.disconnect()
    }

    func protocolSwitchVCCountdownCompleted() {
        if vpnManager.isConnected() && vpnManager.isFromProtocolChange {
            configureVPNTrigger.onNext(())
        } else {
            vpnManager.connectUsingAutomaticMode()
            connectionStateManager.setConnecting()
        }
    }
}
