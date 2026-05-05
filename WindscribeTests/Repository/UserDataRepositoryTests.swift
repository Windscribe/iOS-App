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
    var mockLocationListRepository: MockLocationListRepository!
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
        mockLocationListRepository = MockLocationListRepository()
        mockCredentialsRepository = MockCredentialsRepository()
        mockPortMapRepository = MockPortMapRepository()
        mockLatencyRepository = MockLatencyRepository()
        mockStaticIpRepository = MockStaticIpRepository()
        mockNotificationsRepository = MockNotificationRepository()
        mockEmergencyRepository = MockEmergencyRepository()
        mockLogger = MockLogger()

        // Register mock LocationListRepository
        mockContainer.register(LocationListRepository.self) { _ in
            return self.mockLocationListRepository
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
            return UserDataRepositoryImpl(credentialsRepository: self.mockCredentialsRepository,
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
        mockLocationListRepository = nil
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
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Then
        XCTAssertTrue(mockLatencyRepository.pickBestLocationCalled, "Should pick best location")
        XCTAssertTrue(mockEmergencyRepository.isConnectedCalled, "Should check emergency connection status")
        XCTAssertFalse(mockLatencyRepository.loadQuickLatencyCalled, "Should NOT load quick latency in emergency mode")
        XCTAssertFalse(mockLatencyRepository.loadLatencyCalled, "Should NOT load full latency in emergency mode")
    }

    func testPrepareUserDataHandlesCriticalErrors() async throws {
        // Given
        mockPortMapRepository.shouldThrowError = true
        mockPortMapRepository.errorToThrow = NSError(domain: "Test", code: 1, userInfo: nil)

        // When/Then
        do {
            try await repository.prepareUserData()
            XCTFail("Should throw error when critical repository fails")
        } catch {
            XCTAssertTrue(mockPortMapRepository.getUpdatedPortMapCalled, "Should attempt to get port map")
        }
    }

    func testPrepareUserDataIgnoresNonCriticalErrors() async throws {
        // Given
        mockCredentialsRepository.shouldThrowErrorOnIKEv2 = true
        mockCredentialsRepository.shouldThrowErrorOnOpenVPN = true
        mockStaticIpRepository.shouldThrowError = true
        mockPortMapRepository.portMapsToReturn = []
        mockNotificationsRepository.mockNotices = []

        // When
        try await repository.prepareUserData()

        // Then - Should complete successfully despite credential and static IP errors
        XCTAssertTrue(mockCredentialsRepository.getUpdatedIKEv2CrendentialsCalled, "Should attempt IKEv2")
        XCTAssertTrue(mockCredentialsRepository.getUpdatedOpenVPNCrendentialsCalled, "Should attempt OpenVPN")
        XCTAssertTrue(mockStaticIpRepository.updateStaticServersCalled, "Should attempt static IPs")
        XCTAssertTrue(mockPortMapRepository.getUpdatedPortMapCalled, "Should complete port map")
        XCTAssertTrue(mockNotificationsRepository.getUpdatedNotificationsCalled, "Should complete notifications")
    }
}
