//
//  MockSoundManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-04-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

/// Test double for SoundManager used in unit tests.
class MockSoundManager: SoundManaging {
    private(set) var playedSounds: [(name: String, style: SoundPlayStyle?, tag: String?)] = []
    private(set) var pausedSounds: [String] = []
    private(set) var resumedSounds: [String] = []
    private(set) var fadeOutTimersTriggered: [String] = []

    func playSound(
        named name: String,
        withExtension ext: String,
        fromBundle bundle: Bundle,
        volume: Float,
        style: SoundPlayStyle,
        tag: String?
    ) {
        playedSounds.append((name: name, style: style, tag: tag))

        if case .fadeOut = style {
            fadeOutTimersTriggered.append(name)
        }
    }

    func pauseSound(named name: String) {
        pausedSounds.append(name)
    }

    func resumeSound(named name: String) {
        resumedSounds.append(name)
    }

    func quickPlay(named name: String, extension ext: String) {
        playedSounds.append((name: name, style: nil, tag: nil))
    }

    func playCustomSound(from path: String, volume: Float, tag: String?) {
        playedSounds.append((name: path, style: nil, tag: tag))
    }

    func stopAllSounds() {
        playedSounds.removeAll()
        pausedSounds.removeAll()
        resumedSounds.removeAll()
        fadeOutTimersTriggered.removeAll()
    }
}
