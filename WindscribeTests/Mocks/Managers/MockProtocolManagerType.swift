//
//  MockProtocolManagerType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 13/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import NetworkExtension
@testable import Windscribe

class MockProtocolManagerType: ProtocolManagerType {
    // ProtocolManagerType protocol properties
    var goodProtocol: Windscribe.ProtocolPort?
    var resetGoodProtocolTime: Date?

    var currentProtocolSubject = CurrentValueSubject<Windscribe.ProtocolPort?, Never>(nil)
    var connectionProtocolSubject = CurrentValueSubject<(protocolPort: Windscribe.ProtocolPort, connectionType: Windscribe.ConnectionType)?, Never>(nil)
    var displayProtocolsSubject = CurrentValueSubject<[Windscribe.DisplayProtocolPort], Never>([])
    var showProtocolSwitchTrigger = PassthroughSubject<Void, Never>()
    var showAllProtocolsFailedTrigger = PassthroughSubject<Void, Never>()
    var showNoInternetBeforeFailoverTrigger = PassthroughSubject<Void, Never>()
    var showConnectionModeTriggeer = PassthroughSubject<Void, Never>()
    var disconnectConnectionTrigger = PassthroughSubject<Void, Never>()
    var failOverTimerCompletedSubject = PassthroughSubject<Void, Never>()

    // Mock storage
    private var protocols: [Windscribe.DisplayProtocolPort] = []
    private var currentProtocolIndex = 0

    // Mock configuration
    var mockProtocols: [Windscribe.DisplayProtocolPort] = []
    var mockNextProtocol: Windscribe.ProtocolPort = ("WireGuard", "443")
    var mockCurrentProtocol: Windscribe.ProtocolPort = ("WireGuard", "443")
    var shouldTriggerProtocolSwitch = false
    var shouldTriggerAllProtocolsFailed = false
    var shouldTriggerNoInternet = false
    var shouldTriggerConnectionMode = false
    var shouldTriggerDisconnect = false
    var shouldCompleteFailoverTimer = false

    // Call tracking
    var refreshProtocolsCallCount = 0
    var getRefreshedProtocolsCallCount = 0
    var getDisplayProtocolsCallCount = 0
    var getNextProtocolCallCount = 0
    var getProtocolCallCount = 0
    var onProtocolFailCallCount = 0
    var onUserSelectProtocolCallCount = 0
    var resetGoodProtocolCallCount = 0
    var onConnectStateChangeCallCount = 0
    var saveCurrentWifiNetworksCallCount = 0
    var cancelFailoverTimerCallCount = 0

    var lastRefreshProtocolsShouldReset: Bool?
    var lastRefreshProtocolsShouldReconnect: Bool?
    var lastUserSelectedProtocol: Windscribe.ProtocolPort?
    var lastUserSelectedConnectionType: Windscribe.ConnectionType?
    var lastConnectState: NEVPNStatus?

    // ProtocolManagerType protocol methods
    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async {
        refreshProtocolsCallCount += 1
        lastRefreshProtocolsShouldReset = shouldReset
        lastRefreshProtocolsShouldReconnect = shouldReconnect

        if shouldReset {
            protocols = mockProtocols
            currentProtocolIndex = 0
            goodProtocol = nil
            resetGoodProtocolTime = nil
        }

        displayProtocolsSubject.send(protocols)

        if let firstProtocol = protocols.first?.protocolPort {
            currentProtocolSubject.send(firstProtocol)
            if shouldReconnect {
                connectionProtocolSubject.send((protocolPort: firstProtocol, connectionType: .user))
            }
        }

        if shouldTriggerProtocolSwitch {
            showProtocolSwitchTrigger.send()
        }

        if shouldTriggerConnectionMode {
            showConnectionModeTriggeer.send()
        }
    }

    func getRefreshedProtocols() async -> [Windscribe.DisplayProtocolPort] {
        getRefreshedProtocolsCallCount += 1
        await refreshProtocols(shouldReset: false, shouldReconnect: false)
        return protocols
    }

    func getDisplayProtocols() async -> [Windscribe.DisplayProtocolPort] {
        getDisplayProtocolsCallCount += 1
        return protocols
    }

    func getNextProtocol() async -> Windscribe.ProtocolPort {
        getNextProtocolCallCount += 1

        if protocols.isEmpty {
            return mockNextProtocol
        }

        // Move to next protocol in list
        currentProtocolIndex = (currentProtocolIndex + 1) % protocols.count
        let nextProtocol = protocols[currentProtocolIndex].protocolPort
        currentProtocolSubject.send(nextProtocol)

        return nextProtocol
    }

    func getProtocol() -> Windscribe.ProtocolPort {
        getProtocolCallCount += 1

        if protocols.isEmpty {
            return mockCurrentProtocol
        }

        return protocols[currentProtocolIndex].protocolPort
    }

