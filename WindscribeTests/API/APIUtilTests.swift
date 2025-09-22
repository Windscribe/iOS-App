//
//  APIUtilTests.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class APIUtilTests: XCTestCase {

    var mockContainer: Container!

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockContainer.register(APIUtilService.self) { _ in
            return APIUtilServiceImpl()
        }.inObjectScope(.container)
    }

    override func tearDown() {
        mockContainer = nil
        super.tearDown()
    }

    func testSuccessfulIPMapping() {
        let apiUtilService = mockContainer.resolve(APIUtilService.self)!
        XCTAssertNotNil(apiUtilService.mapToSuccess(json: myIPSuccessJson, modeType: MyIP.self))
        XCTAssertTrue(apiUtilService.mapToSuccess(json: myIPSuccessJson, modeType: MyIP.self)?.userIp == "127.0.0.1")
    }

    func testErrorMapping() {
        let apiUtilService = mockContainer.resolve(APIUtilService.self)!
        if apiUtilService.mapToAPIError(error: myIPIncorrectJson) == Errors.parsingError {
            XCTAssertTrue(true)
        } else {
            XCTFail()
        }
    }

    func testErrorCodeHandling() {
        let apiUtilService = mockContainer.resolve(APIUtilService.self)!
        let error = apiUtilService.mapToAPIError(error: myIPAPIError)

        switch error {
        case let .apiError(apiError):
            XCTAssertTrue(apiError.errorCode == 7001)
        default:
            XCTFail()
        }
    }
}
