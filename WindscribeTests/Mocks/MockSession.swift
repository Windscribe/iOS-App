//
//  MockSession.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-02-12.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockSession: Session {
    override init() {
        super.init()
        self.sessionAuthHash = "mockSessionAuthHash"
        self.username = "mockUsername"
        self.userId = "mockUserId"
        self.trafficUsed = 2 * 1024 * 1024 * 1024 // Default 2GB used
        self.trafficMax = 10 * 1024 * 1024 * 1024 // 10GB max
        self.status = 1
        self.email = "mock@example.com"
        self.emailStatus = true
        self.billingPlanId = -9
        self.isPremium = true
        self.premiumExpiryDate = "2099-12-31"
        self.regDate = 1672531200
        self.lastReset = "2024-01-01"
        self.locRev = 5
        self.locHash = "mockLocHash"
    }

    func configureLists() {
        self.alc.append(objectsIn: ["mockALC1", "mockALC2"])
        let mockSip = SipCount()
        mockSip.countNumber = 42
        self.sipCount.append(mockSip)
    }
}

class MockSipCount: SipCount {
    override init() {
        super.init()
        self.countNumber = 42
    }
}

