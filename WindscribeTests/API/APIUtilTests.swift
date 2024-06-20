//
//  APIUtilTests.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

@testable import Windscribe
import XCTest

class APIUtilTests: XCTestCase {
    func testMyIPParsing() {
        XCTAssertNotNil(mapToSuccess(json: myIPSuccessJson, modeType: MyIP.self))
        XCTAssertTrue(mapToSuccess(json: myIPSuccessJson, modeType: MyIP.self)?.userIp == "127.0.0.1")
        if mapToAPIError(error: myIPIncorrectJson) as! Errors == Errors.parsingError {
            XCTAssertTrue(true)
        } else {
            XCTFail()
        }
        if let error = mapToAPIError(error: myIPAPIError) as? Errors{
            switch error {
            case .apiError(let apiError):
                XCTAssertTrue(apiError.errorCode == 7001)
            default:
                XCTFail()
            }
        } else {
            XCTFail()
        }
    }
}
