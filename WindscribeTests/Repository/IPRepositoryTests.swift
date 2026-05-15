//
//  IPRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2026-02-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class IPRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: IPRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockPreferences: MockPreferences!
    var mockLogger: MockLogger!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockPreferences = MockPreferences()
        mockLogger = MockLogger()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        // Register IPRepository
        mockContainer.register(IPRepository.self) { r in
            return IPRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)
    }

    override func tearDown() {
        cancellables.removeAll()
        mockAPIManager.reset()
        mockLocalDatabase.clean()
        mockContainer = nil
        repository = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockPreferences = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: Initial State Tests

    func testInitialStateWithCachedIP() {
        mockPreferences.mockCurrentIpAddress = "192.168.1.100"

        repository = mockContainer.resolve(IPRepository.self)!

        XCTAssertEqual(repository.ipState.value, .available("192.168.1.100"))
        XCTAssertEqual(repository.currentIp.value, "192.168.1.100")
    }

    func testInitialStateWithoutCachedIP() {
        mockPreferences.mockCurrentIpAddress = nil

        repository = mockContainer.resolve(IPRepository.self)!

        // Then
        XCTAssertEqual(repository.ipState.value, .unavailable)
        XCTAssertNil(repository.currentIp.value)
    }

    func testInitialStateMigratesFromRealm() {
        let realmIP = MyIP()
        realmIP.userIp = "10.0.0.1"
        mockLocalDatabase.mockMyIP = realmIP
        mockPreferences.mockCurrentIpAddress = nil

        repository = mockContainer.resolve(IPRepository.self)!

        XCTAssertEqual(mockPreferences.mockCurrentIpAddress, "10.0.0.1", "Should migrate IP from Realm to Preferences")
    }

    // MARK: GetIP Success Tests

    func testGetIPSuccess() async throws {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = false

        let expectation = expectation(description: "IP state updated")
        var receivedStates: [IPState?] = []
        var hasFulfilled = false

        repository.ipState
            .sink { state in
                receivedStates.append(state)
                if case .available(_)? = state, !hasFulfilled {
                    hasFulfilled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        try await repository.getIp(usePingTest: false)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(repository.currentIp.value, "192.168.1.100")
        XCTAssertEqual(mockPreferences.mockCurrentIpAddress, "192.168.1.100")
        XCTAssertTrue(receivedStates.contains { if case .updating = $0 { return true } else { return false } })
        XCTAssertTrue(receivedStates.contains { if case .available = $0 { return true } else { return false } })
    }

    func testGetIPSuccessWithCachedIP() async throws {
        mockPreferences.mockCurrentIpAddress = "10.0.0.1"
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = false

        var receivedStates: [IPState?] = []
        repository.ipState
            .sink { state in
                receivedStates.append(state)
            }
            .store(in: &cancellables)

        try await repository.getIp(usePingTest: false)

        XCTAssertEqual(repository.currentIp.value, "192.168.1.100")
        XCTAssertEqual(mockPreferences.mockCurrentIpAddress, "192.168.1.100")
        // Should NOT show .updating state when we have cached IP
        XCTAssertFalse(receivedStates.contains { if case .updating = $0 { return true } else { return false } })
    }

    func testGetIPUpdatesCurrentIPSubject() async throws {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = false

        let expectation = expectation(description: "Current IP updated")
        var receivedIP: String?

        repository.currentIp
            .dropFirst() // Skip initial nil
            .prefix(1) // Only take first emission after dropFirst
            .sink { ip in
                receivedIP = ip
                expectation.fulfill()
            }
            .store(in: &cancellables)

        try await repository.getIp(usePingTest: false)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(receivedIP, "192.168.1.100")
    }

    // MARK: GetIP Error Tests

    func testGetIPErrorWithCachedIP() async {
        mockPreferences.mockCurrentIpAddress = "10.0.0.1"
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.notDefined

        let initialState = repository.ipState.value

        do {
            try await repository.getIp(usePingTest: false)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? Errors, Errors.notDefined)
        }

        // Should revert to last state (available with cached IP)
        // Wait for main actor to process state update
        await MainActor.run {
            XCTAssertEqual(repository.ipState.value, initialState)
            XCTAssertEqual(repository.currentIp.value, "10.0.0.1")
        }
    }

    func testGetIPErrorWithoutCachedIP() async {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.notDefined

        do {
            try await repository.getIp(usePingTest: false)
            XCTFail("Should throw error")
        } catch {
            XCTAssertEqual(error as? Errors, Errors.notDefined)
        }

        // Should revert to unavailable state
        // Wait for main actor to process state update
        await MainActor.run {
            XCTAssertEqual(repository.ipState.value, .unavailable)
            XCTAssertNil(repository.currentIp.value)
        }
    }

    // MARK: Observable Tests

    func testIPStateObservable() {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!

        let expectation = expectation(description: "IP state emits")
        var receivedStates: [IPState?] = []

        repository.ipState
            .prefix(2) // Initial + updated
            .collect()
            .sink { states in
                receivedStates = states
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockPreferences.saveCurrentIpAddress(ip: "192.168.1.100")

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedStates.count, 2)
        XCTAssertEqual(receivedStates[0], .unavailable)
        XCTAssertEqual(receivedStates[1], .available("192.168.1.100"))
    }

    func testCurrentIPObservable() {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!

        let expectation = expectation(description: "Current IP emits")
        var receivedIPs: [String?] = []

        repository.currentIp
            .prefix(2) // Initial + updated
            .collect()
            .sink { ips in
                receivedIPs = ips
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockPreferences.saveCurrentIpAddress(ip: "192.168.1.100")

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(receivedIPs.count, 2)
        XCTAssertNil(receivedIPs[0])
        XCTAssertEqual(receivedIPs[1], "192.168.1.100")
    }

    func testPreferencesChangeTriggersUpdate() {
        mockPreferences.mockCurrentIpAddress = "10.0.0.1"
        repository = mockContainer.resolve(IPRepository.self)!

        let expectation = expectation(description: "State updates on preference change")
        var finalState: IPState?

        repository.ipState
            .dropFirst() // Skip initial
            .prefix(1) // Only take first emission after dropFirst
            .sink { state in
                finalState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockPreferences.saveCurrentIpAddress(ip: "192.168.2.200")

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(finalState, .available("192.168.2.200"))
        XCTAssertEqual(repository.currentIp.value, "192.168.2.200")
    }

    // MARK: State Transition Tests

    func testStateTransitionFromUnavailableToAvailable() async throws {
        // Given
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!

        XCTAssertEqual(repository.ipState.value, .unavailable)

        // When
        try await repository.getIp(usePingTest: false)

        // Then
        // Wait for main actor to process state update
        await MainActor.run {
            XCTAssertEqual(repository.ipState.value, .available("192.168.1.100"))
        }
    }

    func testStateTransitionUpdatingToAvailable() async throws {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!

        let expectation = expectation(description: "State transitions through updating")
        var states: [IPState?] = []
        var hasFulfilled = false

        repository.ipState
            .sink { state in
                states.append(state)
                if case .available(_)? = state, !hasFulfilled {
                    hasFulfilled = true
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        try await repository.getIp(usePingTest: false)

        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(states.contains { if case .unavailable = $0 { return true } else { return false } })
        XCTAssertTrue(states.contains { if case .updating = $0 { return true } else { return false } })
        XCTAssertTrue(states.contains { if case .available = $0 { return true } else { return false } })
    }

    // MARK: Edge Cases

    func testMultipleGetIPCalls() async throws {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!

        try await repository.getIp(usePingTest: false)
        let firstIP = repository.currentIp.value
        try await repository.getIp(usePingTest: false)
        let secondIP = repository.currentIp.value

        XCTAssertEqual(firstIP, "192.168.1.100")
        XCTAssertEqual(secondIP, "192.168.1.100")
        // Wait for main actor to process state update
        await MainActor.run {
            XCTAssertEqual(repository.ipState.value, .available("192.168.1.100"))
        }
    }

    func testIPStateNilHandling() {
        mockPreferences.mockCurrentIpAddress = "10.0.0.1"
        repository = mockContainer.resolve(IPRepository.self)!

        let expectation = expectation(description: "State updates to unavailable")
        var finalState: IPState?

        repository.ipState
            .dropFirst() // Skip initial available state
            .prefix(1) // Only take first emission after dropFirst
            .sink { state in
                finalState = state
                expectation.fulfill()
            }
            .store(in: &cancellables)

        mockPreferences.saveCurrentIpAddress(ip: nil)

        waitForExpectations(timeout: 1.0)
        XCTAssertEqual(finalState, .unavailable)
    }

    // MARK: usePingTest Parameter Tests

    func testGetIPUsesMyIPEndpointByDefault() async throws {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = false

        try await repository.getIp(usePingTest: false)

        XCTAssertTrue(mockAPIManager.getIpCalled, "getIp should be called")
        XCTAssertEqual(mockAPIManager.getIpUsedPingTest, false, "Should use /myip endpoint by default")
    }

    func testGetIPUsesPingTestEndpointWhenRequested() async throws {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = false

        try await repository.getIp(usePingTest: true)

        XCTAssertTrue(mockAPIManager.getIpCalled, "getIp should be called")
        XCTAssertEqual(mockAPIManager.getIpUsedPingTest, true, "Should use pingTest endpoint when requested")
    }

    func testGetIPWithPingTestDoesNotStoresResultInPreferences() async throws {
        mockPreferences.mockCurrentIpAddress = nil
        repository = mockContainer.resolve(IPRepository.self)!
        mockAPIManager.shouldThrowError = false
        mockAPIManager.mockIpAddress = "10.20.30.40"

        try await repository.getIp(usePingTest: true)

        XCTAssertNil(repository.currentIp.value)
        XCTAssertNil(mockPreferences.mockCurrentIpAddress)
        await MainActor.run {
            XCTAssertEqual(repository.ipState.value, .unavailable)
        }
    }
}
