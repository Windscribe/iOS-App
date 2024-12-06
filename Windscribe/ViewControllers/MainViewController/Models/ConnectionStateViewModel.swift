//
//  ConnectionStateViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 09/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

protocol ConnectionStateViewModelType {

    func displayLocalIPAddress()
    func displayLocalIPAddress(force: Bool)
    func becameActive()
}

class ConnectionStateViewModel: ConnectionStateViewModelType {

    private let connectionStateManager: ConnectionStateManagerType
    let vpnManager: VPNManager

    init(connectionStateManager: ConnectionStateManagerType, vpnManager: VPNManager) {
        self.connectionStateManager = connectionStateManager
        self.vpnManager = vpnManager
    }

    func displayLocalIPAddress() {
        connectionStateManager.displayLocalIPAddress()
    }

    func displayLocalIPAddress(force: Bool) {
        connectionStateManager.displayLocalIPAddress(force: force)
    }

    func becameActive() {
        connectionStateManager.checkConnectedState()
    }
}
