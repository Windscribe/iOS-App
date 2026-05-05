//
//  RealmKeychainPortMigrationTests.swift
//  WindscribeTests
//
//  Regression coverage for the bug where the Realm→GRDB swap happened
//  during DI resolution, leaving MigrationRepository to read sessions /
//  credentials from a GRDB impl that always returned nil. The port now
//  runs against the Realm impl directly inside the LocalDatabase factory,
//  before the GRDB swap.
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import XCTest
@testable import Windscribe

class RealmKeychainPortMigrationTests: XCTestCase {
    var realm: MockLocalDatabase!
    var preferences: MockPreferences!
    var sessionStore: MockSessionKeychainStore!
    var logger: MockLogger!

    override func setUp() {
        super.setUp()
        realm = MockLocalDatabase()
        preferences = MockPreferences()
        sessionStore = MockSessionKeychainStore()
        logger = MockLogger()
    }

    override func tearDown() {
        realm = nil
        preferences = nil
        sessionStore = nil
        logger = nil
        super.tearDown()
    }

    private func runPort() {
        RealmKeychainPortMigration.run(
            realm: realm,
            preferences: preferences,
            sessionStore: sessionStore,
            logger: logger
        )
    }

    // MARK: - Session

    func testRealmSession_PortedToKeychain_AndRealmCleared() {
        preferences.mockFirstInstall = true
        let mockSession = MockSession()
        mockSession.configureLists()
        realm.sessionSubject.send(SessionModel(from: mockSession))

        runPort()

        XCTAssertTrue(sessionStore.saveCalled, "Should save session to Keychain")
        XCTAssertEqual(sessionStore.storedSession?.username, "mockUsername",
                       "Should migrate the correct session data")
        XCTAssertTrue(realm.clearSessionFromRealmCalled,
                      "Should clear session from Realm after porting")
    }

    func testKeychainAlreadyHasSession_RealmNotRead() {
        preferences.mockFirstInstall = true
        let existingSession = SessionModel(from: MockSession())
        sessionStore.storedSession = existingSession

        runPort()

        XCTAssertTrue(sessionStore.loadCalled, "Should check the Keychain first")
        XCTAssertFalse(sessionStore.saveCalled,
                       "Should NOT overwrite an existing Keychain session")
        XCTAssertFalse(realm.clearSessionFromRealmCalled,
                       "Should NOT clear Realm if Keychain already has a session")
    }

    func testFreshInstall_StaleKeychainSessionCleared() {
        preferences.mockFirstInstall = false
        sessionStore.storedSession = SessionModel(from: MockSession())

        runPort()

        XCTAssertTrue(sessionStore.clearCalled,
                      "Should clear stale Keychain session on fresh install")
        XCTAssertFalse(sessionStore.saveCalled,
                       "Should NOT save anything on fresh install")
    }

    // MARK: - OpenVPN / IKEv2 credentials

    func testRealmOpenVPNCredentials_PortedToKeychain_AndRealmCleared() {
        preferences.mockFirstInstall = true
        realm.mockOpenVPNCredentials = ServerCredentialsModel(username: "ovpn-user", password: "ovpn-pass")

        runPort()

        XCTAssertTrue(preferences.saveOpenVPNCredentialsCalled, "Should save OpenVPN creds to Keychain")
        XCTAssertEqual(preferences.mockOpenVPNCredentials?.username, "ovpn-user")
        XCTAssertNil(realm.mockOpenVPNCredentials, "Should clear OpenVPN creds from Realm")
    }

    func testRealmIKEv2Credentials_PortedToKeychain_AndRealmCleared() {
        preferences.mockFirstInstall = true
        realm.mockIKEv2Credentials = ServerCredentialsModel(username: "ike-user", password: "ike-pass")

        runPort()

        XCTAssertTrue(preferences.saveIKEv2CredentialsCalled, "Should save IKEv2 creds to Keychain")
        XCTAssertEqual(preferences.mockIKEv2Credentials?.username, "ike-user")
        XCTAssertNil(realm.mockIKEv2Credentials, "Should clear IKEv2 creds from Realm")
    }

    func testFreshInstall_StaleCredentialsCleared() {
        preferences.mockFirstInstall = false
        preferences.mockOpenVPNCredentials = ServerCredentialsModel(username: "x", password: "y")
        preferences.mockIKEv2Credentials = ServerCredentialsModel(username: "x", password: "y")

        runPort()

        XCTAssertNil(preferences.mockOpenVPNCredentials,
                     "Should clear stale OpenVPN creds on fresh install")
        XCTAssertNil(preferences.mockIKEv2Credentials,
                     "Should clear stale IKEv2 creds on fresh install")
    }

    // MARK: - Custom config credentials

    func testCustomConfigCredentials_PortedToKeychain_AndRealmStripped() {
        preferences.mockFirstInstall = true
        let config = CustomConfigModel(
            id: "cfg-1",
            name: "test",
            serverAddress: "1.2.3.4",
            protocolType: "openvpn",
            port: "443",
            username: "cfg-user",
            password: "cfg-pass"
        )
        realm.customConfigsSubject.send([config])

        runPort()

        let stored = preferences.getAllCustomConfigCredentials()
        XCTAssertEqual(stored["cfg-1"]?.username, "cfg-user",
                       "Should save custom config credentials dictionary to Keychain")
        XCTAssertEqual(stored["cfg-1"]?.password, "cfg-pass")
        let savedRealmCopy = realm.customConfigsSubject.value.last
        XCTAssertEqual(savedRealmCopy?.username, "", "Should strip username from Realm copy")
        XCTAssertEqual(savedRealmCopy?.password, "", "Should strip password from Realm copy")
    }
}
