//
//  UserSessionRepositoryTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class UserSessionRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var mockPreferences: MockPreferences!
    var mockLocalDatabase: MockLocalDatabase!
    var mockSessionStore: MockSessionKeychainStore!
    var mockLocationListRepository: MockLocationListRepository!
    var mockAntiCensorshipRepository: MockAntiCensorshipRepository!

    var repository: UserSessionRepository!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockPreferences = MockPreferences()
        mockLocalDatabase = MockLocalDatabase()
        mockSessionStore = MockSessionKeychainStore()
        mockLocationListRepository = MockLocationListRepository()
        mockAntiCensorshipRepository = MockAntiCensorshipRepository()

        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }
        mockContainer.register(LocalDatabase.self) { _ in
            return self.mockLocalDatabase
        }
        mockContainer.register(SessionKeychainStore.self) { _ in
            return self.mockSessionStore
        }
        mockContainer.register(LocationListRepository.self) { _ in
            return self.mockLocationListRepository
        }
        mockContainer.register(AntiCensorshipRepository.self) { _ in
            return self.mockAntiCensorshipRepository
        }

        mockContainer.register(UserSessionRepository.self) { r in
            return UserSessionRepositoryImpl(preferences: r.resolve(Preferences.self)!,
                                             localDatabase: r.resolve(LocalDatabase.self)!,
                                             sessionStore: r.resolve(SessionKeychainStore.self)!,
                                             locationListRepository: r.resolve(LocationListRepository.self)!,
                                             antiCensorshipRepository: r.resolve(AntiCensorshipRepository.self)!)
        }.inObjectScope(.container)

        repository = mockContainer.resolve(UserSessionRepository.self)!
    }

    override func tearDown() {
        mockContainer = nil
        repository = nil
        mockPreferences = nil
        mockLocalDatabase = nil
        mockSessionStore = nil
        mockLocationListRepository = nil
        super.tearDown()
    }

    // MARK: GetUpdatedUser Tests

    func test_updateSession() async {
        // Given
        let mockSession = createMockSession()
        let mockSessionSecond = createMockSessionSecond()

        XCTAssertNil(repository.sessionModel, "Session should be nil at the beginning")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil at the beginning")

        await repository.update(session: mockSession)
        XCTAssertEqual(repository.sessionModel, mockSession, "The session should now update to the new one")
        XCTAssertNil(repository.oldSessionModel, "Old Session should still be nil")

        await repository.update(session: mockSessionSecond)
        XCTAssertEqual(repository.sessionModel, mockSessionSecond, "The session should now update to the new one")
        XCTAssertEqual(repository.oldSessionModel, mockSession, "Old Session should now update to the first one")
    }

    func test_clearSession() async {
        // Given
        let mockSession = createMockSession()
        let mockSessionSecond = createMockSessionSecond()

        XCTAssertNil(repository.sessionModel, "Session should be nil at the beginning")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil at the beginning")

        await repository.update(session: mockSession)
        await repository.update(session: mockSessionSecond)
        XCTAssertNotNil(repository.sessionModel, "The session should not be nil after 2 updates")
        XCTAssertNotNil(repository.oldSessionModel, "Old Session should not be nil after 2 updates")

        repository.clearSession()
        XCTAssertNil(repository.sessionModel, "Session should be nil after clear")
        XCTAssertNil(repository.oldSessionModel, "Old Session should be nil after clear")
    }

    func test_canAccesstoProLocation() async {
        // Given
        let mockSession = createMockSession()
        let mockSessionSecond = createMockSessionSecond()
        let proLocation = createMockLocation()

        await repository.update(session: mockSession)
        XCTAssertTrue(repository.canAccesstoProLocation(location: proLocation), "First Session IS pro and CAN Access to Pro Location")

        await repository.update(session: mockSessionSecond)
        XCTAssertFalse(repository.canAccesstoProLocation(location: proLocation), "Second Session is NOT pro and CANNOT Access to Pro Location")
    }

    func test_canAccesstoProLocation_withALC() async {
        // Given — free user but location is in their ALC list
        let alcLocation = createMockLocation(shortName: "US")
        let sessionWithALC = SessionModel(
            sessionAuthHash: "test-auth-hash",
            username: "TestUser",
            userId: "123",
            isUserPro: false,
            isPremium: false,
            email: "test@example.com",
            emailStatus: true,
            billing: 0,
            alc: ["US"],
            rebill: 0,
            billingPlanId: 0,
            trafficUsed: 0,
            trafficMax: 10737418240,
            status: 1,
            expiryDate: "",
            lastReset: "2026-01-01",
            regDate: "2021",
            deviceId: "test-device",
            sipCount: 0,
            loc: "",
            locHash: "test-loc-hash",
            revisionHash: "test-revision",
            amneziawgConfigId: ""
        )

        await repository.update(session: sessionWithALC)
        XCTAssertTrue(repository.canAccesstoProLocation(location: alcLocation), "Free user with ALC containing location shortName CAN access")

        let nonALCLocation = createMockLocation(shortName: "DE")
        XCTAssertFalse(repository.canAccesstoProLocation(location: nonALCLocation), "Free user without ALC for location CANNOT access")
    }

    // MARK: - Helper Methods

    private func createMockLocation(shortName: String = "CA") -> LocationModel {
        return LocationModel(
            id: 1,
            name: "Test Location",
            countryCode: "XX",
            shortName: shortName,
            sortOrder: 0,
            continent: "NA",
            datacenters: []
        )
    }

    private func createMockSession() -> SessionModel {
        return SessionModel(
            sessionAuthHash: "test-auth-hash",
            username: "TestUser",
            userId: "123",
            isUserPro: true,
            isPremium: true,
            email: "test@example.com",
            emailStatus: true,
            billing: 1,
            alc: [],
            rebill: 0,
            billingPlanId: 1,
            trafficUsed: 0,
            trafficMax: 10737418240, // 10 GB
            status: 1,
            expiryDate: "2026-12-31",
            lastReset: "2026-01-01",
            regDate: "2021",
            deviceId: "test-device",
            sipCount: 0,
            loc: "",
            locHash: "test-loc-hash",
            revisionHash: "test-revision",
            amneziawgConfigId: ""
        )
    }

    private func createMockSessionSecond() -> SessionModel {
        return SessionModel(
            sessionAuthHash: "test-auth-hash-second",
            username: "TestUser",
            userId: "123",
            isUserPro: false,
            isPremium: false,
            email: "test@example.com",
            emailStatus: true,
            billing: 0,
            alc: [],
            rebill: 0,
            billingPlanId: 0,
            trafficUsed: 0,
            trafficMax: 10737418240, // 10 GB
            status: 1,
            expiryDate: "",
            lastReset: "2026-01-01",
            regDate: "2021",
            deviceId: "test-device",
            sipCount: 0,
            loc: "",
            locHash: "test-loc-hash-second",
            revisionHash: "test-revision",
            amneziawgConfigId: ""
        )
    }
}

