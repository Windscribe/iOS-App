//
//  SessionRecoverySourceTests.swift
//  WindscribeTests
//
//  Created by Andre Fonseca on 03/09/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
@testable import Windscribe

final class SessionRecoverySourceTests: XCTestCase {
    func testAppLifecycleRetriesSessionWithoutVPNRecovery() {
        XCTAssertTrue(SessionRecoverySource.appLifecycle.retriesSessionWithoutVPNRecovery)
    }

    func testSessionUpdateFailureDoesNotRetryWithoutVPNRecovery() {
        XCTAssertFalse(SessionRecoverySource.sessionUpdateFailure.retriesSessionWithoutVPNRecovery)
    }
}
