//
//  HashAuthManagerTests.swift
//  WindscribeTests
//
//  Created by Anthony on 2026-04-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import XCTest
import CryptoKit
import Combine
@testable import Windscribe

final class HashAuthManagerTests: XCTestCase {

    var sut: HashAuthManagerImpl!
    var mockLogger: MockLogger!
    var cancellables: Set<AnyCancellable>!

    override func setUp() {
        super.setUp()
        mockLogger = MockLogger()
        sut = HashAuthManagerImpl(logger: mockLogger)
        cancellables = []
    }

    override func tearDown() {
        sut = nil
        mockLogger = nil
        cancellables = nil
        super.tearDown()
    }

    // MARK: - regenerate()

    func test_regenerate_producesValidHash() {
        let success = sut.regenerate()

        XCTAssertTrue(success)
        XCTAssertTrue(sut.accountHash.hasPrefix("0x"))
        XCTAssertEqual(sut.accountHash.count, 34) // "0x" + 32 hex chars
    }

    func test_regenerate_producesUniqueHashes() {
        sut.regenerate()
        let first = sut.accountHash

        sut.regenerate()
        let second = sut.accountHash

        XCTAssertNotEqual(first, second)
    }

    func test_regenerate_storesPreImageData() {
        sut.regenerate()

        XCTAssertEqual(sut.preImageData.count, 32)
    }

    func test_regenerate_publishesHashChange() {
        let expectation = expectation(description: "Hash published")

        sut.accountHashPublisher
            .dropFirst() // skip initial empty value
            .sink { hash in
                XCTAssertFalse(hash.isEmpty)
                expectation.fulfill()
            }
            .store(in: &cancellables)

        sut.regenerate()

        waitForExpectations(timeout: 1)
    }

    // MARK: - loadFromFile()

    func test_loadFromFile_computesCorrectHash() {
        // Known test vector: SHA256 of 32 zero bytes
        let data = Data(repeating: 0, count: 32)
        sut.loadFromFile(data)

        let expectedFullHex = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
        let expectedHash = "0x" + expectedFullHex.suffix(32)

        XCTAssertEqual(sut.accountHash, expectedHash)
    }

    func test_loadFromFile_updatesPreImageData() {
        let data = Data([1, 2, 3, 4])
        sut.loadFromFile(data)

        XCTAssertEqual(sut.preImageData, data)
    }

    // MARK: - hash(from:)

    func test_hashFrom_isDeterministic() {
        let data = Data([0xDE, 0xAD, 0xBE, 0xEF])

        let hash1 = sut.hash(from: data)
        let hash2 = sut.hash(from: data)

        XCTAssertEqual(hash1, hash2)
    }

    func test_hashFrom_matchesRegenerateOutput() {
        sut.regenerate()

        let recomputed = sut.hash(from: sut.preImageData)

        XCTAssertEqual(recomputed, sut.accountHash)
    }

    func test_hashFormat_last32CharsOfSHA256() {
        let data = Data(repeating: 0xAB, count: 32)

        let hash = sut.hash(from: data)
        let fullHex = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()

        XCTAssertEqual(hash, "0x" + fullHex.suffix(32))
        XCTAssertEqual(hash.count, 34)
        XCTAssertTrue(hash.hasPrefix("0x"))
    }

    // MARK: - copyHash()

    func test_copyHash_copiesToPasteboard() {
        sut.regenerate()
        let expectedHash = sut.accountHash

        sut.copyHash()

        XCTAssertEqual(UIPasteboard.general.string, expectedHash)
    }
}
