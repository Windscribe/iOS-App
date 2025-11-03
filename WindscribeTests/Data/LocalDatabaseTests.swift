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

    var mockContainer: Container!
    var localDatabase: LocalDatabase!
    var mockLogger: MockLogger!
    var mockPreferences: MockPreferences!

    let disposeBag = DisposeBag()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockLogger = MockLogger()
        mockPreferences = MockPreferences()

        // Register mock logger
        mockContainer.register(FileLogger.self) { _ in
            return self.mockLogger
        }

        // Register mock preferences
        mockContainer.register(Preferences.self) { _ in
            return self.mockPreferences
        }

        // Register mock LocalDatabase for unit tests
        mockContainer.register(LocalDatabase.self) { _ in
            LocalDatabaseImpl(
                logger: FileLoggerImpl(),
                preferences: PreferencesImpl(logger: FileLoggerImpl()))
        }.inObjectScope(.container)

        localDatabase = mockContainer.resolve(LocalDatabase.self)!
    }

    override func tearDown() {
        localDatabase.clean()
        mockContainer = nil
        localDatabase = nil
        mockLogger = nil
        mockPreferences = nil
        super.tearDown()
    }

    func testMyIpSave() {
        localDatabase.clean()

        let expection = expectation(description: "Waiting for getIp call to finish.")
        // Check no saved ip object found
        localDatabase.getIp().subscribe(
            onCompleted: {
                expection.fulfill()
            }
        ).disposed(by: disposeBag)

        // Save Ip object to database.
        let ipAddress = "192.168.0.\(String(describing: (0 ... 100).randomElement()))"
        let object = MyIP()
        object.userIp = ipAddress
        localDatabase.saveIp(myip: object).disposed(by: disposeBag)

        // Get saved object from database
        if let myIP = try? localDatabase.getIp().toBlocking().first(), myIP?.userIp == ipAddress {
            XCTAssert(true, "MyIP object found in database.")
        } else {
            XCTFail("Did not found MyIP object.")
        }

        // Wait for timeouts.
        waitForExpectations(timeout: 2) { _ in }
    }
}
