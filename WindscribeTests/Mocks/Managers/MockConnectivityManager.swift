//
//  MockConnectivityManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-12-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
@testable import Windscribe

class MockConnectivityManager: ConnectivityManager {
    var mockNetwork: AppNetwork = AppNetwork(.disconnected)
    var mockInternetAvailable: Bool = true
    var mockWifiSSID: String?

    var network: CurrentValueSubject<AppNetwork, Never>

    init() {
        self.network = CurrentValueSubject<AppNetwork, Never>(mockNetwork)
    }

    func getNetwork() -> AppNetwork {
        return mockNetwork
    }

    func refreshNetwork() {
        network.send(mockNetwork)
    }

    func internetConnectionAvailable() -> Bool {
        return mockInternetAvailable
    }

    func getWifiSSID() -> String? {
        return mockWifiSSID ?? mockNetwork.name
    }

    func awaitNetwork(maxTime: Double) async throws {
    }
}
