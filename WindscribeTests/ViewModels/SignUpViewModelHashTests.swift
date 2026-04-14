//
//  SignUpViewModelHashTests.swift
//  WindscribeTests
//
//  Created by Anthony on 2026-04-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
import Combine
@testable import Windscribe

final class SignUpViewModelHashTests: XCTestCase {

    var sut: SignUpViewModelImpl!
    var mockAPIManager: MockAPIManager!
    var mockHashAuthManager: MockHashAuthManager!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockAPIManager = MockAPIManager()
        mockHashAuthManager = MockHashAuthManager()
        cancellables = []

        sut = SignUpViewModelImpl(
            apiCallManager: mockAPIManager,
            userSessionRepository: MockUserSessionRepository(),
            userDataRepository: MockUserDataRepository(),
            preferences: MockPreferences(),
            connectivity: MockConnectivityManager(),
            vpnManager: MockVPNManager(),
            protocolManager: MockProtocolManager(),
            latencyRepository: MockLatencyRepository(),
            emergencyConnectRepository: MockEmergencyRepository(),
            lookAndFeelRepository: MockLookAndFeelRepository(),
            logger: MockLogger(),
            sessionManager: MockSessionManager(),
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

    func test_isContinueButtonEnabled_standardTab_requiresUsernamePasswordAndConfirm() {
        sut.selectedTab = .standard

        sut.username = "ab"
        sut.password = "abc"
        sut.confirmPassword = "abc"
        XCTAssertFalse(sut.isContinueButtonEnabled, "Username too short")

        sut.username = "abc"
        sut.password = "ab"
        sut.confirmPassword = "ab"
        XCTAssertFalse(sut.isContinueButtonEnabled, "Password too short")

        sut.username = "abc"
        sut.password = "abc"
        sut.confirmPassword = "xyz"
        XCTAssertFalse(sut.isContinueButtonEnabled, "Passwords don't match")

        sut.username = "abc"
        sut.password = "abc"
        sut.confirmPassword = "abc"
        XCTAssertTrue(sut.isContinueButtonEnabled)
    }

    func test_isContinueButtonEnabled_hashedTab_requiresBackupAndHash() {
        sut.selectedTab = .hashed

        sut.hasBackedUpHash = false
        sut.accountHash = "0xabc123"
        XCTAssertFalse(sut.isContinueButtonEnabled, "Not backed up")

        sut.hasBackedUpHash = true
        sut.accountHash = ""
        XCTAssertFalse(sut.isContinueButtonEnabled, "Empty hash")

        sut.hasBackedUpHash = true
        sut.accountHash = "0xabc123"
        XCTAssertTrue(sut.isContinueButtonEnabled)
    }

    // MARK: - continueButtonTapped validation

    func test_continueButtonTapped_standardTab_shortUsername_setsError() {
        sut.selectedTab = .standard
        sut.username = "ab"
        sut.password = "validpass"
        sut.confirmPassword = "validpass"

        sut.continueButtonTapped(ignoreEmailCheck: true, claimAccount: false)

        if case .username = sut.failedState {} else {
            XCTFail("Expected username error")
        }
    }

    func test_continueButtonTapped_standardTab_shortPassword_setsError() {
        sut.selectedTab = .standard
        sut.username = "validuser"
        sut.password = "short"
        sut.confirmPassword = "short"

        sut.continueButtonTapped(ignoreEmailCheck: true, claimAccount: false)

        if case .password = sut.failedState {} else {
            XCTFail("Expected password error")
        }
    }

    func test_continueButtonTapped_standardTab_mismatchedPasswords_setsError() {
        sut.selectedTab = .standard
        sut.username = "validuser"
        sut.password = "validpass"
        sut.confirmPassword = "different"

        sut.continueButtonTapped(ignoreEmailCheck: true, claimAccount: false)

        if case .confirmPassword = sut.failedState {} else {
            XCTFail("Expected confirmPassword error")
        }
    }

    func test_continueButtonTapped_hashedTab_emptyHash_doesNothing() {
        sut.selectedTab = .hashed
        sut.accountHash = ""

        sut.continueButtonTapped(ignoreEmailCheck: true, claimAccount: false)

        XCTAssertFalse(sut.showLoadingView)
    }

    // MARK: - Hash delegation

    func test_regenerateHash_delegatesToManager() {
        sut.regenerateHash()

        XCTAssertTrue(mockHashAuthManager.regenerateCalled)
    }

    func test_copyHash_delegatesToManager() {
        sut.copyHash()

        XCTAssertTrue(mockHashAuthManager.copyHashCalled)
    }

    func test_loadHashFromFile_delegatesToManager() {
        let data = Data([1, 2, 3])
        sut.loadHashFromFile(data)

        XCTAssertTrue(mockHashAuthManager.loadFromFileCalled)
        XCTAssertEqual(mockHashAuthManager.loadedData, data)
    }
}
