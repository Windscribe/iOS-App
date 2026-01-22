//
//  VPNManagerViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 09/05/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

protocol ConnectionStateViewModelType {
    var selectedNodeSubject: PassthroughSubject<SelectedNode, Never> {get}
    var loadLatencyValuesSubject: PassthroughSubject<LoadLatencyInfo, Never> {get}
    var showAutoModeScreenTrigger: PassthroughSubject<Void, Never> {get}
    var openNetworkHateUsDialogTrigger: PassthroughSubject<Void, Never> {get}
    var pushNotificationPermissionsTrigger: PassthroughSubject<Void, Never> {get}
    var siriShortcutTrigger: PassthroughSubject<Void, Never> {get}
    var requestLocationTrigger: PassthroughSubject<Void, Never> {get}
    var enableConnectTrigger: PassthroughSubject<Void, Never> {get}
    var ipAddressSubject: PassthroughSubject<String, Never> {get}
    var autoModeSelectorHiddenChecker: PassthroughSubject<(_ value: Bool) -> Void, Never> {get}
    var connectedState: CurrentValueSubject<ConnectionStateInfo, Never> {get}

    func disconnect()
    func displayLocalIPAddress()
    func displayLocalIPAddress(force: Bool)
    func becameActive()
    func startConnecting()
    func updateLoadLatencyValuesOnDisconnect(with value: Bool)
}

class ConnectionStateViewModel: ConnectionStateViewModelType {
    let connectedState: CurrentValueSubject<ConnectionStateInfo, Never>
    let selectedNodeSubject: PassthroughSubject<SelectedNode, Never>
    let loadLatencyValuesSubject: PassthroughSubject<LoadLatencyInfo, Never>
    let showAutoModeScreenTrigger: PassthroughSubject<Void, Never>
    let openNetworkHateUsDialogTrigger: PassthroughSubject<Void, Never>
    let pushNotificationPermissionsTrigger: PassthroughSubject<Void, Never>
    let siriShortcutTrigger: PassthroughSubject<Void, Never>
    let requestLocationTrigger: PassthroughSubject<Void, Never>
    let enableConnectTrigger: PassthroughSubject<Void, Never>
    let ipAddressSubject: PassthroughSubject<String, Never>
    let autoModeSelectorHiddenChecker: PassthroughSubject<(_ value: Bool) -> Void, Never>

    var connectionStateManager: ConnectionStateManagerType

    init(connectionStateManager: ConnectionStateManagerType) {
        self.connectionStateManager = connectionStateManager
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
        if connectionStateManager.isConnected() || connectionStateManager.isDisconnected() {
            connectionStateManager.displayLocalIPAddress(force: true)
        }
    }

    func startConnecting() {
        connectionStateManager.setConnecting()
    }

    func updateLoadLatencyValuesOnDisconnect(with value: Bool) {
        connectionStateManager.updateLoadLatencyValuesOnDisconnect(with: value)
    }
}
