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
    var connectedState: BehaviorSubject<ConnectionStateInfo> { get }

    func disconnect()
    func displayLocalIPAddress()
    func displayLocalIPAddress(force: Bool)
    func becameActive()
//    func startConnecting()
    func updateLoadLatencyValuesOnDisconnect(with value: Bool)

    var vpnManager: VPNManager { get }

    // Check State
    func isConnected() -> Bool
    func isDisconnected() -> Bool

    // Actions
    func setOutOfData()
    func enableConnection()
}

class ConnectionStateViewModel: ConnectionStateViewModelType {
    let connectedState = BehaviorSubject<ConnectionStateInfo>(value: ConnectionStateInfo.defaultValue())
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

    private let disposeBag = DisposeBag()
    private let connectionStateManager: ConnectionStateManagerType
    let vpnManager: VPNManager

    init(connectionStateManager: ConnectionStateManagerType, vpnManager: VPNManager) {
        self.connectionStateManager = connectionStateManager
        self.vpnManager = vpnManager
//        connectedState = connectionStateManager.connectedState
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
        
        vpnManager.vpnInfo.subscribe(onNext: { vpnInfo in
            guard let vpnInfo = vpnInfo else { return }
            self.connectedState.onNext(
                ConnectionStateInfo(state: ConnectionState.state(from: vpnInfo.status),
                                    isCustomConfigSelected: false,
                                    internetConnectionAvailable: false,
                                    connectedWifi: nil))
        }).disposed(by: disposeBag)
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

//    func startConnecting() {
//        connectionStateManager.setConnecting()
//    }

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
        if vpnManager.isConnected(), !vpnManager.isCustomConfigSelected() {
            disconnect()
        }
    }
    
    func enableConnection() {
        Task {
            let protocolPort = await vpnManager.getProtocolPort()
            let locationID = vpnManager.getLocationId()
            _ = vpnManager.connectFromViewModel(locationId: locationID, proto: protocolPort)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        print("Connection process completed.")
                    case let .failure(error):
                        print(error.localizedDescription)
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        print(message)
                    case let .validated(ip):
                        print(ip)
                    case let .vpn(status):
                        print(status)
                    default:
                        break
                    }
                })
        }
    }
    
    func disableConnection() {
        _ = vpnManager.disconnectFromViewModel().receive(on: DispatchQueue.main)
            .sink { completion in
                switch completion {
                case .finished:
                    print("disconnect finished")
                case let .failure(error):
                    print(error.localizedDescription)
                }
            } receiveValue: { state in
                switch state {
                case let .update(message):
                    print(message)
                case let .vpn(status):
                    print(status)
                default: ()
                }
            }

    }
}
