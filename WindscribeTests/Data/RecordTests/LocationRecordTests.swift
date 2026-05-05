import XCTest
import GRDB
@testable import Windscribe

final class LocationRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let dc1 = DatacenterModel(
            id:         101,
            city:       "Toronto",
            nick:       "YYZ",
            iata:       "YYZ",
            status:     0,
            gps:        "43.65,-79.38",
            tz:         "America/Toronto",
            p2p:        1,
            isPremium:  0,
            wgPubkey:   "pubkey-abc",
            wgEndpoint: "1.2.3.4:51820",
            ovpnX509:   "x509-abc",
            linkSpeed:  1000
        )
        let dc2 = DatacenterModel(
            id:         102,
            city:       "Vancouver",
            nick:       "YVR",
            iata:       "YVR",
            status:     0,
            gps:        "49.24,-123.11",
            tz:         "America/Vancouver",
            p2p:        0,
            isPremium:  1,
            wgPubkey:   "pubkey-def",
            wgEndpoint: "5.6.7.8:51820",
            ovpnX509:   "x509-def",
            linkSpeed:  500
        )

        let model = LocationModel(
            id:          1,
            name:        "Canada",
            countryCode: "CA",
            shortName:   "Canada",
            sortOrder:   0,
            continent:   "North America",
            datacenters: [dc1, dc2]
        )

        let record = LocationRecord(from: model)

        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in
            try LocationRecord.fetchOne(db, key: record.id)
        }

        XCTAssertNotNil(fetched)
        XCTAssertEqual(record, fetched)
        XCTAssertEqual(fetched?.toModel(), model)
    }
}
