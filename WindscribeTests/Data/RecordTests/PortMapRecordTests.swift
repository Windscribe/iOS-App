import XCTest
import GRDB
@testable import Windscribe

final class PortMapRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = PortMapModel(
            connectionProtocol: "WireGuard",
            heading: "WireGuard UDP",
            use: "wg",
            ports: ["443", "1194", "8443"],
            legacyPorts: ["1701", "500"]
        )
        let record = PortMapRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try PortMapRecord.fetchOne(db, key: record.connectionProtocol) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
