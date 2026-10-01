//
//  RealmSchemaMigrationTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import XCTest
@testable import Windscribe

@MainActor
final class RealmSchemaMigrationTests: XCTestCase {
    // MARK: - Migration regression tests

    func testVersion42PreferencesSurviveCumulativeMigrationAndReopen() throws {
        let fileURL = try makeRealmURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let preferences = MigrationPreferencesSpy()
        let configuration = productionConfiguration(fileURL: fileURL, preferences: preferences)

        try writeVersion42Fixture(fileURL: fileURL, includePreferences: true)
        XCTAssertEqual(try schemaVersionAtURL(fileURL), 42)

        // Opening the file, not invoking a copied/test migration, exercises the actual
        // v43 destination write and all subsequent blocks, including the v47 copy.
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            XCTAssertEqual(realm.objects(UserPreferences.self).count, 1)
            let row = try XCTUnwrap(realm.object(ofType: UserPreferences.self, forPrimaryKey: "legacy-user"))
            assertPreservedPreferences(row)
            XCTAssertFalse(row.showServerNetLoad)
            XCTAssertFalse(row.killSwitch)
            XCTAssertFalse(row.allowLan)
            assertCopiedPreferences(preferences)
            XCTAssertEqual(preferences.languageSaveCount, 1)
        }
        XCTAssertEqual(try schemaVersionAtURL(fileURL), configuration.schemaVersion)

