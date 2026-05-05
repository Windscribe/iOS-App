// NoticeRecordTests.swift
// WindscribeTests

import XCTest
import GRDB
@testable import Windscribe

final class NoticeRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTripWithAction() throws {
        let action = NoticeActionModel(
            type: "upgrade",
            pcpid: "plan_abc",
            promoCode: "SAVE20",
            label: "Upgrade Now"
        )
        let model = NoticeModel(
            id: 7,
            title: "Special Offer",
            message: "Get 20% off Pro today!",
            date: 1_700_000_000,
            popup: true,
            action: action
        )

        let record = NoticeRecord(from: model)
        XCTAssertFalse(record.permFree)
        XCTAssertFalse(record.permPro)
        XCTAssertNotNil(record.actionJson)

        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in
            try NoticeRecord.fetchOne(db, key: record.id)
        }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(record, fetched)

        let roundTripped = fetched?.toModel()
        XCTAssertEqual(roundTripped?.id, model.id)
        XCTAssertEqual(roundTripped?.title, model.title)
        XCTAssertEqual(roundTripped?.message, model.message)
        XCTAssertEqual(roundTripped?.date, model.date)
        XCTAssertEqual(roundTripped?.popup, model.popup)
        XCTAssertEqual(roundTripped?.action?.type, action.type)
        XCTAssertEqual(roundTripped?.action?.pcpid, action.pcpid)
        XCTAssertEqual(roundTripped?.action?.promoCode, action.promoCode)
        XCTAssertEqual(roundTripped?.action?.label, action.label)
    }

    func testRoundTripWithoutAction() throws {
        let model = NoticeModel(
            id: 99,
            title: "Maintenance",
            message: "Servers will restart tonight.",
            date: 1_710_000_000,
            popup: false,
            action: nil
        )

        let record = NoticeRecord(from: model)
        XCTAssertNil(record.actionJson)

        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in
            try NoticeRecord.fetchOne(db, key: record.id)
        }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(record, fetched)
        XCTAssertNil(fetched?.toModel().action)
    }
}
