// RobertFiltersRecordTests.swift
// WindscribeTests

import XCTest
import GRDB
@testable import Windscribe

final class RobertFiltersRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let filters: [RobertFilterModel] = [
            RobertFilterModel(id: "malware",
                              title: "Malware",
                              filterDescription: "Blocks known malware domains",
                              status: 1,
                              enabled: true),
            RobertFilterModel(id: "ads",
                              title: "Ads",
                              filterDescription: "Blocks ad networks",
                              status: 0,
                              enabled: false),
            RobertFilterModel(id: "tracking",
                              title: "Tracking",
                              filterDescription: "Blocks tracking pixels",
                              status: 1,
                              enabled: true)
        ]

        let record = RobertFiltersRecord(from: filters)
        XCTAssertEqual(record.id, "1")

        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in
            try RobertFiltersRecord.fetchOne(db, key: record.id)
        }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(record, fetched)

        let roundTripped = fetched?.toModel() ?? []
        XCTAssertEqual(roundTripped.count, filters.count)
        XCTAssertEqual(roundTripped, filters)
    }

    func testEmptyFilters() throws {
        let record = RobertFiltersRecord(from: [])
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in
            try RobertFiltersRecord.fetchOne(db, key: "1")
        }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(fetched?.toModel(), [])
    }
}
