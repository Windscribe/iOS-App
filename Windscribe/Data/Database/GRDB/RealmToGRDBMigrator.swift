// RealmToGRDBMigrator.swift
// Windscribe
//
// One-time port of all persisted data from the Realm-backed LocalDatabase
// into a freshly-initialised GRDB database. Designed to run on first launch
// after the user upgrades from a Realm release to the GRDB release.
//
// Safety contract
// ───────────────
// • The migration flag (`didMigrateRealmToGRDB_v2`) is set ONLY on success.
// • If any step throws, the flag stays unset and the migrator retries next launch.
// • The Realm file is never touched; GRDB can be wiped and re-seeded freely.
// • A post-write digest compares row/object counts between both DBs; mismatch
//   also leaves the flag unset so the next launch retries.
//
// Copyright © 2026 Windscribe. All rights reserved.

import Foundation
import GRDB

final class RealmToGRDBMigrator {

    // MARK: - Dependencies

    private let realmDB: LocalDatabase          // source  (Realm-backed)
    private let grdbDB: GRDBLocalDatabaseImpl   // destination
    private let preferences: Preferences
    private let logger: FileLogger

    // MARK: - Init

    init(
        realmDB: LocalDatabase,
        grdbDB: GRDBLocalDatabaseImpl,
        preferences: Preferences,
        logger: FileLogger
    ) {
        self.realmDB    = realmDB
        self.grdbDB     = grdbDB
        self.preferences = preferences
        self.logger     = logger
    }

    // MARK: - Public API

    /// Ports data from Realm → GRDB if not already done. Idempotent.
    /// Returns `true` if migration is complete (either now or on a prior launch).
    @discardableResult
    func migrateIfNeeded() -> Bool {
        if preferences.didMigrateRealmToGRDB() {
            logger.logI("RealmToGRDBMigrator", "Migration already complete — skipping.")
            return true
        }

        do {
            try performMigration()
        } catch {
            logger.logE("RealmToGRDBMigrator", "Migration failed: \(error). Flag unset — will retry next launch.")
            return false
        }

        let digest = verifyDigest()
        if digest.matches {
            preferences.saveDidMigrateRealmToGRDB(true)
            logger.logI("RealmToGRDBMigrator", "Migration complete. Digest OK: \(digest.description)")
            return true
        } else {
            logger.logE("RealmToGRDBMigrator", "Digest mismatch: \(digest.description). Flag unset — will retry next launch.")
            return false
        }
    }

    // MARK: - Migration

    private func performMigration() throws {
        // Sessions, OldSession, and OpenVPN/IKEv2 server credentials migrate
        // separately — they live in the Keychain (see MigrationRepository's
        // migrateSessionFromRealmToKeychain / migrateServerCredentialsToKeychain
        // / migrateCustomConfigCredentialsToKeychain). MigrationRepository runs
        // before GRDB DI swap, so by the time we get here those four entity
        // families are already in the Keychain and have been wiped from Realm.

        // Favourites — preserved across logout, always migrate
        for fav in realmDB.getFavouriteList() {
            grdbDB.saveFavourite(favourite: fav)
        }

        // Locations (new architecture)
        if let locations = realmDB.getLocations(), !locations.isEmpty {
            grdbDB.saveLocations(locations: locations)
        } else if let legacyLocations = realmDB.getServers(), !legacyLocations.isEmpty {
            // LEGACY fallback: user is on pre-v62 Realm that stored Server objects.
            // getServers() already converts them to [LocationModel].
            grdbDB.saveLocations(locations: legacyLocations)
            logger.logI("RealmToGRDBMigrator", "Used legacy Server→Location fallback (\(legacyLocations.count) locations).")
        }

        // Server machines
        if let machines = realmDB.getServerMachines() {
            grdbDB.saveServerMachines(serverMachines: machines)
        }

        // Static IPs
        if let staticIPs = realmDB.getStaticIPs() {
            grdbDB.saveStaticIPs(staticIps: staticIPs)
        }

        // Wi-Fi networks
        for net in realmDB.getNetworks() {
            grdbDB.saveNetwork(wifiNetwork: net)
        }

        // Custom configs
        for cfg in realmDB.getCustomConfigs() {
            grdbDB.saveCustomConfig(customConfig: cfg)
        }

        // Notifications (delete-all + insert-all batch)
        grdbDB.saveNotifications(notifications: realmDB.getNotifications())

        // Read notices
        if let read = realmDB.getReadNotices() {
            grdbDB.saveReadNotices(readNotices: read)
        }

        // Robert filters
        if let filters = realmDB.getRobertFilters() {
            grdbDB.saveRobertFilters(filters: filters)
        }

        // Port maps
        if let maps = realmDB.getPortMap() {
            grdbDB.savePortMap(portMap: maps)
        }
        if let suggested = realmDB.getSuggestedPorts() {
            grdbDB.saveSuggestedPorts(suggestedPorts: suggested)
        }

        // Mobile plans
        if let plans = realmDB.getMobilePlans() {
            grdbDB.saveMobilePlans(mobilePlansList: plans)
        }

        // Unblock WG params
        grdbDB.saveUnblockWgParams(params: realmDB.getUnblockWgParams())

        // Ping data
        for ping in realmDB.getAllPingData() {
            grdbDB.addPingData(pingData: ping)
        }

        // MyIP is deprecated (Issue #911) — intentionally not migrated.
        // It is now stored in Preferences, not the DB.
    }

