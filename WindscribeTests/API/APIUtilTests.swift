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

    func testSuccessfulIPMapping() {
        XCTAssertNotNil(mapToSuccess(json: myIPSuccessJson, modeType: MyIP.self))
        XCTAssertTrue(mapToSuccess(json: myIPSuccessJson, modeType: MyIP.self)?.userIp == "127.0.0.1")
    }

    func testErrorMapping() {
        if mapToAPIError(error: myIPIncorrectJson) == Errors.parsingError {
            XCTAssertTrue(true)
        } else {
            XCTFail()
        }
    }

    func testErrorCodeHandling() {
        let error = mapToAPIError(error: myIPAPIError)

        switch error {
        case let .apiError(apiError):
            XCTAssertTrue(apiError.errorCode == 7001)
        default:
            XCTFail()
        }
    }
}
