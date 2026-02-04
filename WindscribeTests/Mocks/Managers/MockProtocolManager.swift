//
//  MockProtocolManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-01-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import NetworkExtension
@testable import Windscribe

class MockProtocolManager: ProtocolManagerType {

    // MARK: Protocol Properties

    var refreshProtocolsCalled = false
    var lastShouldReset: Bool?
    var lastShouldReconnect: Bool?

    var goodProtocol: ProtocolPort?
    var resetGoodProtocolTime: Date?
    var currentProtocolSubject = CurrentValueSubject<ProtocolPort?, Never>(nil)
    var connectionProtocolSubject = CurrentValueSubject<(protocolPort: ProtocolPort, connectionType: ConnectionType)?, Never>(nil)
    var showProtocolSwitchTrigger = PassthroughSubject<Void, Never>()
    var showAllProtocolsFailedTrigger = PassthroughSubject<Void, Never>()
    var showNoInternetBeforeFailoverTrigger = PassthroughSubject<Void, Never>()
    var showConnectionModeTriggeer = PassthroughSubject<Void, Never>()
    var disconnectConnectionTrigger = PassthroughSubject<Void, Never>()
    var displayProtocolsSubject = CurrentValueSubject<[DisplayProtocolPort], Never>([])
    var failOverTimerCompletedSubject = PassthroughSubject<Void, Never>()

    // MARK: Protocol Methods

    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async {
        refreshProtocolsCalled = true
        lastShouldReset = shouldReset
        lastShouldReconnect = shouldReconnect
    }

    func getRefreshedProtocols() async -> [DisplayProtocolPort] { return [] }
    func getDisplayProtocols() async -> [DisplayProtocolPort] { return [] }
    func getNextProtocol() async -> ProtocolPort { return ProtocolPort(protocolName: "IKEv2", portName: "500") }
    func getProtocol() -> ProtocolPort { return ProtocolPort(protocolName: "IKEv2", portName: "500") }
    func onProtocolFail() async {}
    func onUserSelectProtocol(proto: ProtocolPort, connectionType: ConnectionType) {}
    func resetGoodProtocol() {}
    func onConnectStateChange(state: NEVPNStatus) {}
    func saveCurrentWifiNetworks() {}
    func cancelFailoverTimer() {}

    // MARK: Helper Methods

    func reset() {
        refreshProtocolsCalled = false
        lastShouldReset = nil
        lastShouldReconnect = nil
    }
}
