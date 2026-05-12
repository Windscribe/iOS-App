//
//  WireguardIPManagerTests.swift
//  WindscribeTests
//
//  Created by Anthony Wong on 2026-05-12.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import XCTest
@testable import Windscribe

class WireguardIPManagerTests: XCTestCase {

    private var sut: WireguardIPManagerImpl!

    // Stable test fixtures
    private let publicKey = "iL3y3qXmYTH1nfX/A2j0eAm0t9aFEcLOPMcz04kSxlk="
    private let v6CIDR = "fd54:0004::/64"
    private let v4CIDR = "100.64.0.0/10"

    override func setUp() {
        super.setUp()
        sut = WireguardIPManagerImpl(logger: MockLogger())
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - generateIPv6

    func test_generateIPv6_returns_non_empty_string_for_valid_inputs() throws {
        let result = try sut.generateIPv6(publicKeyBase64: publicKey, cidr: v6CIDR)
        XCTAssertFalse(result.isEmpty, "generateIPv6 must not return empty string for valid inputs (regression: TestFlight Release build returned \"\")")
    }

    func test_generateIPv6_returns_address_parseable_by_inet_pton() throws {
        let result = try sut.generateIPv6(publicKeyBase64: publicKey, cidr: v6CIDR)
        var roundTrip = in6_addr()
        XCTAssertEqual(inet_pton(AF_INET6, result, &roundTrip), 1, "Generated IPv6 \"\(result)\" must be parseable")
    }

    func test_generateIPv6_preserves_prefix() throws {
        let result = try sut.generateIPv6(publicKeyBase64: publicKey, cidr: v6CIDR)
        var parsed = in6_addr()
        XCTAssertEqual(inet_pton(AF_INET6, result, &parsed), 1)
        // First 8 bytes (network prefix for /64) must match the parsed prefix fd54:0004::
        let prefixBytes = withUnsafeBytes(of: &parsed) { Array($0.prefix(8)) }
        XCTAssertEqual(prefixBytes, [0xfd, 0x54, 0x00, 0x04, 0x00, 0x00, 0x00, 0x00])
    }

    func test_generateIPv6_is_deterministic_for_same_inputs() throws {
        let a = try sut.generateIPv6(publicKeyBase64: publicKey, cidr: v6CIDR)
        let b = try sut.generateIPv6(publicKeyBase64: publicKey, cidr: v6CIDR)
        XCTAssertEqual(a, b)
    }

    func test_generateIPv6_differs_for_different_public_keys() throws {
        let otherKey = "AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="
        let a = try sut.generateIPv6(publicKeyBase64: publicKey, cidr: v6CIDR)
        let b = try sut.generateIPv6(publicKeyBase64: otherKey, cidr: v6CIDR)
        XCTAssertNotEqual(a, b)
    }

    func test_generateIPv6_throws_for_invalid_base64() {
        XCTAssertThrowsError(try sut.generateIPv6(publicKeyBase64: "!!not-base64!!", cidr: v6CIDR))
    }

    func test_generateIPv6_throws_for_prefix_longer_than_64() {
        XCTAssertThrowsError(try sut.generateIPv6(publicKeyBase64: publicKey, cidr: "fd54:0004::/96"))
    }

    func test_generateIPv6_throws_for_missing_slash() {
        XCTAssertThrowsError(try sut.generateIPv6(publicKeyBase64: publicKey, cidr: "fd54:0004::"))
    }

    // MARK: - generateIP (sanity check that the v4 path still works)

    func test_generateIP_v4_returns_address_in_cidr() throws {
        let result = try sut.generateIP(publicKeyBase64: publicKey, cidr: v4CIDR)
        XCTAssertTrue(result.hasPrefix("100."), "Generated IP \(result) should fall inside 100.64.0.0/10")
    }
}
