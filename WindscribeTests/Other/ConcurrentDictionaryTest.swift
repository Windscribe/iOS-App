//
//  ConcurrentDictionaryTest.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2022-12-21.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe
import XCTest

class ConcurrentDictionaryTest: XCTestCase {
    func testConcurrentWriteAndRead() {
        let dispatchQueue = DispatchQueue(label: "concurrent", attributes: .concurrent)
        let promise = expectation(description: "Multiple threads can access dictionary at the same time.")
        let dictionary = ConcurrentDictionary<String, Int>()
        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()
        dispatchQueue.async {
            for i in 0 ... 100_000 {
                dictionary["\(i)"] = i
            }
            dispatchGroup.leave()
        }
        dispatchGroup.enter()
        dispatchQueue.async {
            for i in 0 ... 1000 {
                guard let _ = dictionary["\(i)"] else {
                    continue
                }
            }
            dispatchGroup.leave()
        }
        dispatchGroup.notify(queue: .main) {
            promise.fulfill()
        }
        waitForExpectations(timeout: 3, handler: nil)
    }
}
