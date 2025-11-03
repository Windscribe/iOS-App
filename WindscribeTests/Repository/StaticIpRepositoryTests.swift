//
//  StaticIpRepositoryTests.swift
//  WindscribeTests
//
//  Created by Claude Code on 2025-10-16.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class StaticIpRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: StaticIpRepository!
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

        // Register StaticIpRepository
        mockContainer.register(StaticIpRepository.self) { r in
            return StaticIpRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        // Resolve repository from container
        repository = mockContainer.resolve(StaticIpRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockLogger = nil
        repository = nil
        super.tearDown()
    }

    // MARK: Success Tests

    func test_getStaticServers_success_shouldReturnStaticIPs() async throws {
        // Given
        let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList

        // When
        let result = try await repository.getStaticServers()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.staticIP, "192.168.1.100")
        XCTAssertEqual(result.first?.name, "US East")
        XCTAssertTrue(mockAPIManager.getStaticIpListCalled)
    }

    func test_getStaticServers_success_shouldSaveToLocalDatabase() async throws {
        // Given
        let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList
        mockLocalDatabase.saveStaticIPsCalled = false

        // When
        _ = try await repository.getStaticServers()

        // Then
        XCTAssertTrue(mockLocalDatabase.saveStaticIPsCalled, "Should save static IPs to local database")
        XCTAssertNotNil(mockLocalDatabase.staticIPsToReturn)
        XCTAssertEqual(mockLocalDatabase.staticIPsToReturn?.count, 2)
    }

    func test_getStaticServers_success_shouldDeleteOldStaticIPs() async throws {
        // Given
        let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList
        mockLocalDatabase.deleteStaticIpsCalled = false

        // When
        _ = try await repository.getStaticServers()

        // Then
        XCTAssertTrue(mockLocalDatabase.deleteStaticIpsCalled, "Should delete old static IPs before saving new ones")
        XCTAssertNotNil(mockLocalDatabase.lastDeletedStaticIPsIgnoreList)
        XCTAssertEqual(mockLocalDatabase.lastDeletedStaticIPsIgnoreList?.count, 2)
    }

    func test_getStaticServers_singleIP_shouldReturnCorrectly() async throws {
        // Given
        let jsonData = SampleDataStaticIP.singleStaticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList

        // When
        let result = try await repository.getStaticServers()

        // Then
        XCTAssertEqual(result.count, 1)
        XCTAssertEqual(result.first?.staticIP, "192.168.1.100")
        XCTAssertEqual(result.first?.countryCode, "US")
    }

    // MARK: Fallback Tests

    func test_getStaticServers_apiFailure_withCachedData_shouldReturnCachedData() async throws {
        // Given
        let cachedStaticIPs = createMockStaticIPs()
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.staticIPsToReturn = cachedStaticIPs

        // When
        let result = try await repository.getStaticServers()

        // Then
        XCTAssertEqual(result.count, cachedStaticIPs.count)
        XCTAssertEqual(result.first?.staticIP, cachedStaticIPs.first?.staticIP)
    }

    func test_getStaticServers_apiFailure_noCachedData_shouldThrowError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.staticIPsToReturn = nil

        // When/Then
        do {
            _ = try await repository.getStaticServers()
            XCTFail("Should throw error when API fails and no cached data")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    func test_getStaticServers_apiFailure_emptyCachedData_shouldThrowError() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockLocalDatabase.staticIPsToReturn = []

        // When/Then
        do {
            _ = try await repository.getStaticServers()
            XCTFail("Should throw error when API fails and cached data is empty")
        } catch {
            XCTAssertNotNil(error)
        }
    }

    // MARK: Lookup Tests

    func test_getStaticIp_withMatchingId_shouldReturnStaticIP() {
        // Given
        let staticIPs = createMockStaticIPs()
        mockLocalDatabase.staticIPsToReturn = staticIPs
        let targetId = staticIPs.first!.id

        // When
        let result = repository.getStaticIp(id: targetId)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, targetId)
        XCTAssertEqual(result?.staticIP, "192.168.1.100")
    }

    func test_getStaticIp_withNonMatchingId_shouldReturnNil() {
        // Given
        let staticIPs = createMockStaticIPs()
        mockLocalDatabase.staticIPsToReturn = staticIPs
        let nonExistentId = 999

        // When
        let result = repository.getStaticIp(id: nonExistentId)

        // Then
        XCTAssertNil(result)
    }

    func test_getStaticIp_withNoData_shouldReturnNil() {
        // Given
        mockLocalDatabase.staticIPsToReturn = nil

        // When
        let result = repository.getStaticIp(id: 1)

        // Then
        XCTAssertNil(result)
    }

    func test_getStaticIp_withEmptyData_shouldReturnNil() {
        // Given
        mockLocalDatabase.staticIPsToReturn = []

        // When
        let result = repository.getStaticIp(id: 1)

        // Then
        XCTAssertNil(result)
    }

    // MARK: - Integration Tests

    func test_getStaticServers_multipleCalls_shouldWorkCorrectly() async throws {
        // Given
        let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList

        // When - call multiple times
        let result1 = try await repository.getStaticServers()
        let result2 = try await repository.getStaticServers()

        // Then
        XCTAssertEqual(result1.count, result2.count)
        XCTAssertEqual(result1.first?.staticIP, result2.first?.staticIP)
    }

    func test_getStaticServers_apiSuccess_afterPreviousFailure_shouldReturnNewData() async throws {
        // Given - first call fails
        mockAPIManager.shouldThrowError = true
        mockLocalDatabase.staticIPsToReturn = createMockStaticIPs()
        _ = try await repository.getStaticServers()

        // When - second call succeeds
        mockAPIManager.shouldThrowError = false
        let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList

        let result = try await repository.getStaticServers()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.first?.staticIP, "192.168.1.100")
    }

    func test_fullFlow_getStaticServers_thenLookup() async throws {
        // Given
        let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList

        // When - fetch static IPs
        let fetchedIPs = try await repository.getStaticServers()
        let firstId = fetchedIPs.first!.id

        // Then - lookup should work
        let lookedUpIP = repository.getStaticIp(id: firstId)
        XCTAssertNotNil(lookedUpIP)
        XCTAssertEqual(lookedUpIP?.id, firstId)
    }

    // MARK: Edge Cases

    func test_getStaticServers_emptyStaticIPList_shouldReturnEmptyArray() async throws {
        // Given
        let jsonData = SampleDataStaticIP.emptyStaticIPListJSON.data(using: .utf8)!
        let emptyStaticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = emptyStaticIPList

        // When
        let result = try await repository.getStaticServers()

        // Then
        XCTAssertEqual(result.count, 0)
    }

    func test_getStaticServers_verifyStaticIPProperties() async throws {
        // Given
        let jsonData = SampleDataStaticIP.singleStaticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        mockAPIManager.staticIPListToReturn = staticIPList

        // When
        let result = try await repository.getStaticServers()

        // Then
        let staticIP = result.first!
        XCTAssertEqual(staticIP.id, 1)
        XCTAssertEqual(staticIP.staticIP, "192.168.1.100")
        XCTAssertEqual(staticIP.name, "US East")
        XCTAssertEqual(staticIP.countryCode, "US")
        XCTAssertEqual(staticIP.cityName, "New York")
        XCTAssertEqual(staticIP.deviceName, "My Device")
        XCTAssertEqual(staticIP.connectIP, "us-east.windscribe.com")
        XCTAssertTrue(staticIP.isActive)
    }

    func test_getStaticServers_withDifferentErrors_shouldHandleCorrectly() async {
        // Given
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.notDefined
        mockLocalDatabase.staticIPsToReturn = nil

        // When/Then
        do {
            _ = try await repository.getStaticServers()
            XCTFail("Should throw error")
        } catch let error as Errors {
            XCTAssertEqual(error, Errors.notDefined)
        } catch {
            XCTFail("Should throw Errors.notDefined")
        }
    }

    // MARK: - Helper Methods

    private func createMockStaticIPs() -> [StaticIP] {
        let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
        let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
        return Array(staticIPList.staticIPs)
    }
}
