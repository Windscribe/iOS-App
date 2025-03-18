//
//  PreferencesTests.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-25.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxBlocking
import Swinject
@testable import Windscribe
import XCTest

class PreferencesTests: XCTestCase {

    var mockContainer: Container!

    override func setUp() {
        super.setUp()
        mockContainer = Container()

    }

    override func tearDown() {
        mockContainer = nil
        super.tearDown()
    }

    func testSaveAdvanceParams() {
        let preferences = mockContainer.injectPreferences()
        preferences.saveAdvanceParams(params: advanceParams)

        if let params = try? preferences.getAdvanceParams().toBlocking().first() {
            XCTAssertTrue(params == advanceParams)
        } else {
            XCTFail()
        }
        preferences.saveAdvanceParams(params: "")
    }
}
