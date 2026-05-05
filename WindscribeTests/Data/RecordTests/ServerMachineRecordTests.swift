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
            sclass:      1
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
}