    // MARK: - Digest

    /// Per-table count comparison between source and destination.
    struct Digest {
        let matches: Bool
        let description: String
    }

    func verifyDigest() -> Digest {
        var mismatches: [String] = []

        func checkOptional<T>(_ name: String, _ lhs: T?, _ rhs: T?) {
            let l = lhs == nil ? "nil" : "present"
            let r = rhs == nil ? "nil" : "present"
            if l != r { mismatches.append("\(name): realm=\(l) grdb=\(r)") }
        }

        func checkCount<T>(_ name: String, _ lhs: [T], _ rhs: [T]) {
            if lhs.count != rhs.count {
                mismatches.append("\(name): realm=\(lhs.count) grdb=\(rhs.count)")
            }
        }

        checkCount("favourites",      realmDB.getFavouriteList(), grdbDB.getFavouriteList())

        // Locations: treat nil and empty as equivalent for digest purposes —
        // the legacy fallback may have bridged Server→Location on the GRDB side.
        let realmLocs  = realmDB.getLocations() ?? []
        let grdbLocs   = grdbDB.getLocations() ?? []
        if realmLocs.isEmpty && !grdbLocs.isEmpty {
            // Legacy fallback populated GRDB — that's correct, don't flag.
        } else {
            checkCount("locations", realmLocs, grdbLocs)
        }

        checkCount("serverMachines",  realmDB.getServerMachines() ?? [], grdbDB.getServerMachines() ?? [])
        checkCount("staticIPs",       realmDB.getStaticIPs() ?? [],      grdbDB.getStaticIPs() ?? [])
        checkCount("wifiNetworks",    realmDB.getNetworks(),              grdbDB.getNetworks())
        checkCount("customConfigs",   realmDB.getCustomConfigs(),         grdbDB.getCustomConfigs())
        checkCount("notices",         realmDB.getNotifications(),         grdbDB.getNotifications())
        checkCount("readNotices",     realmDB.getReadNotices() ?? [],     grdbDB.getReadNotices() ?? [])
        checkOptional("robertFilters", realmDB.getRobertFilters(),        grdbDB.getRobertFilters())
        checkCount("portMaps",        realmDB.getPortMap() ?? [],         grdbDB.getPortMap() ?? [])
        checkCount("suggestedPorts",  realmDB.getSuggestedPorts() ?? [],  grdbDB.getSuggestedPorts() ?? [])
        checkCount("mobilePlans",     realmDB.getMobilePlans() ?? [],     grdbDB.getMobilePlans() ?? [])
        checkCount("unblockWgParams", realmDB.getUnblockWgParams(),       grdbDB.getUnblockWgParams())
        checkCount("pingData",        realmDB.getAllPingData(),            grdbDB.getAllPingData())

        let ok = mismatches.isEmpty
        let desc = ok ? "all tables match" : mismatches.joined(separator: ", ")
        return Digest(matches: ok, description: desc)
    }
}
