import XCTest
import GRDB
@testable import Windscribe

final class FavouriteRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = FavouriteModel(
            id: "dc-123",
            pinnedIp: "192.168.1.1",
            pinnedNodeHostname: "hostname.example.com"
        )
        let record = FavouriteRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try FavouriteRecord.fetchOne(db, key: record.id) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }

    func testRoundTripNilFields() throws {
        let model = FavouriteModel(id: "dc-456", pinnedIp: nil, pinnedNodeHostname: nil)
        let record = FavouriteRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try FavouriteRecord.fetchOne(db, key: record.id) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
