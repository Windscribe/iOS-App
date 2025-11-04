//
//  SampleDataMobilePlan.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-20.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class SampleDataMobilePlan {
    static let mobilePlanListJSON = """
    {
        "data": {
            "plans": [
                {
                    "active": 1,
                    "ext_id": "com.windscribe.ios.1year",
                    "name": "Pro 1 Year",
                    "price": "$49.00",
                    "type": "subscription",
                    "ws_plan_id": "yearly",
                    "duration": 12,
                    "discount": -1
                },
                {
                    "active": 1,
                    "ext_id": "com.windscribe.ios.1month",
                    "name": "Pro 1 Month",
                    "price": "$9.00",
                    "type": "subscription",
                    "ws_plan_id": "monthly",
                    "duration": 1,
                    "discount": -1
                },
                {
                    "active": 1,
                    "ext_id": "com.windscribe.ios.3month",
                    "name": "Pro 3 Months",
                    "price": "$24.00",
                    "type": "subscription",
                    "ws_plan_id": "3months",
                    "duration": 3,
                    "discount": -1
                }
            ]
        }
    }
    """

    static let discountedMobilePlanListJSON = """
    {
        "data": {
            "plans": [
                {
                    "active": 1,
                    "ext_id": "com.windscribe.ios.1year.promo",
                    "name": "Pro 1 Year (50% Off)",
                    "price": "$24.50",
                    "type": "subscription",
                    "ws_plan_id": "yearly_promo",
                    "duration": 12,
                    "discount": 50
                },
                {
                    "active": 1,
                    "ext_id": "com.windscribe.ios.1month",
                    "name": "Pro 1 Month",
                    "price": "$9.00",
                    "type": "subscription",
                    "ws_plan_id": "monthly",
                    "duration": 1,
                    "discount": -1
                }
            ]
        }
    }
    """

    static let singleMobilePlanListJSON = """
    {
        "data": {
            "plans": [
                {
                    "active": 1,
                    "ext_id": "com.windscribe.ios.1year",
                    "name": "Pro 1 Year",
                    "price": "$49.00",
                    "type": "subscription",
                    "ws_plan_id": "yearly",
                    "duration": 12,
                    "discount": -1
                }
            ]
        }
    }
    """

    static let emptyMobilePlanListJSON = """
    {
        "data": {
            "plans": []
        }
    }
    """
}