// MARK: - ConfigurationsManager Access Validation Regression Tests

final class ConfigurationsManagerAccessValidationTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    func testValidateAccessToLocationForProUserServerLocationCompletes() {
        let sut = makeSUT()
        let expectation = expectation(description: "Pro user server location access validation completes")
        var receivedError: Error?

        sut.validateAccessToLocation(locationID: "101")
            .sink(receiveCompletion: { completion in
                if case let .failure(error) = completion {
                    receivedError = error
                }
            }, receiveValue: {
                expectation.fulfill()
            })
            .store(in: &cancellables)

        wait(for: [expectation], timeout: 1.0)
        XCTAssertNil(receivedError)
    }

    private func makeSUT() -> ConfigurationsManager {
        let preferences = MockPreferences()
        preferences.mockPrivacyPopupAccepted = true

        let server = ServerMachineModel(
            id: 1,
            hostname: "pro-location-001.windscribe.com",
            ip: "192.0.2.1",
            ip2: "192.0.2.2",
            ip3: "192.0.2.3",
            ipv6: 0,
            datacenterId: 101,
            weight: 100,
            netLoad: 10,
            sclass: 1
        )

        var datacenter = DatacenterModel(
            id: 101,
            city: "Toronto",
            nick: "Pro",
            iata: "YYZ",
            status: 1,
            gps: "43.6532,-79.3832",
            tz: "America/Toronto",
            p2p: 1,
            isPremium: 1,
            wgPubkey: "test-wg-key",
            wgEndpoint: "pro-location.windscribe.com:443",
            ovpnX509: "test-x509",
            linkSpeed: 1000
        )
        datacenter.locationId = 1
        datacenter.servers = [server]

        let location = LocationModel(
            id: 1,
            name: "Canada",
            countryCode: "CA",
            shortName: "CA",
            sortOrder: 1,
            continent: "North America",
            datacenters: [datacenter]
        )

        let locationsManager = MockLocationsManager()
        locationsManager.mockConnectionTargetType = .server
        locationsManager.mockLocation = (location, datacenter)

        let userSessionRepository = MockUserSessionRepository()
        userSessionRepository.setMockSession(userId: "pro-user", isPremium: true)

        let locationListRepository = MockLocationListRepository()
        locationListRepository.locationListSubject.send([location])
        locationListRepository.datacenterListSubject.send([datacenter])
        locationListRepository.serverListSubject.send([server])

        return ConfigurationsManager(
            logger: MockLogger(),
            keychainDb: ConfigurationsManagerAccessKeyChainDatabase(),
            fileDatabase: MockFileDatabase(),
            advanceRepository: MockAdvanceRepository(),
            wgRepository: ConfigurationsManagerAccessWireguardConfigRepository(),
            wgCredentials: MockWgCredentials(),
            preferences: preferences,
            locationsManager: locationsManager,
            ipRepository: ConfigurationsManagerAccessIPRepository(),
            userSessionRepository: userSessionRepository,
            locationListRepository: locationListRepository,
            bridgeAPI: MockWSNetBridgeAPI(),
            bridgeApiRepository: ConfigurationsManagerAccessBridgeApiRepository(),
            credentialsRepository: MockCredentialsRepository(),
            staticIpRepository: MockStaticIpRepository(),
            customConfigRepository: MockCustomConfigRepository(),
            antiCensorshipRepository: MockAntiCensorshipRepository()
        )
    }
}

private final class ConfigurationsManagerAccessKeyChainDatabase: KeyChainDatabase {
    func save(username: String, password: String) {}
    func retrieve(username: String) -> Data? { nil }
    func isGhostAccountCreated() -> Bool { false }
    func setGhostAccountCreated() {}
}

private final class ConfigurationsManagerAccessWireguardConfigRepository: WireguardConfigRepository {
    func getCredentials() async throws {}
}

private final class ConfigurationsManagerAccessIPRepository: IPRepository {

    let ipState = CurrentValueSubject<IPState?, Never>(nil)
    let currentIp = CurrentValueSubject<String?, Never>(nil)

    func getIp() async throws {}
    func getIp(usePingTest: Bool) async throws {}
}

private final class ConfigurationsManagerAccessBridgeApiRepository: BridgeApiRepository {
    let bridgeIsAvailable = CurrentValueSubject<Bool, Never>(false)
    let isReady = false
}
