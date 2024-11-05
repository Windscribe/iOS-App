//
//  ConnectionStateViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 09/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol ConnectionStateViewModelType {
    var selectedNodeSubject: PublishSubject<SelectedNode> {get}
    var loadLatencyValuesSubject: PublishSubject<LoadLatencyInfo> {get}
    var showAutoModeScreenTrigger: PublishSubject<Void> {get}
    var openNetworkHateUsDialogTrigger: PublishSubject<Void> {get}
    var pushNotificationPermissionsTrigger: PublishSubject<Void> {get}
    var siriShortcutTrigger: PublishSubject<Void> {get}
    var requestLocationTrigger: PublishSubject<Void> {get}
    var enableConnectTrigger: PublishSubject<Void> {get}
    var ipAddressSubject: PublishSubject<String> {get}
    var autoModeSelectorHiddenChecker: PublishSubject<(_ value: Bool) -> Void> {get}
    var connectedState: BehaviorSubject<ConnectionStateInfo> {get}

    func disconnect()
    func displayLocalIPAddress()
    func displayLocalIPAddress(force: Bool)
    func becameActive()
    func startConnecting()
    func updateLoadLatencyValuesOnDisconnect(with value: Bool)
    
    var vpnManager: VPNManager { get }
    
    // Check State
    func isConnected() -> Bool
    func isDisconnected() -> Bool
    
    // Actions
    func setOutOfData()
}

class ConnectionStateViewModel: ConnectionStateViewModelType {
    let connectedState: BehaviorSubject<ConnectionStateInfo>
    let selectedNodeSubject: PublishSubject<SelectedNode>
    let loadLatencyValuesSubject: PublishSubject<LoadLatencyInfo>
    let showAutoModeScreenTrigger: PublishSubject<Void>
    let openNetworkHateUsDialogTrigger: PublishSubject<Void>
    let pushNotificationPermissionsTrigger: PublishSubject<Void>
    let siriShortcutTrigger: PublishSubject<Void>
    let requestLocationTrigger: PublishSubject<Void>
    let enableConnectTrigger: PublishSubject<Void>
    let ipAddressSubject: PublishSubject<String>
    let autoModeSelectorHiddenChecker: PublishSubject<(_ value: Bool) -> Void>

    private let connectionStateManager: ConnectionStateManagerType
    let vpnManager: VPNManager

    init(connectionStateManager: ConnectionStateManagerType, vpnManager: VPNManager) {
        self.connectionStateManager = connectionStateManager
        self.vpnManager = vpnManager
        self.connectedState = connectionStateManager.connectedState
        self.selectedNodeSubject = connectionStateManager.selectedNodeSubject
        self.loadLatencyValuesSubject = connectionStateManager.loadLatencyValuesSubject
        self.showAutoModeScreenTrigger = connectionStateManager.showAutoModeScreenTrigger
        self.openNetworkHateUsDialogTrigger = connectionStateManager.openNetworkHateUsDialogTrigger
        self.pushNotificationPermissionsTrigger = connectionStateManager.pushNotificationPermissionsTrigger
        self.siriShortcutTrigger = connectionStateManager.siriShortcutTrigger
        self.requestLocationTrigger = connectionStateManager.requestLocationTrigger
        self.enableConnectTrigger = connectionStateManager.enableConnectTrigger
        self.ipAddressSubject = connectionStateManager.ipAddressSubject
        self.autoModeSelectorHiddenChecker = connectionStateManager.autoModeSelectorHiddenChecker
    }

    func disconnect() {
        connectionStateManager.disconnect()
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

    func startConnecting() {
        connectionStateManager.setConnecting()
    }

    func updateLoadLatencyValuesOnDisconnect(with value: Bool) {
        connectionStateManager.updateLoadLatencyValuesOnDisconnect(with: value)
    }
}

extension ConnectionStateViewModel {
    func isConnected() -> Bool {
        vpnManager.isConnected()
    }
    func isDisconnected() -> Bool {
        vpnManager.isDisconnected()
    }
    
    func setOutOfData() {
        if vpnManager.isConnected() && !vpnManager.isCustomConfigSelected() {
            disconnect()
        }
    }
}
