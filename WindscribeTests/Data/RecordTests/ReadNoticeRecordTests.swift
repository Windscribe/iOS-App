import XCTest
import GRDB
@testable import Windscribe

final class ReadNoticeRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let record = ReadNoticeRecord(id: 99)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try ReadNoticeRecord.fetchOne(db, key: record.id) }
        XCTAssertEqual(fetched, record)
    }

    func testToModel() throws {
        let record = ReadNoticeRecord(id: 42)
        XCTAssertEqual(record.toModel(), 42)
    }
}
