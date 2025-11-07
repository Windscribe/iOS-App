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

        let expectation = expectation(description: "Waiting for IP to be saved and retrieved.")

        // Save IP object to database
        let ipAddress = "192.168.0.\(String(describing: (0 ... 100).randomElement()))"
        let object = MyIP()
        object.userIp = ipAddress

        // Trigger save first
        localDatabase.saveIp(myip: object).disposed(by: disposeBag)

        // Use DispatchQueue.main.async to ensure save is queued before subscribe
        // This ensures the object exists when getRealmObservable checks
        DispatchQueue.main.async {
            self.localDatabase.getIp()
                .take(1)
                .subscribe(
                    onNext: { myIP in
                        XCTAssertNotNil(myIP, "MyIP object should not be nil after save")
                        XCTAssertEqual(myIP?.userIp, ipAddress, "MyIP object found in database with correct IP.")
                        expectation.fulfill()
                    },
                    onError: { error in
                        XCTFail("Error retrieving MyIP: \(error)")
                        expectation.fulfill()
                    }
                ).disposed(by: self.disposeBag)
        }

        // Wait for expectations
        waitForExpectations(timeout: 2) { _ in }
    }
}
