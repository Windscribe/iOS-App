//
//  SessionModelCodableTests.swift
//  WindscribeTests
//
//  Created by CodeScribe on 2026-04-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import XCTest
@testable import Windscribe

class SessionModelCodableTests: XCTestCase {

    /// Builds a fully-populated SessionModel so every field is exercised.
    private func makePopulatedSession() -> SessionModel {
        // Build from a MockSession (Realm object) via init(from: Session)
        let mock = MockSession()
        mock.configureLists()
        return SessionModel(from: mock)
    }

    // MARK: - Encode → Decode Roundtrip

    func testEncodeDecodeRoundtrip() throws {
        // Given
        let original = makePopulatedSession()

        // When — encode then decode
        let encoder = JSONEncoder()
        let data = try encoder.encode(original)
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(SessionModel.self, from: data)

        // Then — every persisted field must survive the trip
        XCTAssertEqual(decoded.sessionAuthHash, original.sessionAuthHash, "sessionAuthHash mismatch")
        XCTAssertEqual(decoded.username, original.username, "username mismatch")
        XCTAssertEqual(decoded.userId, original.userId, "userId mismatch")
        XCTAssertEqual(decoded.trafficUsed, original.trafficUsed, "trafficUsed mismatch")
        XCTAssertEqual(decoded.trafficMax, original.trafficMax, "trafficMax mismatch")
        XCTAssertEqual(decoded.status, original.status, "status mismatch")
        XCTAssertEqual(decoded.email, original.email, "email mismatch")
        XCTAssertEqual(decoded.emailStatus, original.emailStatus, "emailStatus mismatch")
        XCTAssertEqual(decoded.billingPlanId, original.billingPlanId, "billingPlanId mismatch")
        XCTAssertEqual(decoded.isPremium, original.isPremium, "isPremium mismatch")
        XCTAssertEqual(decoded.premiumExpiryDate, original.premiumExpiryDate, "premiumExpiryDate mismatch")
        XCTAssertEqual(decoded.regDate, original.regDate, "regDate mismatch")
        XCTAssertEqual(decoded.lastReset, original.lastReset, "lastReset mismatch")
        XCTAssertEqual(decoded.locRev, original.locRev, "locRev mismatch")
        XCTAssertEqual(decoded.locHash, original.locHash, "locHash mismatch")
        XCTAssertEqual(decoded.alc, original.alc, "alc mismatch")
        XCTAssertEqual(decoded.sipCount, original.sipCount, "sipCount mismatch")
        XCTAssertEqual(decoded.inventory, original.inventory, "inventory mismatch")
    }

    func testEncodeDecodeWithEmptyOptionals() throws {
        // Given — session with no sip counts and no inventory
        let mock = MockSession()
        // Don't call configureLists() → alc and sipCount stay empty
        var original = SessionModel(from: mock)
        // inventory is non-nil from init(from:) due to amneziawgConfigId default,
        // but sipCount should be empty
        XCTAssertTrue(original.sipCount.isEmpty, "Precondition: sipCount should be empty")
        XCTAssertTrue(original.alc.isEmpty, "Precondition: alc should be empty")

        // When
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(SessionModel.self, from: data)

        // Then
        XCTAssertEqual(decoded.sessionAuthHash, original.sessionAuthHash)
        XCTAssertEqual(decoded.sipCount, original.sipCount)
        XCTAssertEqual(decoded.alc, original.alc)
        XCTAssertEqual(decoded.inventory, original.inventory)
    }

    func testEncodedJSONHasNestedDataContainer() throws {
        // Given
        let session = makePopulatedSession()

        // When
        let data = try JSONEncoder().encode(session)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        // Then — the top-level key should be "data" (nested container)
        XCTAssertNotNil(json?["data"], "Encoded JSON should contain a 'data' wrapper key")
    }
}
