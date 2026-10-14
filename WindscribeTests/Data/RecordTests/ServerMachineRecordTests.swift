import XCTest
import GRDB
@testable import Windscribe

final class ServerMachineRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = ServerMachineModel(
            id:          42,
            hostname:    "ca-001.example.com",
            ip:          "10.0.0.1",
            ip2:         "10.0.0.2",
            ip3:         "10.0.0.3",
            ipv6:        0,
            datacenterId: 101,
            weight:      100,
            netLoad:     35,
            sclass:      1,
            forceDisconnect: true
        )

        let record = ServerMachineRecord(from: model)

        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in
            try ServerMachineRecord.fetchOne(db, key: record.id)
        }

        XCTAssertNotNil(fetched)
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }

    func testDecodesForceDisconnectFlagAndDefaultsMissingFlagToFalse() throws {
        let draining = try JSONDecoder().decode(
            ServerMachineModel.self,
            from: Data(#"{"id":1,"host":"draining.example.com","dc_id":10,"fd":1}"#.utf8)
        )
        let active = try JSONDecoder().decode(
            ServerMachineModel.self,
            from: Data(#"{"id":2,"host":"active.example.com","dc_id":10}"#.utf8)
        )

        XCTAssertTrue(draining.forceDisconnect)
        XCTAssertFalse(active.forceDisconnect)
        XCTAssertTrue(try JSONDecoder().decode(ServerMachineModel.self, from: JSONEncoder().encode(draining)).forceDisconnect)
    }

    func testLegacyRealmServerDefaultsForceDisconnectToFalse() {
        let legacyServer = ServerMachineObject()
        legacyServer.id = 1
        legacyServer.hostname = "legacy.example.com"

        XCTAssertFalse(ServerMachineModel(from: legacyServer).forceDisconnect)
    }

    func testV2MigrationAddsForceDisconnectDefaultToExistingServerRows() throws {
        let queue = try DatabaseQueue()
        var legacyMigrator = DatabaseMigrator()
        legacyMigrator.registerMigration("v1") { db in
            try db.create(table: Tables.serverMachine) { t in
                t.primaryKey("id", .integer).notNull()
                t.column("hostname", .text).notNull().defaults(to: "")
                t.column("ip", .text).notNull().defaults(to: "")
                t.column("ip2", .text).notNull().defaults(to: "")
                t.column("ip3", .text).notNull().defaults(to: "")
                t.column("ipv6", .integer).notNull().defaults(to: 0)
                t.column("datacenter_id", .integer).notNull().defaults(to: 0)
                t.column("weight", .integer).notNull().defaults(to: 0)
                t.column("net_load", .integer).notNull().defaults(to: 0)
                t.column("sclass", .integer).notNull().defaults(to: 0)
            }
            try db.execute(
                sql: "INSERT INTO server_machine (id, hostname, datacenter_id) VALUES (?, ?, ?)",
                arguments: [1, "legacy.example.com", 10]
            )
        }
        try legacyMigrator.migrate(queue)

        try GRDBSchema.makeMigrator().migrate(queue)

        let migrated = try queue.read { db in
            try ServerMachineRecord.fetchOne(db, key: 1)
        }
        XCTAssertFalse(migrated?.forceDisconnect ?? true)
    }
}
