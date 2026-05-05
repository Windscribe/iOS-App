import XCTest
import GRDB
@testable import Windscribe

final class SuggestedPortsRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = SuggestedPortsModel(protocolType: "WireGuard", port: "443")
        let record = SuggestedPortsRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try SuggestedPortsRecord.fetchOne(db, key: record.id) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
