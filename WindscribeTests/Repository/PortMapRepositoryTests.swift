//
//  PortMapRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-10.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class PortMapRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: PortMapRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockLogger: MockLogger!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockLogger = MockLogger()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        // Register PortMapRepository
        mockContainer.register(PortMapRepository.self) { r in
            return PortMapRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        // Resolve repository from container
        repository = mockContainer.resolve(PortMapRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockLogger = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Success Tests

    func test_getUpdatedPortMap_success_shouldReturnPortMaps() async throws {
        // Given
        let expectedPortMaps = createMockPortMaps()
        let portMapList = createMockPortMapList(portMaps: expectedPortMaps, suggested: nil)
        mockAPIManager.portMapListToReturn = portMapList

        // When
        let result = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertEqual(result.count, expectedPortMaps.count)
        XCTAssertEqual(result.first?.connectionProtocol, "tcp")
        XCTAssertEqual(result.first?.heading, "TCP")
    }

    func test_getUpdatedPortMap_success_shouldSaveToLocalDatabase() async throws {
        // Given
        let expectedPortMaps = createMockPortMaps()
        let portMapList = createMockPortMapList(portMaps: expectedPortMaps, suggested: nil)
        mockAPIManager.portMapListToReturn = portMapList
        mockLocalDatabase.savePortMapCalled = false

        // When
        _ = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertTrue(mockLocalDatabase.savePortMapCalled, "Should save port maps to local database")
    }

    func test_getUpdatedPortMap_withSuggestedPorts_shouldSaveSuggestedPorts() async throws {
        // Given
        let expectedPortMaps = createMockPortMaps()
        let suggestedPorts = createMockSuggestedPorts()
        let portMapList = createMockPortMapList(portMaps: expectedPortMaps, suggested: suggestedPorts)
        mockAPIManager.portMapListToReturn = portMapList
        mockLocalDatabase.saveSuggestedPortsCalled = false

        // When
        _ = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertTrue(mockLocalDatabase.saveSuggestedPortsCalled, "Should save suggested ports when present")
    }

    func test_getUpdatedPortMap_withoutSuggestedPorts_shouldNotSaveSuggestedPorts() async throws {
        // Given
        let expectedPortMaps = createMockPortMaps()
        let portMapList = createMockPortMapList(portMaps: expectedPortMaps, suggested: nil)
        mockAPIManager.portMapListToReturn = portMapList
        mockLocalDatabase.saveSuggestedPortsCalled = false

        // When
        _ = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertFalse(mockLocalDatabase.saveSuggestedPortsCalled, "Should not save suggested ports when nil")
    }

    // MARK: - Fallback Tests

    func test_getUpdatedPortMap_apiFailure_withCachedData_shouldReturnCachedData() async throws {
        // Given
        let cachedPortMaps = createMockPortMaps()
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.portMapsToReturn = cachedPortMaps

        // When
        let result = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertEqual(result.count, cachedPortMaps.count)
        XCTAssertEqual(result.first?.connectionProtocol, "tcp")
    }

    func test_getUpdatedPortMap_apiFailure_noCachedData_shouldThrowError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.portMapsToReturn = nil

        // When/Then
        do {
            _ = try await repository.getUpdatedPortMap()
            XCTFail("Should throw error when API fails and no cached data")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_getUpdatedPortMap_apiFailure_emptyCachedData_shouldThrowError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.portMapsToReturn = []

        // When/Then
        do {
            _ = try await repository.getUpdatedPortMap()
            XCTFail("Should throw error when API fails and cached data is empty")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: - Integration Tests

    func test_getUpdatedPortMap_multipleCalls_shouldWorkCorrectly() async throws {
        // Given
        let portMaps = createMockPortMaps()
        let portMapList = createMockPortMapList(portMaps: portMaps, suggested: nil)
        mockAPIManager.portMapListToReturn = portMapList

        // When - call multiple times
        let result1 = try await repository.getUpdatedPortMap()
        let result2 = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertEqual(result1.count, result2.count)
    }

    func test_getUpdatedPortMap_withDifferentPortMaps_shouldReturnCorrectData() async throws {
        // Given
        let jsonData = SampleDataPorts.singleUDPPortMapListJSON.data(using: .utf8)!
        let portMapList = try! JSONDecoder().decode(PortMapList.self, from: jsonData)
        mockAPIManager.portMapListToReturn = portMapList

        // When
        let result = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.connectionProtocol, "udp")
        XCTAssertEqual(result.first?.heading, "UDP")
    }

    // MARK: - Edge Cases

    func test_getUpdatedPortMap_emptyPortMapList_shouldReturnEmptyArray() async throws {
        // Given
        let jsonData = SampleDataPorts.emptyPortMapListJSON.data(using: .utf8)!
        let emptyPortMapList = try! JSONDecoder().decode(PortMapList.self, from: jsonData)
        mockAPIManager.portMapListToReturn = emptyPortMapList

        // When
        let result = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertEqual(result.count, 0)
    }

    func test_getUpdatedPortMap_apiSuccess_afterPreviousFailure_shouldReturnNewData() async throws {
        // Given - first call fails
        mockAPIManager.shouldThrowError = true
        mockLocalDatabase.portMapsToReturn = createMockPortMaps()
        _ = try await repository.getUpdatedPortMap()

        // When - second call succeeds
        mockAPIManager.shouldThrowError = false
        let newPortMaps = createMockPortMaps()
        let portMapList = createMockPortMapList(portMaps: newPortMaps, suggested: nil)
        mockAPIManager.portMapListToReturn = portMapList

        let result = try await repository.getUpdatedPortMap()

        // Then
        XCTAssertEqual(result.count, newPortMaps.count)
    }

    // MARK: - Helper Methods

    private func createMockPortMaps() -> [PortMap] {
        let jsonData = SampleDataPorts.portMapsJSON.data(using: .utf8)!
        let portMaps = try! JSONDecoder().decode([PortMap].self, from: jsonData)
        return portMaps
    }

    private func createMockPortMapList(portMaps: [PortMap], suggested: SuggestedPorts?) -> PortMapList {
        // Build JSON structure matching PortMapList's expected format
        var portMapsJson: [[String: Any]] = []
        for portMap in portMaps {
            portMapsJson.append([
                "protocol": portMap.connectionProtocol,
                "heading": portMap.heading,
                "use": portMap.use,
                "ports": Array(portMap.ports),
                "legacy_ports": Array(portMap.legacyPorts)
            ])
        }

        var dataDict: [String: Any] = ["portmap": portMapsJson]

        if let suggested = suggested {
            dataDict["suggested"] = [
                "protocol": suggested.protocolType,
                "port": Int(suggested.port) ?? 443
            ]
        }

        let json: [String: Any] = ["data": dataDict]
        let jsonData = try! JSONSerialization.data(withJSONObject: json)
        let portMapList = try! JSONDecoder().decode(PortMapList.self, from: jsonData)

        return portMapList
    }

    private func createMockSuggestedPorts() -> SuggestedPorts {
        let jsonData = SampleDataPorts.suggestedPortsJSON.data(using: .utf8)!
        let suggested = try! JSONDecoder().decode(SuggestedPorts.self, from: jsonData)
        return suggested
    }
}
