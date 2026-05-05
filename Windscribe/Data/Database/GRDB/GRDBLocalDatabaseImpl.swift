// GRDBLocalDatabaseImpl.swift
// Windscribe
//
// GRDB-backed concrete implementation of the LocalDatabase protocol.
// Replaces the Realm implementation for the aw/realm-to-grdb migration.
//
// Copyright © 2026 Windscribe. All rights reserved.

import Foundation
import Combine
import GRDB

class GRDBLocalDatabaseImpl: LocalDatabase {

    // MARK: - Dependencies

    let logger: FileLogger
    let preferences: Preferences
    let dbQueue: DatabaseQueue

    /// Fires before each clean() — publishers merge this to emit an immediate
    /// nil/empty value, matching the Realm impl's ordering.
    let cleanSubject = PassthroughSubject<Void, Never>()

    // MARK: - Init

    init(logger: FileLogger, preferences: Preferences, dbQueue: DatabaseQueue) {
        self.logger = logger
        self.preferences = preferences
        self.dbQueue = dbQueue
    }

    /// Production convenience init. Writes to Documents/windscribe.sqlite.
    convenience init(logger: FileLogger, preferences: Preferences) throws {
        let fileURL = try FileManager.default
            .url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
            .appendingPathComponent("windscribe.sqlite")
        let queue = try DatabaseQueue(path: fileURL.path)
        try GRDBSchema.makeMigrator().migrate(queue)
        self.init(logger: logger, preferences: preferences, dbQueue: queue)
    }

    // MARK: - migrate()

    func migrate() {
        // No-op: migrations are applied in init via GRDBSchema.makeMigrator().migrate(queue).
        // Kept for LocalDatabase protocol conformance.
    }

    // MARK: - Session (Keychain-resident)
    //
    // Sessions live in the Keychain via SessionKeychainStore; GRDB doesn't
    // store them. The protocol-required readers below exist for the Realm
    // impl's migration role; on GRDB they are no-ops.

    func getSession() -> SessionModel? {
        return nil
    }

    func clearSessionFromRealm() {
        // No-op — sessions are in Keychain, GRDB has no Realm row to clear.
    }

    // MARK: - Servers (legacy — not stored in GRDB; returns nil so callers fall back)

    func getServers() -> [LocationModel]? {
        return nil
    }

    // MARK: - Locations

