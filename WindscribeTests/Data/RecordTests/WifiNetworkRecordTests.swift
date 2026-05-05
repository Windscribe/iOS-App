import XCTest
import GRDB
@testable import Windscribe

final class WifiNetworkRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        var model = WifiNetworkModel(
            SSID: "HomeNetwork",
            status: true,
            protocolType: "WireGuard",
            port: "443",
            preferredProtocol: "WireGuard",
            preferredPort: "443",
            preferredProtocolStatus: true
        )
        model.popupDismissCount = 3
        model.dontAskAgainForPreferredProtocol = true

        let record = WifiNetworkRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try WifiNetworkRecord.fetchOne(db, key: record.ssid) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
