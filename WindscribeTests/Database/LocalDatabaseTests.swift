//
//  LocalDatabaseTests.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2023-12-26.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift
import RxBlocking
import RxSwift
import Swinject
@testable import Windscribe
import XCTest

class LocalDatabaseTests: XCTestCase {
    let disposeBag = DisposeBag()
    func testMyIpSave() {
        // Setup
        let container = Container()
        let db = container.injectLocalDatabase()
        db.clean()
        let expection = expectation(description: "Waiting for getIp call to finish.")
        // Check no saved ip object found
        db.getIp().subscribe(
            onCompleted: {
                expection.fulfill()
            }
        ).disposed(by: disposeBag)
        // Save Ip object to database.
        let object = MyIP()
        let ipAddress = "192.168.0.\(String(describing: (0 ... 100).randomElement()))"
        object.userIp = ipAddress
        db.saveIp(myip: object).disposed(by: disposeBag)
        // Get saved object from database
        if let myIP = try? db.getIp().toBlocking().first(), myIP?.userIp == ipAddress {
            XCTAssert(true, "MyIP object found in database.")
        } else {
            XCTFail("Did not found MyIP object.")
        }
        // Wait for timeouts.
        waitForExpectations(timeout: 2) { _ in
        }
    }
}
