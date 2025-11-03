//
//  SampleDataNotifications.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

class SampleDataNotifications {
    static let notificationListJSON = """
    {
        "data": {
            "notifications": [
                {
                    "id": 1,
                    "title": "Welcome to Windscribe",
                    "message": "Thank you for joining Windscribe VPN!",
                    "date": 1697530800,
                    "popup": 1,
                    "perm_free": 1,
                    "perm_pro": 1
                },
                {
                    "id": 2,
                    "title": "Special Offer",
                    "message": "Get 50% off Pro plan",
                    "date": 1697534400,
                    "popup": 0,
                    "perm_free": 1,
                    "perm_pro": 0,
                    "action": {
                        "type": "promo",
                        "pcpid": "promo123",
                        "promo_code": "SAVE50",
                        "label": "Get Offer"
                    }
                },
                {
                    "id": 3,
                    "title": "Server Maintenance",
                    "message": "Scheduled maintenance on October 20",
                    "date": 1697538000,
                    "popup": 0,
                    "perm_free": 1,
                    "perm_pro": 1
                }
            ]
        }
    }
    """

    static let singleNotificationListJSON = """
    {
        "data": {
            "notifications": [
                {
                    "id": 1,
                    "title": "Test Notification",
                    "message": "This is a test notification",
                    "date": 1697530800,
                    "popup": 0,
                    "perm_free": 1,
                    "perm_pro": 1
                }
            ]
        }
    }
    """

    static let emptyNotificationListJSON = """
    {
        "data": {
            "notifications": []
        }
    }
    """

    static let notificationWithPcpidJSON = """
    {
        "data": {
            "notifications": [
                {
                    "id": 100,
                    "title": "Promo Notification",
                    "message": "Special offer with pcpid",
                    "date": 1697530800,
                    "popup": 1,
                    "perm_free": 1,
                    "perm_pro": 0,
                    "action": {
                        "type": "promo",
                        "pcpid": "test-pcpid-123",
                        "promo_code": "TESTCODE",
                        "label": "Claim Now"
                    }
                }
            ]
        }
    }
    """
}
