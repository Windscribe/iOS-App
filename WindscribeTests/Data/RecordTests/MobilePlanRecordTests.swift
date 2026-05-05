import XCTest
import GRDB
@testable import Windscribe

final class MobilePlanRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = MobilePlanModel(
            active: true,
            extId: "plan-monthly-pro",
            name: "Pro Monthly",
            price: "$9.99",
            type: "subscription",
            duration: 30,
            discount: 0
        )
        let record = MobilePlanRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try MobilePlanRecord.fetchOne(db, key: record.extId) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
