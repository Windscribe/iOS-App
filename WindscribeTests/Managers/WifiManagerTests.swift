//
//  WifiManagerTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 2026-08-21.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Combine
import XCTest
@testable import Windscribe

final class WifiManagerTests: XCTestCase {
    func testNetworkTransitionUpdatesConnectedNetworkBeforeProtocolPreferences() async {
        let wifiA = WifiNetworkModel(SSID: "Wifi A",
                                     status: false,
                                     protocolType: VPNProtocolType.wireGuard.identifier,
                                     port: "443",
                                     preferredProtocol: VPNProtocolType.iKEv2.identifier,
                                     preferredPort: "500",
                                     preferredProtocolStatus: true)
        let wifiB = WifiNetworkModel(SSID: "Wifi B",
                                     status: true,
                                     protocolType: VPNProtocolType.wireGuard.identifier,
                                     port: "443",
                                     preferredProtocol: VPNProtocolType.stealth.identifier,
                                     preferredPort: "443",
                                     preferredProtocolStatus: true)
        let connectivity = MockConnectivityManager()
        let repository = WifiManagerTestRepository(networks: [wifiA, wifiB])
        connectivity.mockNetwork = AppNetwork(.connected, networkType: .wifi, name: wifiA.SSID)
        connectivity.network.send(connectivity.mockNetwork)

        let manager = WifiManagerImpl(preferences: MockPreferences(),
                                      connectivity: connectivity,
                                      logger: MockLogger(),
                                      wifiNetworkRepository: repository)

        await Task.yield()
        XCTAssertEqual(manager.getConnectedNetwork()?.SSID, wifiA.SSID)
        XCTAssertEqual(manager.selectedPreferredProtocol, wifiA.preferredProtocol)
        XCTAssertEqual(manager.selectedPreferredPort, wifiA.preferredPort)

        connectivity.mockNetwork = AppNetwork(.connected, networkType: .wifi, name: wifiB.SSID)
        connectivity.network.send(connectivity.mockNetwork)

        await Task.yield()
        XCTAssertEqual(manager.getConnectedNetwork()?.SSID, wifiB.SSID)
        XCTAssertEqual(manager.selectedPreferredProtocol, wifiB.preferredProtocol)
        XCTAssertEqual(manager.selectedPreferredPort, wifiB.preferredPort)
    }
}

private final class WifiManagerTestRepository: WifiNetworkRepository {
    let networks: CurrentValueSubject<[WifiNetworkModel], Never>

    init(networks: [WifiNetworkModel]) {
        self.networks = CurrentValueSubject(networks)
    }

    func addNetwork(status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String) {}
    func addNetwork(wifiSSID: String, status: Bool, protocolType: String, port: String, preferredProtocol: String, preferredPort: String) {}
    func getCurrentNetwork() -> WifiNetworkModel? { nil }
    func getOtherNetworks() -> [WifiNetworkModel]? { nil }
    func removeNetwork(network: WifiNetworkModel) {}
    func setNetworkPreferredProtocol(network: WifiNetworkModel, status: Bool) {}
    func setNetworkDontAskAgainForPreferredProtocol(network: WifiNetworkModel) {}
    func incrementNetworkDismissCount(network: WifiNetworkModel) {}
    func updateNetworkPreferredProtocol(with preferredProtocol: String, andPort port: String) {}
    func updateNetworkPreferredProtocol(network: WifiNetworkModel, protocol: String, port: String) {}
    func updateNetworkPreferredProtocolStatus(network: WifiNetworkModel, status: Bool) {}
    func updateNetworkTrustStatus(network: WifiNetworkModel, trusted: Bool) {}
    func updateNetworkProtocolAndPort(network: WifiNetworkModel, protocol: String, port: String) {}
    func updateNetworkPreferredPort(network: WifiNetworkModel, port: String) {}
    func updateNetworkPreferredProtocolWithStatus(network: WifiNetworkModel, protocol: String, port: String, status: Bool) {}
    func touchNetwork(network: WifiNetworkModel) {}
    func findNetwork(with nameSSID: String) -> WifiNetworkModel? { nil }
}