        // Release all accessors before reopening so Realm must read the migrated file.
        // Changing the spy makes an accidental repeat of the v47 side effects visible.
        preferences.mockLanguage = "after-migration"
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            XCTAssertEqual(realm.objects(UserPreferences.self).count, 1)
            let row = try XCTUnwrap(realm.object(ofType: UserPreferences.self, forPrimaryKey: "legacy-user"))
            assertPreservedPreferences(row)
            XCTAssertFalse(row.showServerNetLoad)
            XCTAssertFalse(row.killSwitch)
            XCTAssertFalse(row.allowLan)
        }
        XCTAssertEqual(preferences.languageSaveCount, 1)
        XCTAssertEqual(preferences.mockLanguage, "after-migration")
    }

    func testVersion42WithoutPreferencesDoesNotCreateOrCopyARow() throws {
        let fileURL = try makeRealmURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let preferences = MigrationPreferencesSpy()
        preferences.mockLanguage = "existing-setting"
        let configuration = productionConfiguration(fileURL: fileURL, preferences: preferences)
        try writeVersion42Fixture(fileURL: fileURL, includePreferences: false)
        XCTAssertEqual(try schemaVersionAtURL(fileURL), 42)

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            XCTAssertTrue(realm.objects(UserPreferences.self).isEmpty)
        }
        XCTAssertEqual(try schemaVersionAtURL(fileURL), configuration.schemaVersion)
        XCTAssertEqual(preferences.languageSaveCount, 0)
        XCTAssertNil(preferences.copiedConnectionMode)
        XCTAssertEqual(preferences.mockLanguage, "existing-setting")
    }

    func testFreshFileDoesNotRunLegacyPreferencesCopy() throws {
        let fileURL = try makeRealmURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let preferences = MigrationPreferencesSpy()
        let configuration = productionConfiguration(fileURL: fileURL, preferences: preferences)
        XCTAssertFalse(FileManager.default.fileExists(atPath: fileURL.path))

        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            XCTAssertTrue(realm.objects(UserPreferences.self).isEmpty)
        }
        XCTAssertEqual(try schemaVersionAtURL(fileURL), configuration.schemaVersion)
        XCTAssertEqual(preferences.languageSaveCount, 0)
        XCTAssertNil(preferences.copiedConnectionMode)
    }

    func testVersion43DoesNotResetExistingNetLoadPreference() throws {
        let fileURL = try makeRealmURL()
        defer { try? FileManager.default.removeItem(at: fileURL.deletingLastPathComponent()) }
        let preferences = MigrationPreferencesSpy()
        let configuration = productionConfiguration(fileURL: fileURL, preferences: preferences)

        // Deliberately a CURRENT model stamped v43, not a historical v43 schema:
        // the current destination field must already exist to test the <43 boundary.
        try autoreleasepool {
            let oldConfiguration = Realm.Configuration(
                fileURL: fileURL, schemaVersion: 43, objectTypes: [UserPreferences.self]
            )
            let realm = try Realm(configuration: oldConfiguration)
            try realm.write {
                let row = UserPreferences()
                row.id = "boundary-user"
                row.showServerNetLoad = true
                row.language = "boundary-language"
                realm.add(row)
            }
        }
        XCTAssertEqual(try schemaVersionAtURL(fileURL), 43)
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            let row = try XCTUnwrap(realm.object(ofType: UserPreferences.self, forPrimaryKey: "boundary-user"))
            XCTAssertTrue(row.showServerNetLoad)
            XCTAssertEqual(preferences.mockLanguage, "boundary-language")
            XCTAssertEqual(preferences.languageSaveCount, 1)
        }
        try autoreleasepool {
            let realm = try Realm(configuration: configuration)
            let row = try XCTUnwrap(realm.object(ofType: UserPreferences.self, forPrimaryKey: "boundary-user"))
            XCTAssertTrue(row.showServerNetLoad)
        }
        XCTAssertEqual(try schemaVersionAtURL(fileURL), configuration.schemaVersion)
        XCTAssertEqual(preferences.languageSaveCount, 1)
    }

    // MARK: - Isolated on-disk fixtures

    private func makeRealmURL() throws -> URL {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("RealmSchemaMigrationTests-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("fixture.realm")
    }

    private func productionConfiguration(
        fileURL: URL, preferences: MigrationPreferencesSpy
    ) -> Realm.Configuration {
        // migrate() only installs a configuration; the constructor does not open a
        // Realm. Restore the process default synchronously, before opening any file.
        let original = Realm.Configuration.defaultConfiguration
        let configuration: Realm.Configuration = {
            defer { Realm.Configuration.defaultConfiguration = original }
            LocalDatabaseImpl(logger: MockLogger(), preferences: preferences).migrate()
            return Realm.Configuration.defaultConfiguration
        }()
        var isolated = configuration
        isolated.fileURL = fileURL
        XCTAssertNotNil(isolated.migrationBlock)
        XCTAssertFalse(isolated.deleteRealmIfMigrationNeeded)
        XCTAssertEqual(isolated.schemaVersion, 64)
        return isolated
    }

    private func writeVersion42Fixture(fileURL: URL, includePreferences: Bool) throws {
        try autoreleasepool {
            let configuration = Realm.Configuration(
                fileURL: fileURL, schemaVersion: 42, objectTypes: [Version42UserPreferences.self]
            )
            let realm = try Realm(configuration: configuration)
            let row = Version42UserPreferences()
            // Verify that this fixture actually lacks the properties introduced later.
            let names = Set(row.objectSchema.properties.map(\.name))
            XCTAssertFalse(names.contains("showServerHealth"))
            XCTAssertFalse(names.contains("showServerNetLoad"))
            XCTAssertFalse(names.contains("killSwitch"))
            XCTAssertFalse(names.contains("allowLan"))
            if includePreferences {
                try realm.write { realm.add(row) }
            }
            XCTAssertEqual(realm.objects(Version42UserPreferences.self).count, includePreferences ? 1 : 0)
        }
    }

    private func assertPreservedPreferences(
        _ row: UserPreferences, file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(row.id, "legacy-user", file: file, line: line)
        XCTAssertEqual(row.connectionMode, "manual", file: file, line: line)
        XCTAssertEqual(row.language, "fr", file: file, line: line)
        XCTAssertEqual(row.latencyType, "milliseconds", file: file, line: line)
        XCTAssertEqual(row.orderLocationsBy, "alphabetical", file: file, line: line)
        XCTAssertEqual(row.appearance, DefaultValues.appearance, file: file, line: line)
        XCTAssertFalse(row.firewall, file: file, line: line)
        XCTAssertFalse(row.autoSecureNewNetworks, file: file, line: line)
        XCTAssertFalse(row.hapticFeedback, file: file, line: line)
        XCTAssertEqual(row.protocolType, VPNProtocolType.wireGuard.identifier, file: file, line: line)
        XCTAssertEqual(row.port, "51820", file: file, line: line)
    }

    private func assertCopiedPreferences(
        _ preferences: MigrationPreferencesSpy, file: StaticString = #filePath, line: UInt = #line
    ) {
        XCTAssertEqual(preferences.copiedConnectionMode, "manual", file: file, line: line)
        XCTAssertEqual(preferences.mockLanguage, "fr", file: file, line: line)
        XCTAssertEqual(preferences.copiedOrderLocationsBy, "alphabetical", file: file, line: line)
        XCTAssertEqual(preferences.mockDarkMode, true, file: file, line: line)
        XCTAssertEqual(preferences.mockFirewallMode, false, file: file, line: line)
        XCTAssertEqual(preferences.mockKillSwitch, false, file: file, line: line)
        XCTAssertEqual(preferences.copiedAllowLan, false, file: file, line: line)
        XCTAssertEqual(preferences.copiedAutoSecure, false, file: file, line: line)
        XCTAssertEqual(preferences.copiedHapticFeedback, false, file: file, line: line)
        XCTAssertEqual(preferences.mockSelectedProtocol.value, VPNProtocolType.wireGuard.identifier, file: file, line: line)
        XCTAssertEqual(preferences.mockSelectedPort, "51820", file: file, line: line)
    }
}

