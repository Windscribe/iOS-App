//
//  LoginViewModelHashTests.swift
//  WindscribeTests
//
//  Created by Anthony on 2026-04-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
import Combine
@testable import Windscribe

final class LoginViewModelHashTests: XCTestCase {

    var sut: LoginViewModelImpl!
    var mockAPIManager: MockAPIManager!
    var mockHashAuthManager: MockHashAuthManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAPIManager = MockAPIManager()
        mockHashAuthManager = MockHashAuthManager()
        cancellables = []

        sut = LoginViewModelImpl(
            apiCallManager: mockAPIManager,
            userSessionRepository: MockUserSessionRepository(),
            sessionManager: MockSessionManager(),
            preferences: MockPreferences(),
            emergencyConnectRepository: MockEmergencyRepository(),
            userDataRepository: MockUserDataRepository(),
            vpnManager: MockVPNManager(),
            protocolManager: MockProtocolManager(),
            latencyRepository: MockLatencyRepository(),
            connectivity: MockConnectivityManager(),
            wifiManager: MockWifiManager(),
            lookAndFeelRepository: MockLookAndFeelRepository(),
            logger: MockLogger(),
            hashAuthManager: mockHashAuthManager
        )
    }

    override func tearDown() {
        sut = nil
        mockAPIManager = nil
        mockHashAuthManager = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - isContinueButtonEnabled

    func test_isContinueButtonEnabled_standardTab_requiresMinLength() {
        sut.selectedTab = .standard

        sut.username = "ab"
        sut.password = "abc"
        XCTAssertFalse(sut.isContinueButtonEnabled, "Username too short")

        sut.username = "abc"
        sut.password = "ab"
        XCTAssertFalse(sut.isContinueButtonEnabled, "Password too short")

        sut.username = "abc"
        sut.password = "abc"
        XCTAssertTrue(sut.isContinueButtonEnabled)
    }

    func test_isContinueButtonEnabled_hashedTab_requiresNonEmptyHash() {
        sut.selectedTab = .hashed

        sut.accountHash = ""
        XCTAssertFalse(sut.isContinueButtonEnabled)

        sut.accountHash = "0xabc123"
        XCTAssertTrue(sut.isContinueButtonEnabled)
    }

    // MARK: - continueButtonTapped

    func test_continueButtonTapped_standardTab_rejectsEmailInUsername() {
        sut.selectedTab = .standard
        sut.username = "user@example.com"
        sut.password = "password123"

        sut.continueButtonTapped()

        if case .username = sut.failedState {} else {
            XCTFail("Expected username error for email input")
        }
    }

    func test_continueButtonTapped_hashedTab_emptyHash_doesNothing() {
        sut.selectedTab = .hashed
        sut.accountHash = ""

        sut.continueButtonTapped()

        XCTAssertFalse(sut.showLoadingView)
    }

    func test_continueButtonTapped_hashedTab_withHash_showsLoading() {
        sut.selectedTab = .hashed
        sut.accountHash = "0xabc123"

        sut.continueButtonTapped()

        XCTAssertTrue(sut.showLoadingView)
    }

    // MARK: - loadHashFromFile

    func test_loadHashFromFile_delegatesToHashAuthManager() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

        sut.loadHashFromFile(data)

        XCTAssertEqual(sut.accountHash, mockHashAuthManager.mockHashResult)
    }
}