    func onProtocolFail() async {
        onProtocolFailCallCount += 1

        // Mark current protocol as failed
        if currentProtocolIndex < protocols.count {
            protocols[currentProtocolIndex].viewType = .fail
            displayProtocolsSubject.send(protocols)
        }

        // Move to next protocol
        _ = await getNextProtocol()

        if shouldTriggerAllProtocolsFailed {
            showAllProtocolsFailedTrigger.send()
        }

        if shouldCompleteFailoverTimer {
            failOverTimerCompletedSubject.send()
        }
    }

    func onUserSelectProtocol(proto: Windscribe.ProtocolPort, connectionType: Windscribe.ConnectionType) {
        onUserSelectProtocolCallCount += 1
        lastUserSelectedProtocol = proto
        lastUserSelectedConnectionType = connectionType

        // Update current protocol
        currentProtocolSubject.send(proto)
        connectionProtocolSubject.send((protocolPort: proto, connectionType: connectionType))

        // Find and mark the selected protocol
        if let index = protocols.firstIndex(where: { $0.protocolPort == proto }) {
            currentProtocolIndex = index
            protocols[index].viewType = .connected
            displayProtocolsSubject.send(protocols)
        }
    }

    func resetGoodProtocol() {
        resetGoodProtocolCallCount += 1
        goodProtocol = nil
        resetGoodProtocolTime = Date()
    }

    func onConnectStateChange(state: NEVPNStatus) {
        onConnectStateChangeCallCount += 1
        lastConnectState = state

        // Update protocol view types based on connection state
        if state == .connected {
            if currentProtocolIndex < protocols.count {
                protocols[currentProtocolIndex].viewType = .connected
                goodProtocol = protocols[currentProtocolIndex].protocolPort
                displayProtocolsSubject.send(protocols)
            }
        } else if state == .disconnected {
            // Reset all protocols to normal
            for i in 0..<protocols.count {
                if protocols[i].viewType == .connected {
                    protocols[i].viewType = .normal
                }
            }
            displayProtocolsSubject.send(protocols)
        }

        if shouldTriggerNoInternet {
            showNoInternetBeforeFailoverTrigger.send()
        }

        if shouldTriggerDisconnect {
            disconnectConnectionTrigger.send()
        }
    }

    func saveCurrentWifiNetworks() {
        saveCurrentWifiNetworksCallCount += 1
    }

    func cancelFailoverTimer() {
        cancelFailoverTimerCallCount += 1
    }

    // MARK: - Helper Methods

    func reset() {
        goodProtocol = nil
        resetGoodProtocolTime = nil
        protocols = []
        currentProtocolIndex = 0

        mockProtocols = []
        mockNextProtocol = ("WireGuard", "443")
        mockCurrentProtocol = ("WireGuard", "443")
        shouldTriggerProtocolSwitch = false
        shouldTriggerAllProtocolsFailed = false
        shouldTriggerNoInternet = false
        shouldTriggerConnectionMode = false
        shouldTriggerDisconnect = false
        shouldCompleteFailoverTimer = false

        refreshProtocolsCallCount = 0
        getRefreshedProtocolsCallCount = 0
        getDisplayProtocolsCallCount = 0
        getNextProtocolCallCount = 0
        getProtocolCallCount = 0
        onProtocolFailCallCount = 0
        onUserSelectProtocolCallCount = 0
        resetGoodProtocolCallCount = 0
        onConnectStateChangeCallCount = 0
        saveCurrentWifiNetworksCallCount = 0
        cancelFailoverTimerCallCount = 0

        lastRefreshProtocolsShouldReset = nil
        lastRefreshProtocolsShouldReconnect = nil
        lastUserSelectedProtocol = nil
        lastUserSelectedConnectionType = nil
        lastConnectState = nil

        currentProtocolSubject.send(nil)
        connectionProtocolSubject.send(nil)
        displayProtocolsSubject.send([])
    }

    func setProtocols(_ newProtocols: [Windscribe.DisplayProtocolPort]) {
        protocols = newProtocols
        mockProtocols = newProtocols
        displayProtocolsSubject.send(protocols)

        if let firstProtocol = protocols.first?.protocolPort {
            currentProtocolSubject.send(firstProtocol)
        }
    }

    func addProtocol(_ protocolPort: Windscribe.ProtocolPort, viewType: ProtocolViewType = .normal) {
        let displayProtocol = Windscribe.DisplayProtocolPort(protocolPort: protocolPort, viewType: viewType)
        protocols.append(displayProtocol)
        mockProtocols.append(displayProtocol)
        displayProtocolsSubject.send(protocols)
    }

    func getCurrentProtocolIndex() -> Int {
        return currentProtocolIndex
    }

    func getProtocolCount() -> Int {
        return protocols.count
    }
}

