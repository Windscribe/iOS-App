//
//  StringRedactedTests.swift
//  WindscribeTests
//
//  Created by Codescribe on 2026-04-24.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
@testable import Windscribe

final class StringRedactedTests: XCTestCase {

    // MARK: - Edge Cases

    func testEmptyString() {
        XCTAssertEqual("".redacted, "")
    }

    func testSingleCharacter() {
        XCTAssertEqual("a".redacted, "*")
        XCTAssertEqual("X".redacted, "*")
    }

    func testTwoCharacters() {
        XCTAssertEqual("ab".redacted, "a*")
        XCTAssertEqual("XY".redacted, "X*")
    }

    func testThreeCharacters() {
        XCTAssertEqual("abc".redacted, "a*c")
        XCTAssertEqual("XYZ".redacted, "X*Z")
    }

    // MARK: - Short Strings (4–10 characters)

    func testFourCharacters() {
        // sideLength = min(5, (4-1)/2) = 1, hidden = 4 - 2 = 2, asterisks = min(2,5) = 2
        XCTAssertEqual("abcd".redacted, "a**d")
    }

    func testFiveCharacters() {
        // sideLength = min(5, (5-1)/2) = 2, hidden = 5 - 4 = 1, asterisks = 1
        XCTAssertEqual("abcde".redacted, "ab*de")
    }

    func testSixCharacters() {
        // sideLength = min(5, (6-1)/2) = 2, hidden = 6 - 4 = 2, asterisks = 2
        XCTAssertEqual("abcdef".redacted, "ab**ef")
    }

    func testEightCharacters() {
        // sideLength = min(5, (8-1)/2) = 3, hidden = 8 - 6 = 2, asterisks = 2
        XCTAssertEqual("abcdefgh".redacted, "abc**fgh")
    }

    func testTenCharacters() {
        // sideLength = min(5, (10-1)/2) = 4, hidden = 10 - 8 = 2, asterisks = 2
        XCTAssertEqual("abcdefghij".redacted, "abcd**ghij")
    }

    // MARK: - Medium Strings (11–15 characters)

    func testElevenCharacters() {
        // sideLength = min(5, (11-1)/2) = 5, hidden = 11 - 10 = 1, asterisks = 1
        XCTAssertEqual("abcdefghijk".redacted, "abcde*ghijk")
    }

    func testTwelveCharacters() {
        // sideLength = min(5, (12-1)/2) = 5, hidden = 12 - 10 = 2, asterisks = 2
        XCTAssertEqual("abcdefghijkl".redacted, "abcde**hijkl")
    }

    func testFifteenCharacters() {
        // sideLength = min(5, (15-1)/2) = 5, hidden = 15 - 10 = 5, asterisks = 5
        XCTAssertEqual("abcdefghijklmno".redacted, "abcde*****klmno")
    }

    // MARK: - Long Strings (asterisks capped at 5)

    func testTwentyCharacters() {
        // sideLength = 5, hidden = 20 - 10 = 10, asterisks = min(10,5) = 5
        XCTAssertEqual("abcdefghijklmnopqrst".redacted, "abcde*****pqrst")
    }

    func testFiftyCharacters() {
        let input = String(repeating: "x", count: 50)
        let result = input.redacted
        // sideLength = 5, asterisks = 5
        XCTAssertEqual(result, "xxxxx*****xxxxx")
    }

    // MARK: - Realistic Token Strings

    func testRealisticAuthToken() {
        let token = "a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6"
        let result = token.redacted
        XCTAssertEqual(result, "a1b2c*****4o5p6")
    }

    func testRealisticPushToken() {
        let token = "AABBCCDD11223344EEFFGGHH55667788"
        let result = token.redacted
        XCTAssertEqual(result, "AABBC*****67788")
    }

    // MARK: - Symmetry

    func testPrefixAndSuffixLengthsAreEqual() {
        for length in 4...100 {
            let input = String(repeating: "a", count: length)
            let result = input.redacted

            // Strip the asterisks from the middle
            let firstStar = result.firstIndex(of: "*")!
            let lastStar = result.lastIndex(of: "*")!
            let prefixLen = result.distance(from: result.startIndex, to: firstStar)
            let suffixLen = result.distance(from: result.index(after: lastStar), to: result.endIndex)
            XCTAssertEqual(prefixLen, suffixLen, "Prefix and suffix lengths should be equal for input length \(length)")
        }
    }

    func testAsterisksNeverExceedFive() {
        for length in 4...100 {
            let input = String(repeating: "z", count: length)
            let result = input.redacted
            let starCount = result.filter { $0 == "*" }.count
            XCTAssertLessThanOrEqual(starCount, 5, "Asterisk count should not exceed 5 for input length \(length)")
        }
    }

    func testOriginalStringNeverFullyRevealed() {
        for length in 1...100 {
            let input = String(repeating: "a", count: length)
            let result = input.redacted
            XCTAssertTrue(result.contains("*"), "Redacted output should always contain at least one asterisk for length \(length)")
        }
    }
}
