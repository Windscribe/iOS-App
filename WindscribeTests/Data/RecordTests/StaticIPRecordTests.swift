// StaticIPRecordTests.swift
// WindscribeTests

import XCTest
import GRDB
@testable import Windscribe

final class StaticIPRecordTests: XCTestCase {

    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    func testRoundTrip() throws {
        let nodes: [NodeModel] = [
            NodeModel(ip1: "1.2.3.4", ip2: "5.6.7.8", ip3: "9.10.11.12",
                      hostname: "node1.example.com", dnsHostname: "dns1.example.com",
                      forceDisconnect: false, weight: 100),
            NodeModel(ip1: "2.3.4.5", ip2: "6.7.8.9", ip3: "10.11.12.13",
                      hostname: "node2.example.com", dnsHostname: "dns2.example.com",
                      forceDisconnect: true, weight: 50)
        ]
        let credentials: [ServerCredentialsModel] = [
            ServerCredentialsModel(username: "user1", password: "pass1"),
            ServerCredentialsModel(username: "user2", password: "pass2")
        ]
        let model = StaticIPModel(
            id: 42,
            staticIP: "203.0.113.1",
            connectIP: "203.0.113.2",
            type: "datacenter",
            name: "Test Static IP",
            countryCode: "US",
            deviceName: "My iPhone",
            cityName: "New York",
            expiry: ISO8601DateFormatter().date(from: "2025-12-31T00:00:00Z"),
            isActive: true,
            credentials: credentials,
            wgPublicKey: "abc123pubkey==",
            ovpnX509: "CN=example",
            wgIp: "10.64.0.1",
            pingHost: "ping.example.com",
            nodes: nodes
        )

        let record = StaticIPRecord(from: model)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in
            try StaticIPRecord.fetchOne(db, key: record.id)
        }
        XCTAssertNotNil(fetched)
        XCTAssertEqual(record, fetched)

        // Round-trip through toModel — verify key fields
        let roundTripped = fetched?.toModel()
        XCTAssertEqual(roundTripped?.id, model.id)
        XCTAssertEqual(roundTripped?.staticIP, model.staticIP)
        XCTAssertEqual(roundTripped?.nodes.count, model.nodes.count)
        XCTAssertEqual(roundTripped?.nodes.first?.ip1, model.nodes.first?.ip1)
        XCTAssertEqual(roundTripped?.credentials.count, model.credentials.count)
        XCTAssertEqual(roundTripped?.credentials.first?.username, model.credentials.first?.username)
        XCTAssertEqual(roundTripped?.isActive, model.isActive)
        // expiry round-trip: compare at second granularity via ISO8601
        XCTAssertEqual(roundTripped?.expiry?.timeIntervalSince1970,
                       model.expiry?.timeIntervalSince1970)
    }

    func testNilExpiry() throws {
        let model = StaticIPModel(
            id: 1,
            staticIP: "10.0.0.1",
            connectIP: "10.0.0.2",
            type: "residential",
            name: "No Expiry",
            countryCode: "CA",
            deviceName: "iPad",
            cityName: "Toronto",
            expiry: nil,
            isActive: false,
            credentials: [],
            wgPublicKey: "",
            ovpnX509: "",
            wgIp: "",
            pingHost: "",
            nodes: []
        )
        let record = StaticIPRecord(from: model)
        XCTAssertNil(record.expiry)
        let queue = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try StaticIPRecord.fetchOne(db, key: record.id) }
        XCTAssertNil(fetched?.expiry)
        XCTAssertNil(fetched?.toModel().expiry)
    }
}
