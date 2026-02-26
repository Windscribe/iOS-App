//
//  UserDataRepositoryTests.swift
//  Windscribe
//
//  Created by Andre Fonseca on 19/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//


import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class UserDataRepositoryTests: XCTestCase {
    var mockContainer: Container!
    var mockServerRepository: MockServerRepository!
    var mockCredentialsRepository: MockCredentialsRepository!
    var mockPortMapRepository: MockPortMapRepository!
    var mockLatencyRepository: MockLatencyRepository!
    var mockStaticIpRepository: MockStaticIpRepository!
    var mockNotificationsRepository: MockNotificationRepository!
    var mockEmergencyRepository: MockEmergencyRepository!
    var mockLogger: MockLogger!
    var repository: UserDataRepository!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockServerRepository = MockServerRepository()
        mockCredentialsRepository = MockCredentialsRepository()
        mockPortMapRepository = MockPortMapRepository()
        mockLatencyRepository = MockLatencyRepository()
        mockStaticIpRepository = MockStaticIpRepository()
        mockNotificationsRepository = MockNotificationRepository()
        mockEmergencyRepository = MockEmergencyRepository()
        mockLogger = MockLogger()

        // Register mock ServerRepository
        mockContainer.register(ServerRepository.self) { _ in
            return self.mockServerRepository
        }

        // Register mock CredentialsRepository
        mockContainer.register(CredentialsRepository.self) { _ in
            return self.mockCredentialsRepository
        }
        // Register mock PortMapRepository
        mockContainer.register(PortMapRepository.self) { _ in
            return self.mockPortMapRepository
        }

        // Register mock LatencyRepository
        mockContainer.register(LatencyRepository.self) { _ in
            return self.mockLatencyRepository
        }
        // Register mock StaticIpRepository
        mockContainer.register(StaticIpRepository.self) { _ in
            return self.mockStaticIpRepository
        }

        // Register mock NotificationsRepository
        mockContainer.register(NotificationRepository.self) { _ in
            return self.mockNotificationsRepository
        }

        // Register mock EmergencyRepository
        mockContainer.register(EmergencyRepository.self) { _ in
            return self.mockEmergencyRepository
        }

        // Register mock Logger
        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }

        // Register UserDataRepository for unit tests
        mockContainer.register(UserDataRepository.self) { _ in
            return UserDataRepositoryImpl(serverRepository: self.mockServerRepository,
                                          credentialsRepository: self.mockCredentialsRepository,
                                          portMapRepository: self.mockPortMapRepository,
                                          latencyRepository: self.mockLatencyRepository,
                                          staticIpRepository: self.mockStaticIpRepository,
                                          notificationsRepository: self.mockNotificationsRepository,
                                          emergencyRepository: self.mockEmergencyRepository,
                                          logger: self.mockLogger)
        }.inObjectScope(.container)

        repository = mockContainer.resolve(UserDataRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        repository = nil
        mockServerRepository = nil
        mockCredentialsRepository = nil
        mockPortMapRepository = nil
        mockLatencyRepository = nil
        mockStaticIpRepository = nil
        mockNotificationsRepository = nil
        mockEmergencyRepository = nil
        mockLogger = nil
        super.tearDown()
    }

    // MARK: - Tests

    func testPrepareUserDataSuccess() async throws {
        // Given
        mockServerRepository.mockServers = []
        mockCredentialsRepository.mockOpenVPNCredentials = ServerCredentialsModel(username: "test", password: "test")
        mockCredentialsRepository.mockIKEv2Credentials = ServerCredentialsModel(username: "test", password: "test")
        mockPortMapRepository.portMapsToReturn = []
        mockNotificationsRepository.mockNotices = []
        mockStaticIpRepository.mockStaticIPs = []
        mockLatencyRepository.mockPingData = []
        mockEmergencyRepository.mockIsConnected = false

        // When
        try await repository.prepareUserData()

        // Then
        XCTAssertTrue(mockServerRepository.updatedServersCalled, "Should update servers")
        XCTAssertTrue(mockLatencyRepository.pickBestLocationCalled, "Should pick best location")
        XCTAssertTrue(mockLatencyRepository.loadQuickLatencyCalled, "Should load quick latency when not in emergency mode")
        XCTAssertTrue(mockCredentialsRepository.getUpdatedOpenVPNCrendentialsCalled, "Should get OpenVPN credentials")
        XCTAssertTrue(mockCredentialsRepository.getUpdatedIKEv2CrendentialsCalled, "Should get IKEv2 credentials")
        XCTAssertTrue(mockCredentialsRepository.getUpdatedServerConfigCalled, "Should get server config")
        XCTAssertTrue(mockPortMapRepository.getUpdatedPortMapCalled, "Should get port map")
        XCTAssertTrue(mockNotificationsRepository.getUpdatedNotificationsCalled, "Should get notifications")
        XCTAssertTrue(mockStaticIpRepository.updateStaticServersCalled, "Should update static IPs")
    }

    func testPrepareUserDataWhenEmergencyConnected() async throws {
        // Given
        mockServerRepository.mockServers = []
        mockCredentialsRepository.mockOpenVPNCredentials = ServerCredentialsModel(username: "test", password: "test")
        mockCredentialsRepository.mockIKEv2Credentials = ServerCredentialsModel(username: "test", password: "test")
        mockPortMapRepository.portMapsToReturn = []
        mockNotificationsRepository.mockNotices = []
        mockStaticIpRepository.mockStaticIPs = []
        mockLatencyRepository.mockPingData = []
        mockEmergencyRepository.mockIsConnected = true

        // When
        try await repository.prepareUserData()

        // Small delay to ensure any background tasks don't interfere with assertions
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        XCTAssertTrue(mockServerRepository.updatedServersCalled, "Should update servers")
        XCTAssertTrue(mockLatencyRepository.pickBestLocationCalled, "Should pick best location")
        XCTAssertTrue(mockEmergencyRepository.isConnectedCalled, "Should check emergency connection status")
        XCTAssertFalse(mockLatencyRepository.loadQuickLatencyCalled, "Should NOT load quick latency in emergency mode")
        XCTAssertFalse(mockLatencyRepository.loadLatencyCalled, "Should NOT load full latency in emergency mode")
    }

    func testPrepareUserDataHandlesServerRepositoryError() async throws {
        // Given
        mockServerRepository.shouldThrowError = true
        mockServerRepository.errorToThrow = NSError(domain: "Test", code: 1, userInfo: nil)

        // When/Then
        do {
            try await repository.prepareUserData()
            XCTFail("Should throw error when server repository fails")
        } catch {
            XCTAssertTrue(mockServerRepository.updatedServersCalled, "Should attempt to update servers")
        }
    }

    func testPrepareUserDataHandlesCriticalErrors() async throws {
        // Given
        mockServerRepository.mockServers = []
        mockPortMapRepository.shouldThrowError = true
        mockPortMapRepository.errorToThrow = NSError(domain: "Test", code: 1, userInfo: nil)

        // When/Then
        do {
            try await repository.prepareUserData()
            XCTFail("Should throw error when critical repository fails")
        } catch {
            XCTAssertTrue(mockServerRepository.updatedServersCalled, "Should complete server update before failing")
            XCTAssertTrue(mockPortMapRepository.getUpdatedPortMapCalled, "Should attempt to get port map")
        }
    }

    func testPrepareUserDataIgnoresNonCriticalErrors() async throws {
        // Given
        mockServerRepository.mockServers = []
        mockCredentialsRepository.shouldThrowErrorOnIKEv2 = true
        mockCredentialsRepository.shouldThrowErrorOnOpenVPN = true
        mockStaticIpRepository.shouldThrowError = true
        mockPortMapRepository.portMapsToReturn = []
        mockNotificationsRepository.mockNotices = []

        // When
        try await repository.prepareUserData()

        // Then - Should complete successfully despite credential and static IP errors
        XCTAssertTrue(mockServerRepository.updatedServersCalled, "Should update servers")
        XCTAssertTrue(mockCredentialsRepository.getUpdatedIKEv2CrendentialsCalled, "Should attempt IKEv2")
        XCTAssertTrue(mockCredentialsRepository.getUpdatedOpenVPNCrendentialsCalled, "Should attempt OpenVPN")
        XCTAssertTrue(mockStaticIpRepository.updateStaticServersCalled, "Should attempt static IPs")
        XCTAssertTrue(mockPortMapRepository.getUpdatedPortMapCalled, "Should complete port map")
        XCTAssertTrue(mockNotificationsRepository.getUpdatedNotificationsCalled, "Should complete notifications")
    }
}
