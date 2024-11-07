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
    var selectedNodeSubject: PublishSubject<SelectedNode> { get }
    var loadLatencyValuesSubject: PublishSubject<LoadLatencyInfo> { get }
    var showAutoModeScreenTrigger: PublishSubject<Void> { get }
    var openNetworkHateUsDialogTrigger: PublishSubject<Void> { get }
    var pushNotificationPermissionsTrigger: PublishSubject<Void> { get }
    var siriShortcutTrigger: PublishSubject<Void> { get }
    var requestLocationTrigger: PublishSubject<Void> { get }
    var enableConnectTrigger: PublishSubject<Void> { get }
    var ipAddressSubject: PublishSubject<String> { get }
    var autoModeSelectorHiddenChecker: PublishSubject<(_ value: Bool) -> Void> { get }

    func displayLocalIPAddress()
    func displayLocalIPAddress(force: Bool)
    func becameActive()
    func updateLoadLatencyValuesOnDisconnect(with value: Bool)
    func updateBestLocation(bestLocation: BestLocation)
}

class ConnectionStateViewModel: ConnectionStateViewModelType {
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
        selectedNodeSubject = connectionStateManager.selectedNodeSubject
        loadLatencyValuesSubject = connectionStateManager.loadLatencyValuesSubject
        showAutoModeScreenTrigger = connectionStateManager.showAutoModeScreenTrigger
        openNetworkHateUsDialogTrigger = connectionStateManager.openNetworkHateUsDialogTrigger
        pushNotificationPermissionsTrigger = connectionStateManager.pushNotificationPermissionsTrigger
        siriShortcutTrigger = connectionStateManager.siriShortcutTrigger
        requestLocationTrigger = connectionStateManager.requestLocationTrigger
        enableConnectTrigger = connectionStateManager.enableConnectTrigger
        ipAddressSubject = connectionStateManager.ipAddressSubject
        autoModeSelectorHiddenChecker = connectionStateManager.autoModeSelectorHiddenChecker
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

    func updateLoadLatencyValuesOnDisconnect(with value: Bool) {
        connectionStateManager.updateLoadLatencyValuesOnDisconnect(with: value)
    }
}

extension ConnectionStateViewModel {
    func updateBestLocation(bestLocation: BestLocation) {
        connectionStateManager.updateBestLocation(bestLocation: bestLocation)
    }
}
