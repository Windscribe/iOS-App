//
//  SoundManagerTests.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-04-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Swinject
@testable import Windscribe
import XCTest

class SoundManagerTests: XCTestCase {

    var soundManager: SoundManager!
    var testBundle: Bundle!
    private var mockLogger: MockLogger!

    override func setUp() {
        super.setUp()
        mockLogger = MockLogger()
        soundManager = SoundManager(logger: mockLogger)
        testBundle = Bundle(for: Self.self)
    }

    override func tearDown() {
        mockLogger = nil
        soundManager = nil
        super.tearDown()
    }

    func test_playSystemSound_shouldNotCrash() {
        soundManager.playSound(
            named: "click",
            withExtension: "caf",
            fromBundle: testBundle,
            volume: 1.0,
            style: .instant
        )

        XCTAssertTrue(true)
    }

    func test_pauseAndResume_shouldNotCrash() {
        soundManager.playSound(
            named: "click",
            withExtension: "caf",
            fromBundle: testBundle,
            volume: 1.0,
            style: .looped
        )

        soundManager.pauseSound(named: "click")
        soundManager.resumeSound(named: "click")

        XCTAssertTrue(true)
    }

    func test_playSoundWithFadeOut_shouldTrackInMock() {
        let mock = MockSoundManager()

        mock.playSound(
            named: "fadeSound",
            withExtension: "caf",
            fromBundle: .main,
            volume: 1.0,
            style: .fadeOut(after: 2.5),
            tag: nil
        )

        XCTAssertTrue(mock.fadeOutTimersTriggered.contains("fadeSound"))
    }
}
