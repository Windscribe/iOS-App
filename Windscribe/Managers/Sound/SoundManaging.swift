//
//  SoundManaging.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

/// Protocol used for dependency injection and mocking.
/// Adopted by `SoundManager` and mockable in tests.
protocol SoundManaging {
    func playSound(
        named name: String,
        withExtension ext: String,
        fromBundle bundle: Bundle,
        volume: Float,
        style: SoundPlayStyle,
        tag: String?
    )

    func pauseSound(named name: String)
    func resumeSound(named name: String)
    func quickPlay(named name: String, extension ext: String)
    func playCustomSound(from path: String, volume: Float, tag: String?)
    func stopAllSounds()
}
