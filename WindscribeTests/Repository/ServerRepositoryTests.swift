//
//  ServerRepositoryTests.swift
//  Windscribe
//
//  Created by Andre Fonseca on 10/10/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class ServerRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: ServerRepository!
    var mockAPIManager: MockAPIManager!
    var mockLocalDatabase: MockLocalDatabase!
    var mockUserSessionRepository: MockUserSessionRepository!
    var mockLogger: MockLogger!
    var mockPreferences: MockPreferences!
    var mockAdvanceRepository: MockAdvanceRepository!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockLocalDatabase = MockLocalDatabase()
        mockUserSessionRepository = MockUserSessionRepository()
        mockPreferences = MockPreferences()
        mockLogger = MockLogger()
        mockAdvanceRepository = MockAdvanceRepository()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }.inObjectScope(.container)

        mockContainer.register(UserSessionRepository.self) { _ in
            return self.mockUserSessionRepository
        }.inObjectScope(.container)

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }.inObjectScope(.container)

        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }.inObjectScope(.container)

        mockContainer.register(AdvanceRepository.self) { _ in
            return self.mockAdvanceRepository
        }.inObjectScope(.container)

        // Register ServerRepository
        mockContainer.register(ServerRepository.self) { r in
            return ServerRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                preferences: r.resolve(Preferences.self)!,
                advanceRepository: r.resolve(AdvanceRepository.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(ServerRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockAPIManager.reset()
        mockAdvanceRepository.reset()
        mockLocalDatabase.clean()
        mockContainer = nil
        repository = nil
        mockAPIManager = nil
        mockLocalDatabase = nil
        mockUserSessionRepository = nil
        mockPreferences = nil
        mockLogger = nil
        mockAdvanceRepository = nil
        super.tearDown()
    }

    // MARK: - Test Cases
    func testGetUpdatedServersSuccess() async throws {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        guard let mockServerList = createMockServerList() else {
            XCTFail("ServerList was nil, should be something")
            return
        }

        mockAPIManager.mockServerList = mockServerList

        let expectedServers = Array(mockServerList.servers)

        // When
        try await repository.updatedServers()

        let savedServers = mockLocalDatabase.getServers()
        let currentServerModels = repository.currentServerModels
        let savedServersModels = savedServers?.map { $0.getServerModel() } ?? []

        // Then
        XCTAssertEqual(currentServerModels.count, expectedServers.count)
        XCTAssertEqual(savedServersModels, currentServerModels)
    }

    func testGetUpdatedServersWithoutUser() async {
        // Given
        mockUserSessionRepository.clearSession()

        // When/Then
        do {
             try await repository.updatedServers()
            XCTFail("Should have thrown validation failure error")
        } catch {
            XCTAssertEqual(error as? Errors, Errors.validationFailure)
        }
    }

    func testGetUpdatedServersAPIErrorFallbackToLocal() async throws {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        // API will fail
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.datanotfound

        guard let mockServerList = createMockServerList() else {
            XCTFail("ServerList was nil, should be something")
            return
        }

        // But local database has data
        let localServers = Array(mockServerList.servers)
        mockLocalDatabase.mockServers = localServers

        // When
        try await repository.updatedServers()
        // Then
        let currentServerModels = repository.currentServerModels
        let localServersModels = localServers.map { $0.getServerModel() }
        XCTAssertEqual(currentServerModels.count, localServers.count)
        XCTAssertEqual(currentServerModels, localServersModels)
    }

    func testGetUpdatedServersAPIErrorNoLocalData() async {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        // API will fail and no local data
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.datanotfound
        mockLocalDatabase.mockServers = nil

        // When/Then
        do {
            try await repository.updatedServers()
            XCTFail("Should have thrown network error")
        } catch {
            XCTAssertEqual(error as? Errors, Errors.datanotfound)
        }
    }

    func testserverListSubject() async throws {
        // Given
        let sessionModel = createMockSessionModel()
        mockUserSessionRepository.sessionModel = sessionModel

        guard let mockServerList = createMockServerList() else {
            XCTFail("ServerList was nil, should be something")
            return
        }

        mockAPIManager.mockServerList = mockServerList

        let mockServers = Array(mockServerList.servers).map {
            $0.getServerModel()
        }

        var receivedServers: [ServerModel] = []
        try await repository.updatedServers()

        receivedServers = await withCheckedContinuation { continuation in
            repository.serverListSubject
                .sink(receiveValue: { servers in
                    if !servers.isEmpty {
                        continuation.resume(returning: servers)
                    }
                })
                .store(in: &cancellables)
        }

        // Then
        XCTAssertEqual(receivedServers.count, mockServers.count)
        XCTAssertEqual(receivedServers.first?.name, mockServers.first?.name)
    }

    func testUpdateRegionsWithCustomLocations() {
        // Given
        let mockRegions = createMockExportedRegions()
        guard let mockServerList = createMockServerList() else {
            XCTFail("ServerList was nil, should be something")
            return
        }

        let mockServers = Array(mockServerList.servers)
        mockLocalDatabase.mockServers = mockServers

        let expectation = expectation(description: "Server models updated with custom regions")

        // Set up the subscription before calling updateRegions to avoid race conditions
        repository.serverListSubject
            .dropFirst() // Skip initial empty value
            .first() // Only take the first emission to prevent multiple fulfillments
            .sink { servers in
                if !servers.isEmpty {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)

        // When
        repository.updateRegions(with: mockRegions)

        // Then
        wait(for: [expectation], timeout: 2.0)

        let region = mockRegions.first
        let server = repository.currentServerModels.first { region?.id == $0.id }
        let city = region?.cities.first
        let group = server?.groups.first { city?.id == $0.id }
        XCTAssertEqual(server?.name, region?.country)
        XCTAssertEqual(group?.city, city?.name)
        XCTAssertEqual(group?.nick, city?.nickname)
    }
}

// MARK: - Helper Methods
extension ServerRepositoryTests {

    private func createMockSessionModel() -> SessionModel {
        let session = Session()
        session.userId = "test-user-id"
        session.username = "testuser"
        session.sessionAuthHash = "test-auth-hash"
        return SessionModel(session: session)
    }

    private func createMockServerList() -> ServerList? {
        guard let url = Bundle(for: type(of: self)).url(forResource: "ServerList", withExtension: "json") else {
            return nil
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            return try decoder.decode(ServerList.self, from: data)
        } catch _ {
            return nil
        }
    }

    private func createMockExportedRegions() -> [ExportedRegion] {
        let city1 = ExportedCity(id: 414, name: "Custom Dallas", nickname: "Trinity")
        let city2 = ExportedCity(id: 156, name: "Custom Atlanta", nickname: "Peachtree")

        let region = ExportedRegion(id: 65, country: "Custom US Central", cities: [city1, city2])

        return [region]
    }
}
