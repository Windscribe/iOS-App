//
//  VPNStateRepositoryTests.swift
//  Windscribe
//
//  Created by Andre Fonseca on 11/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import NetworkExtension
@testable import Windscribe
import XCTest

class VPNStateRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var mockLogger: MockLogger!

    var repository: VPNStateRepository!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockLogger = MockLogger()

        // Register mocks

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        // Register PortMapRepository
        mockContainer.register(VPNStateRepository.self) { r in
            return VPNStateRepositoryImpl(
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        // Resolve repository from container
        repository = mockContainer.resolve(VPNStateRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        mockLogger = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - State change Tests

    func test_isConnected() async throws {
        // Given
        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Then
        XCTAssertTrue(repository.isConnected())
    }

    func test_isConnecting() async throws {
        // Given
        repository.vpnInfo.send(getVPNInfo(with: .connecting))

        // Then
        XCTAssertTrue(repository.isConnecting())
    }

    func test_isDisconnected() async throws {
        // Given
        repository.vpnInfo.send(getVPNInfo(with: .disconnected))

        // Then
        XCTAssertTrue(repository.isDisconnected())
    }

    func test_setting_values() async throws {
        // Given
        repository.setUntrustedOneTimeOnlySSID("UntrustedOneTimeOnlySSID")
        repository.setIsFromProtocolFailover(true)
        repository.setIsFromProtocolChange(true)
        repository.setLastConnectionStatus(.connecting)
        repository.setConfigurationState(.configuring)

        // Then
        XCTAssertEqual(repository.untrustedOneTimeOnlySSID, "UntrustedOneTimeOnlySSID")
        XCTAssertEqual(repository.isFromProtocolFailover, true)
        XCTAssertEqual(repository.isFromProtocolChange, true)
        XCTAssertEqual(repository.lastConnectionStatus, .connecting)
        XCTAssertEqual(repository.configurationState, .configuring)
    }

    // MARK: - Configuration State Tests

    func test_configurationState_initial() async throws {
        // Then
        XCTAssertEqual(repository.configurationState, .initial)
    }

    func test_configurationState_triggers_update() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Configuration state trigger fires")

        let cancellable = repository.configurationStateUpdatedTrigger.sink { _ in
            expectation.fulfill()
        }

        // When
        repository.setConfigurationState(.configuring)

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(repository.configurationState, .configuring)

        cancellable.cancel()
    }

    func test_configurationState_multiple_changes() async throws {
        // Given
        var triggerCount = 0
        let cancellable = repository.configurationStateUpdatedTrigger.sink { _ in
            triggerCount += 1
        }

        // When
        repository.setConfigurationState(.configuring)
        repository.setConfigurationState(.disabling)
        repository.setConfigurationState(.initial)
        repository.setConfigurationState(.testing)

        // Then
        XCTAssertEqual(triggerCount, 4)
        XCTAssertEqual(repository.configurationState, .testing)

        cancellable.cancel()
    }

    // MARK: - getStatus() Publisher Tests

    func test_getStatus_with_initial_configuration_state() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status publisher emits connected")
        repository.setConfigurationState(.initial)

        var receivedStatus: NEVPNStatus?
        let cancellable = repository.getStatus().sink { status in
            receivedStatus = status
            expectation.fulfill()
        }

        // When
        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedStatus, .connected)

        cancellable.cancel()
    }

    func test_getStatus_with_configuring_state() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status publisher emits connecting when configuring")
        repository.setConfigurationState(.configuring)

        var receivedStatus: NEVPNStatus?
        let cancellable = repository.getStatus().sink { status in
            receivedStatus = status
            expectation.fulfill()
        }

        // When
        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedStatus, .connecting)

        cancellable.cancel()
    }

    func test_getStatus_with_disabling_state() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status publisher emits disconnecting when disabling")
        repository.setConfigurationState(.disabling)

        var receivedStatus: NEVPNStatus?
        let cancellable = repository.getStatus().sink { status in
            receivedStatus = status
            expectation.fulfill()
        }

        // When
        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedStatus, .disconnecting)

        cancellable.cancel()
    }

    func test_getStatus_with_testing_state() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status publisher emits actual status when testing")
        repository.setConfigurationState(.testing)

        var receivedStatus: NEVPNStatus?
        let cancellable = repository.getStatus().sink { status in
            receivedStatus = status
            expectation.fulfill()
        }

        // When
        repository.vpnInfo.send(getVPNInfo(with: .disconnected))

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedStatus, .disconnected)

        cancellable.cancel()
    }

    func test_getStatus_removes_duplicates() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status publisher only emits unique values")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        repository.setConfigurationState(.initial)

        var emissionCount = 0
        let cancellable = repository.getStatus().sink { status in
            emissionCount += 1
            expectation.fulfill()
        }

        // When - Send the same status multiple times
        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Wait for debounce
        try await Task.sleep(nanoseconds: 500_000_000) // 500ms

        repository.vpnInfo.send(getVPNInfo(with: .connected))
        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Then - Should only receive one emission
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(emissionCount, 1)

        cancellable.cancel()
    }

    func test_getStatus_emits_different_statuses() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status publisher emits different statuses")
        expectation.expectedFulfillmentCount = 3

        repository.setConfigurationState(.initial)

        var receivedStatuses: [NEVPNStatus] = []
        let cancellable = repository.getStatus().sink { status in
            receivedStatuses.append(status)
            expectation.fulfill()
        }

        // When
        repository.vpnInfo.send(getVPNInfo(with: .disconnected))
        try await Task.sleep(nanoseconds: 500_000_000)

        repository.vpnInfo.send(getVPNInfo(with: .connecting))
        try await Task.sleep(nanoseconds: 500_000_000)

        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(receivedStatuses, [.disconnected, .connecting, .connected])

        cancellable.cancel()
    }

    func test_getStatus_debounces_rapid_updates() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Status publisher debounces rapid updates")
        expectation.expectedFulfillmentCount = 1
        expectation.assertForOverFulfill = true

        repository.setConfigurationState(.initial)

        var emissionCount = 0
        var lastStatus: NEVPNStatus?
        let cancellable = repository.getStatus().sink { status in
            emissionCount += 1
            lastStatus = status
            expectation.fulfill()
        }

        // When - Send multiple updates rapidly (within debounce window)
        repository.vpnInfo.send(getVPNInfo(with: .disconnected))
        repository.vpnInfo.send(getVPNInfo(with: .connecting))
        repository.vpnInfo.send(getVPNInfo(with: .connected))

        // Then - Should only receive the last emission after debounce
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertEqual(emissionCount, 1)
        XCTAssertEqual(lastStatus, .connected)

        cancellable.cancel()
    }

    // MARK: - Connection State Trigger Tests

    func test_connectionStateUpdatedTrigger() async throws {
        // Given
        let expectation = XCTestExpectation(description: "Connection state trigger can be sent")

        let cancellable = repository.connectionStateUpdatedTrigger.sink { _ in
            expectation.fulfill()
        }

        // When
        repository.connectionStateUpdatedTrigger.send()

        // Then
        await fulfillment(of: [expectation], timeout: 5.0)

        cancellable.cancel()
    }

    // MARK: - Thread Safety Tests

    func test_configurationState_thread_safety() async throws {
        // Given
        let iterations = 100
        let expectation = XCTestExpectation(description: "All operations complete")
        expectation.expectedFulfillmentCount = iterations * 2

        let states: [ConfigurationState] = [.initial, .configuring, .disabling, .testing]

        // When - Access configuration state from multiple threads
        DispatchQueue.concurrentPerform(iterations: iterations) { index in
            DispatchQueue.global().async {
                let state = states[index % states.count]
                self.repository.setConfigurationState(state)
                expectation.fulfill()
            }

            DispatchQueue.global().async {
                let _ = self.repository.configurationState
                expectation.fulfill()
            }
        }

        // Then - Should not crash and complete all operations
        await fulfillment(of: [expectation], timeout: 5.0)
        XCTAssertTrue(states.contains(repository.configurationState))
    }

    // MARK: - VPNInfo Updates Tests

    func test_vpnInfo_can_be_updated() async throws {
        // Given
        let info1 = getVPNInfo(with: .disconnected)
        let info2 = getVPNInfo(with: .connected)

        // When
        repository.vpnInfo.send(info1)
        XCTAssertEqual(repository.vpnInfo.value?.status, .disconnected)

        repository.vpnInfo.send(info2)
        XCTAssertEqual(repository.vpnInfo.value?.status, .connected)
    }

    func test_vpnInfo_nil_handling() async throws {
        // Given
        repository.vpnInfo.send(nil)

        // Then
        XCTAssertFalse(repository.isConnected())
        XCTAssertFalse(repository.isConnecting())
        XCTAssertFalse(repository.isDisconnected())
    }

    // MARK: - Edge Cases Tests

    func test_default_values() async throws {
        // Then
        XCTAssertEqual(repository.configurationState, .initial)
        XCTAssertEqual(repository.lastConnectionStatus, .disconnected)
        XCTAssertFalse(repository.isFromProtocolFailover)
        XCTAssertFalse(repository.isFromProtocolChange)
        XCTAssertEqual(repository.untrustedOneTimeOnlySSID, "")
        XCTAssertNil(repository.vpnInfo.value)
    }

    func test_lastConnectionStatus_persistence() async throws {
        // Given
        repository.setLastConnectionStatus(.connecting)
        XCTAssertEqual(repository.lastConnectionStatus, .connecting)

        // When
        repository.setLastConnectionStatus(.connected)

        // Then
        XCTAssertEqual(repository.lastConnectionStatus, .connected)
    }

    // MARK: - Help Functions
    func getVPNInfo(with status: NEVPNStatus) -> VPNConnectionInfo{
        return VPNConnectionInfo(selectedProtocol: "Wireguard",
                                 selectedPort: "443",
                                 status: status,
                                 killSwitch: false,
                                 onDemand: false)
    }
}