// Reconstructed v42 preferences only, not a shipped database. Map the fixture to
// the real table without adding this historical type to Realm's default schema.
@objc(WSMigrationVersion42UserPreferences)
private class Version42UserPreferences: Object {
    // MARK: - Historical persisted properties

    @objc dynamic var id = "legacy-user"
    @objc dynamic var connectionMode = "manual"
    @objc dynamic var language = "fr"
    @objc dynamic var latencyType = "milliseconds"
    @objc dynamic var orderLocationsBy = "alphabetical"
    @objc dynamic var appearance = DefaultValues.appearance
    @objc dynamic var firewall = false
    @objc dynamic var autoSecureNewNetworks = false
    @objc dynamic var hapticFeedback = false
    @objc dynamic var protocolType = VPNProtocolType.wireGuard.identifier
    @objc dynamic var port = "51820"

    // MARK: - Realm schema identity

    override class func primaryKey() -> String? { "id" }
    override class func _realmObjectName() -> String { UserPreferences.className() }
    override class func shouldIncludeInDefaultSchema() -> Bool { false }
}

private final class MigrationPreferencesSpy: MockPreferences {
    // MARK: - Recorded preferences

    var copiedConnectionMode: String?
    var copiedOrderLocationsBy: String?
    var copiedAllowLan: Bool?
    var copiedAutoSecure: Bool?
    var copiedHapticFeedback: Bool?
    var languageSaveCount = 0

    // MARK: - Saves not recorded by the shared mock

    override func saveConnectionMode(mode: String) { copiedConnectionMode = mode }
    override func saveOrderLocationsBy(order: String) { copiedOrderLocationsBy = order }
    override func saveAllowLane(mode: Bool) { copiedAllowLan = mode }
    override func saveAutoSecureNewNetworks(autoSecure: Bool) { copiedAutoSecure = autoSecure }
    override func saveHapticFeedback(haptic: Bool) { copiedHapticFeedback = haptic }

    override func saveLanguage(language: String) {
        languageSaveCount += 1
        super.saveLanguage(language: language)
    }
}
