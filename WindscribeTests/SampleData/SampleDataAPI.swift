//
//  SampleDataAPI.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

let myIPSuccessJson = """
{
    "data": {
        "user_ip": "127.0.0.1",
        "our_ip": 1
    }
}
"""

let myIPAPIError = """
{
        "errorCode": 7001,
        "errorMessage": "Error message"
}
"""

let myIPIncorrectJson = """
{
    "data": {
        "user_ip_1": "",
        "our_ip: 1
    }
}
"""
