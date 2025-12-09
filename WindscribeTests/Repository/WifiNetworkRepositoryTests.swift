//
//  WifiNetworkRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-12-09.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class WifiNetworkRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var mockPreferences: MockPreferences!
    var mockLocalDatabase: MockLocalDatabase!
    var mockConnectivityManager: MockConnectivityManager!
    var mockLogger: MockLogger!
    var repository: WifiNetworkRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockPreferences = MockPreferences()
        mockLocalDatabase = MockLocalDatabase()
        mockConnectivityManager = MockConnectivityManager()
        mockLogger = MockLogger()

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(ConnectivityManager.self) { _ in
            return self.mockConnectivityManager
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(WifiNetworkRepository.self) { r in
            return WifiNetworkRepositoryImpl(
                preferences: r.resolve(Preferences.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                connectivity: r.resolve(ConnectivityManager.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(WifiNetworkRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockContainer = nil
        repository = nil
        mockPreferences = nil
        mockLocalDatabase = nil
        mockConnectivityManager = nil
        mockLogger = nil
        super.tearDown()
    }

    func testGetCurrentNetwork_returnsNetworkWhenSSIDMatches() {
        let testSSID = "TestWiFi"
        mockConnectivityManager.mockNetwork = AppNetwork(.connected, networkType: .wifi, name: testSSID)

        let network = WifiNetworkModel(
            SSID: testSSID,
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        let expectation = XCTestExpectation(description: "Networks loaded")
        mockLocalDatabase.mockWifiNetworks = [WifiNetwork(from: network)]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = self.repository.getCurrentNetwork()
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.SSID, testSSID)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetCurrentNetwork_returnsNilWhenNoMatch() {
        mockConnectivityManager.mockNetwork = AppNetwork(.connected, networkType: .wifi, name: "DifferentWiFi")

        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        let expectation = XCTestExpectation(description: "Networks loaded")
        mockLocalDatabase.mockWifiNetworks = [WifiNetwork(from: network)]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = self.repository.getCurrentNetwork()
            XCTAssertNil(result)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testGetOtherNetworks_excludesCurrentNetwork() {
        let currentSSID = "CurrentWiFi"
        let otherSSID = "OtherWiFi"

        mockConnectivityManager.mockNetwork = AppNetwork(.connected, networkType: .wifi, name: currentSSID)

        let network1 = WifiNetworkModel(
            SSID: currentSSID,
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        let network2 = WifiNetworkModel(
            SSID: otherSSID,
            status: false,
            protocolType: TextsAsset.openVPN,
            port: "80",
            preferredProtocol: TextsAsset.openVPN,
            preferredPort: "80"
        )

        let expectation = XCTestExpectation(description: "Networks loaded")
        mockLocalDatabase.mockWifiNetworks = [WifiNetwork(from: network1), WifiNetwork(from: network2)]

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let result = self.repository.getOtherNetworks()
            XCTAssertNotNil(result)
            XCTAssertEqual(result?.count, 1)
            XCTAssertEqual(result?.first?.SSID, otherSSID)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }

    func testUpdateNetworkPreferredProtocol() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        repository.updateNetworkPreferredProtocol(network: network, protocol: TextsAsset.openVPN, port: "80")

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredProtocol, TextsAsset.openVPN)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredPort, "80")
    }

    func testUpdateNetworkPreferredProtocolStatus() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443",
            preferredProtocolStatus: false
        )

        repository.updateNetworkPreferredProtocolStatus(network: network, status: true)

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredProtocolStatus, true)
    }

    func testUpdateNetworkTrustStatus_trusted() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: false,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443",
            preferredProtocolStatus: true
        )

        repository.updateNetworkTrustStatus(network: network, trusted: true)

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.status, false)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredProtocolStatus, false)
    }

    func testUpdateNetworkTrustStatus_untrusted() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        repository.updateNetworkTrustStatus(network: network, trusted: false)

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.status, true)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredProtocolStatus, false)
    }

    func testUpdateNetworkProtocolAndPort() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        repository.updateNetworkProtocolAndPort(network: network, protocol: TextsAsset.openVPN, port: "80")

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.protocolType, TextsAsset.openVPN)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.port, "80")
    }

    func testUpdateNetworkPreferredPort() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        repository.updateNetworkPreferredPort(network: network, port: "8080")

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredPort, "8080")
    }

    func testUpdateNetworkPreferredProtocolWithStatus() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443",
            preferredProtocolStatus: false
        )

        repository.updateNetworkPreferredProtocolWithStatus(
            network: network,
            protocol: TextsAsset.openVPN,
            port: "80",
            status: true
        )

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredProtocol, TextsAsset.openVPN)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredPort, "80")
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.preferredProtocolStatus, true)
    }

    func testTouchNetwork() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        repository.touchNetwork(network: network)

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.SSID, "TestWiFi")
    }

    func testSetNetworkDontAskAgainForPreferredProtocol() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        repository.setNetworkDontAskAgainForPreferredProtocol(network: network)

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.dontAskAgainForPreferredProtocol, true)
    }

    func testIncrementNetworkDismissCount() {
        let network = WifiNetworkModel(
            SSID: "TestWiFi",
            status: true,
            protocolType: wireGuard,
            port: "443",
            preferredProtocol: wireGuard,
            preferredPort: "443"
        )

        repository.incrementNetworkDismissCount(network: network)

        XCTAssertTrue(mockLocalDatabase.saveNetworkCalled)
        XCTAssertEqual(mockLocalDatabase.lastSavedNetwork?.popupDismissCount, 1)
    }
}
