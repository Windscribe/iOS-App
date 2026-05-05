import XCTest
import GRDB
@testable import Windscribe

final class PingDataRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = PingDataModel(ip: "10.0.0.1", latency: 42)
        let record = PingDataRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try PingDataRecord.fetchOne(db, key: record.ip) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
