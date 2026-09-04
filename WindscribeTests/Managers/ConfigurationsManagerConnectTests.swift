//
//  ConfigurationsManagerConnectTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 26/08/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
import NetworkExtension
@testable import Windscribe

final class DisconnectErrorFetchTrackerTests: XCTestCase {
    func testDoesNotFetchBeforeConnectionTransitionsToDisconnected() {
        var tracker = DisconnectErrorFetchTracker()

        XCTAssertFalse(tracker.shouldFetch(for: .disconnected))
        XCTAssertFalse(tracker.shouldFetch(for: .connecting))
        XCTAssertFalse(tracker.shouldFetch(for: .connected))
    }

    func testFetchesWhenConnectionTransitionsToDisconnected() {
        var tracker = DisconnectErrorFetchTracker()

        XCTAssertFalse(tracker.shouldFetch(for: .connecting))
        XCTAssertTrue(tracker.shouldFetch(for: .disconnected))
    }

    func testFetchesOnlyOncePerConnectionAttempt() {
        var tracker = DisconnectErrorFetchTracker()

        XCTAssertFalse(tracker.shouldFetch(for: .connecting))
        XCTAssertTrue(tracker.shouldFetch(for: .disconnected))
        XCTAssertFalse(tracker.shouldFetch(for: .connecting))
        XCTAssertFalse(tracker.shouldFetch(for: .disconnected))
    }
}
