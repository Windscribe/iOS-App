import XCTest
import GRDB
@testable import Windscribe

final class UnblockWgParamsRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = UnblockWgParams(
            id: "wg-params-1",
            title: "Default",
            countries: ["US", "CA", "GB"],
            jc: 4,
            jMin: 40,
            jMax: 70,
            s1: 0,
            s2: 0,
            s3: nil,
            s4: nil,
            h1: "abc123",
            h2: nil,
            h3: nil,
            h4: nil,
            i1: "10.0.0.1",
            i2: nil,
            i3: nil,
            i4: nil,
            i5: nil
        )
        let record = UnblockWgParamsRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try UnblockWgParamsRecord.fetchOne(db, key: record.id) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
