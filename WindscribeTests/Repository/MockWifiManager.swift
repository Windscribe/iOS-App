//
//  MockWifiManager.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 16/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockWifiManager: WifiManager {

    // Mock properties
    var mockConnectedNetwork: WifiNetworkModel?
    var mockNetworks: [WifiNetworkModel] = []
    var mockIsConnectedWifiTrusted: Bool = false

    // WifiManager protocol properties
    var selectedPreferredProtocol: String?
    var selectedPreferredPort: String?
    var selectedPreferredProtocolStatus: Bool?

    // Call tracking
    var getConnectedNetworkCallCount = 0
    var isConnectedWifiTrustedCallCount = 0
    var saveCurrentWifiNetworksCallCount = 0
    var addNetworkCallCount = 0
    var removeNetworkCallCount = 0
    var updateNetworkCallCount = 0
    var lastAddedNetwork: WifiNetworkModel?
    var lastRemovedNetwork: WifiNetworkModel?
    var lastUpdatedNetwork: WifiNetworkModel?

    // MARK: - WifiManager Protocol Methods

    func getConnectedNetwork() -> WifiNetworkModel? {
        getConnectedNetworkCallCount += 1
        return mockConnectedNetwork
    }

    func isConnectedWifiTrusted() -> Bool {
        isConnectedWifiTrustedCallCount += 1
        return mockIsConnectedWifiTrusted
    }

    func saveCurrentWifiNetworks() {
        saveCurrentWifiNetworksCallCount += 1
    }

    // MARK: - Helper Methods (Not part of protocol, for testing only)

    func addNetwork(_ network: WifiNetworkModel) {
        addNetworkCallCount += 1
        lastAddedNetwork = network
        mockNetworks.append(network)
    }

    func removeNetwork(_ network: WifiNetworkModel) {
        removeNetworkCallCount += 1
        lastRemovedNetwork = network
        mockNetworks.removeAll { $0.SSID == network.SSID }
    }

    func updateNetwork(_ network: WifiNetworkModel) {
        updateNetworkCallCount += 1
        lastUpdatedNetwork = network
        if let index = mockNetworks.firstIndex(where: { $0.SSID == network.SSID }) {
            mockNetworks[index] = network
        }
    }

    func getAllNetworks() -> [WifiNetworkModel] {
        return mockNetworks
    }

    func getNetwork(ssid: String) -> WifiNetworkModel? {
        return mockNetworks.first { $0.SSID == ssid }
    }

    // MARK: - Reset

    func reset() {
        mockConnectedNetwork = nil
        mockNetworks = []
        mockIsConnectedWifiTrusted = false
        selectedPreferredProtocol = nil
        selectedPreferredPort = nil
        selectedPreferredProtocolStatus = nil
        getConnectedNetworkCallCount = 0
        isConnectedWifiTrustedCallCount = 0
        saveCurrentWifiNetworksCallCount = 0
        addNetworkCallCount = 0
        removeNetworkCallCount = 0
        updateNetworkCallCount = 0
        lastAddedNetwork = nil
        lastRemovedNetwork = nil
        lastUpdatedNetwork = nil
    }
}