    func getLocations() -> [LocationModel]? {
        do {
            return try dbQueue.read { db in
                try LocationRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getLocations failed: \(error)")
            return nil
        }
    }

    func saveLocations(locations: [LocationModel]) {
        do {
            try dbQueue.write { db in
                for location in locations {
                    try LocationRecord(from: location).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveLocations failed: \(error)")
        }
    }

    // MARK: - Server Machines

    func getServerMachines() -> [ServerMachineModel]? {
        do {
            return try dbQueue.read { db in
                try ServerMachineRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getServerMachines failed: \(error)")
            return nil
        }
    }

    func getServerMachinesPublisher() -> AnyPublisher<[ServerMachineModel], Never> {
        safeModelArrayPublisher { db in
            try ServerMachineRecord.fetchAll(db).map { $0.toModel() }
        }
    }

    func saveServerMachines(serverMachines: [ServerMachineModel]) {
        do {
            try dbQueue.write { db in
                for machine in serverMachines {
                    try ServerMachineRecord(from: machine).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveServerMachines failed: \(error)")
        }
    }

    // MARK: - Mobile Plans

    func getMobilePlans() -> [MobilePlanModel]? {
        do {
            return try dbQueue.read { db in
                try MobilePlanRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getMobilePlans failed: \(error)")
            return nil
        }
    }

    func saveMobilePlans(mobilePlansList: [MobilePlanModel]) {
        do {
            try dbQueue.write { db in
                for plan in mobilePlansList {
                    try MobilePlanRecord(from: plan).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveMobilePlans failed: \(error)")
        }
    }

    // MARK: - Static IPs

    func getStaticIPs() -> [StaticIPModel]? {
        do {
            return try dbQueue.read { db in
                try StaticIPRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getStaticIPs failed: \(error)")
            return nil
        }
    }

    func saveStaticIPs(staticIps: [StaticIPModel]) {
        do {
            try dbQueue.write { db in
                for sip in staticIps {
                    try StaticIPRecord(from: sip).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveStaticIPs failed: \(error)")
        }
    }

    func deleteStaticIps(ignore: [String]) {
        do {
            try dbQueue.write { db in
                let all = try StaticIPRecord.fetchAll(db)
                for record in all where !ignore.contains(record.staticIP) {
                    try record.delete(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "deleteStaticIps failed: \(error)")
        }
    }

    // MARK: - Server Credentials (Keychain-resident)
    //
    // OpenVPN and IKEv2 server credentials live in the Keychain via
    // Preferences.{save,get,delete}{OpenVPN,IKEv2}Credentials. GRDB doesn't
    // store them. The readers below return nil and the clear* methods are
    // no-ops; they exist only so the Realm impl can satisfy the protocol's
    // migration-role methods.

    func getOpenVPNServerCredentials() -> ServerCredentialsModel? {
        return nil
    }

    func clearOpenVPNServerCredentials() {
        // No-op — credentials are in Keychain, GRDB has no Realm row to clear.
    }

    func getIKEv2ServerCredentials() -> ServerCredentialsModel? {
        return nil
    }

    func clearIKEv2ServerCredentials() {
        // No-op — credentials are in Keychain, GRDB has no Realm row to clear.
    }

    // MARK: - Port Map

    func getPortMap() -> [PortMapModel]? {
        do {
            return try dbQueue.read { db in
                try PortMapRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getPortMap failed: \(error)")
            return nil
        }
    }

    func savePortMap(portMap: [PortMapModel]) {
        do {
            try dbQueue.write { db in
                for entry in portMap {
                    try PortMapRecord(from: entry).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "savePortMap failed: \(error)")
        }
    }

    // MARK: - Suggested Ports

    func getSuggestedPorts() -> [SuggestedPortsModel]? {
        do {
            return try dbQueue.read { db in
                try SuggestedPortsRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getSuggestedPorts failed: \(error)")
            return nil
        }
    }

    func saveSuggestedPorts(suggestedPorts: [SuggestedPortsModel]) {
        do {
            try dbQueue.write { db in
                for entry in suggestedPorts {
                    try SuggestedPortsRecord(from: entry).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveSuggestedPorts failed: \(error)")
        }
    }

    // MARK: - Notifications / Notices

    func getNotificationsPublisher() -> AnyPublisher<[NoticeModel], Never> {
        safeModelArrayPublisher { db in
            try NoticeRecord.fetchAll(db).map { $0.toModel() }
        }
    }

    func getNotifications() -> [NoticeModel] {
        do {
            return try dbQueue.read { db in
                try NoticeRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "Failed to fetch notifications: \(error)")
            return []
        }
    }

    func saveNotifications(notifications: [NoticeModel]) {
        do {
            try dbQueue.write { db in
                try db.execute(sql: "DELETE FROM \(NoticeRecord.databaseTableName)")
                for notice in notifications {
                    try NoticeRecord(from: notice).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveNotifications failed: \(error)")
        }
    }

    // MARK: - Read Notices

    func getReadNotices() -> [Int]? {
        do {
            return try dbQueue.read { db in
                try ReadNoticeRecord.fetchAll(db).map { $0.id }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getReadNotices failed: \(error)")
            return nil
        }
    }

    func getReadNoticesPublisher() -> AnyPublisher<[Int], Never> {
        safeModelArrayPublisher { db in
            try ReadNoticeRecord.fetchAll(db).map { $0.id }
        }
    }

    func saveReadNotices(readNotices: [Int]) {
        do {
            try dbQueue.write { db in
                for id in readNotices {
                    try ReadNoticeRecord(id: id).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveReadNotices failed: \(error)")
        }
    }

    // MARK: - MyIP (Deprecated — Issue #911)

    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddressPublisher() instead")
    func getIpPublisher() -> AnyPublisher<MyIP?, Never> {
        return Just(nil).eraseToAnyPublisher()
    }

    @available(*, deprecated, message: "Use Preferences.getCurrentIpAddress() instead")
    func getIp() -> MyIP? {
        return nil
    }

    @available(*, deprecated, message: "Use Preferences.saveCurrentIpAddress(ip:) instead")
    func saveIp(myip: MyIP) {
        // No-op: IP is now stored in Preferences, not the database.
    }

    // MARK: - Wifi Networks

    func getNetworksPublisher() -> AnyPublisher<[WifiNetworkModel], Never> {
        safeModelArrayPublisher { db in
            try WifiNetworkRecord.fetchAll(db).map { $0.toModel() }
        }
    }

    func getNetworks() -> [WifiNetworkModel] {
        do {
            return try dbQueue.read { db in
                try WifiNetworkRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "Failed to fetch networks: \(error)")
            return []
        }
    }

    func saveNetwork(wifiNetwork: WifiNetworkModel) {
        do {
            try dbQueue.write { db in
                try WifiNetworkRecord(from: wifiNetwork).save(db)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveNetwork failed: \(error)")
        }
    }

    func removeNetwork(wifiNetwork: WifiNetworkModel) {
        do {
            try dbQueue.write { db in
                try WifiNetworkRecord.deleteOne(db, key: wifiNetwork.SSID)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "removeNetwork failed: \(error)")
        }
    }

    // MARK: - Ping Data

    func addPingData(pingData: PingDataModel) {
        do {
            try dbQueue.write { db in
                try PingDataRecord(from: pingData).save(db)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "addPingData failed: \(error)")
        }
    }

    func getAllPingData() -> [PingDataModel] {
        do {
            return try dbQueue.read { db in
                try PingDataRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getAllPingData failed: \(error)")
            return []
        }
    }

    // MARK: - Custom Config

    func saveCustomConfig(customConfig: CustomConfigModel) {
        do {
            try dbQueue.write { db in
                try CustomConfigRecord(from: customConfig).save(db)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveCustomConfig failed: \(error)")
        }
    }

    func removeCustomConfig(fileId: String) {
        do {
            try dbQueue.write { db in
                try CustomConfigRecord.deleteOne(db, key: fileId)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "removeCustomConfig failed: \(error)")
        }
    }

    func getCustomConfigPublisher() -> AnyPublisher<[CustomConfigModel], Never> {
        safeModelArrayPublisher { db in
            try CustomConfigRecord.fetchAll(db).map { $0.toModel() }
        }
    }

    func getCustomConfigs() -> [CustomConfigModel] {
        do {
            return try dbQueue.read { db in
                try CustomConfigRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getCustomConfigs failed: \(error)")
            return []
        }
    }

    // MARK: - Robert Filters

    func getRobertFilters() -> [RobertFilterModel]? {
        do {
            return try dbQueue.read { db in
                try RobertFiltersRecord.fetchOne(db, key: "1")?.toModel()
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getRobertFilters failed: \(error)")
            return nil
        }
    }

    func saveRobertFilters(filters: [RobertFilterModel]) {
        do {
            try dbQueue.write { db in
                try RobertFiltersRecord(from: filters).save(db)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveRobertFilters failed: \(error)")
        }
    }

    func toggleRobertRule(id: String) {
        do {
            try dbQueue.write { db in
                guard var record = try RobertFiltersRecord.fetchOne(db, key: "1") else { return }
                var filters = record.toModel()
                guard let idx = filters.firstIndex(where: { $0.id == id }) else { return }
                let current = filters[idx]
                if current.status == 0 {
                    filters[idx] = RobertFilterModel(id: current.id,
                                                      title: current.title,
                                                      filterDescription: current.filterDescription,
                                                      status: 1,
                                                      enabled: true)
                } else {
                    filters[idx] = RobertFilterModel(id: current.id,
                                                      title: current.title,
                                                      filterDescription: current.filterDescription,
                                                      status: 0,
                                                      enabled: false)
                }
                record = RobertFiltersRecord(from: filters)
                try record.save(db)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "toggleRobertRule failed: \(error)")
        }
    }

    // MARK: - Favourites

    func saveFavourite(favourite: FavouriteModel) {
        do {
            try dbQueue.write { db in
                try FavouriteRecord(from: favourite).save(db)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveFavourite failed: \(error)")
        }
    }

    func getFavouriteListPublisher() -> AnyPublisher<[FavouriteModel], Never> {
        safeModelArrayPublisher { db in
            try FavouriteRecord.fetchAll(db).map { $0.toModel() }
        }
    }

    func getFavouriteList() -> [FavouriteModel] {
        do {
            return try dbQueue.read { db in
                try FavouriteRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getFavouriteList failed: \(error)")
            return []
        }
    }

    func removeFavourite(datacenterId: String) {
        do {
            try dbQueue.write { db in
                try FavouriteRecord.deleteOne(db, key: datacenterId)
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "removeFavourite failed: \(error)")
        }
    }

    // MARK: - UnblockWgParams

    func saveUnblockWgParams(params: [UnblockWgParams]) {
        do {
            try dbQueue.write { db in
                for param in params {
                    try UnblockWgParamsRecord(from: param).save(db)
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "saveUnblockWgParams failed: \(error)")
        }
    }

    func getUnblockWgParams() -> [UnblockWgParams] {
        do {
            return try dbQueue.read { db in
                try UnblockWgParamsRecord.fetchAll(db).map { $0.toModel() }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "getUnblockWgParams failed: \(error)")
            return []
        }
    }

    // MARK: - Clean

    func clean() {
        // Fire cleanSubject BEFORE deletes (matches Realm impl ordering).
        cleanSubject.send(())

        do {
            try dbQueue.write { db in
                for table in GRDBSchema.allTables {
                    try db.execute(sql: "DELETE FROM \(table)")
                }
            }
        } catch {
            logger.logE("GRDBLocalDatabaseImpl", "clean failed: \(error)")
        }
    }
}
