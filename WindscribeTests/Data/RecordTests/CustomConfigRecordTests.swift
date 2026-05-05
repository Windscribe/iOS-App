import XCTest
import GRDB
@testable import Windscribe

final class CustomConfigRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let model = CustomConfigModel(
            id: "config-1",
            name: "My VPN",
            serverAddress: "vpn.example.com",
            protocolType: "OpenVPN",
            port: "1194",
            username: "user1",
            password: "s3cr3t",
            authRequired: true,
            saveCredentials: true
        )
        let record = CustomConfigRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try CustomConfigRecord.fetchOne(db, key: record.id) }
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
