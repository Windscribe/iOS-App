//
//  SoundManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-11.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import AVFoundation
import AudioToolbox

/// Defines how a sound should behave when played.
enum SoundPlayStyle: Equatable {
    case instant
    case looped
    case fadeOut(after: TimeInterval)
}

/// Manages playback of sound effects and ambient sounds.
/// Supports:
/// - SystemSoundID for ultra-fast short sounds
/// - AVAudioPlayer for controlled playback
/// - Volume, loop, fadeOut
/// - Pause/resume
/// - Custom folder & bundle support
final class SoundManager: SoundManaging {

    internal private(set) var audioPlayers: [String: AVAudioPlayer] = [:]
    internal private(set) var systemSounds: [String: SystemSoundID] = [:]

    private var taggedPlayers: [String: AVAudioPlayer] = [:]
    private let defaultSoundFolder = "Sounds"

    let logger: FileLogger

    init (logger: FileLogger) {
        self.logger = logger

        try? AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
    }

    /// Unified sound playback interface.
    ///
    /// This method automatically chooses the appropriate playback engine based on file extension:
    /// - `.caf` or `.wav`: Uses `SystemSoundID` for ultra-fast playback (low latency, fire-and-forget)
    ///   `volume`, `style`, and `tag` will be ignored for these formats.
    /// - `.m4a`, `.mp3`, etc: Uses `AVAudioPlayer` (supports volume, loop, fade out, tag-based interruption)
    ///
    /// - Parameters:
    ///   - name: Filename (without extension)
    ///   - ext: File extension (e.g., `"caf"`, `"m4a"`). Defaults to `"caf"`.
    ///   - fromBundle: Bundle to load from (defaults to `.main`)
    ///   - volume: Playback volume for AVAudioPlayer (ignored with `.caf`/`.wav`)
    ///   - style: Playback behavior for AVAudioPlayer (`.instant`, `.looped`, `.fadeOut`)
    ///   - tag: Optional logical channel ID to prevent overlap. If set, any active sound using the same tag will be stopped before this plays.
    ///
    /// ### Example:
    /// ```
    /// soundManager.playSound(named: "click") // .caf -> SystemSoundID
    /// soundManager.playSound(named: "success", withExtension: "m4a", volume: 1.0)
    /// soundManager.playSound(named: "turnOn", withExtension: "m4a", tag: "vpnState") // Stops previous "vpnState" sound
    /// ```
    func playSound(
        named name: String,
        withExtension ext: String = "caf",
        fromBundle bundle: Bundle = .main,
        volume: Float = 1.0,
        style: SoundPlayStyle = .instant,
        tag: String? = nil
    ) {
        let lowercasedExt = ext.lowercased()
        let shouldUseSystemSound = ["caf", "wav"].contains(lowercasedExt)

        if shouldUseSystemSound {
            playSystemSoundInternal(named: name, withExtension: ext, fromBundle: bundle)
        } else {
            playAudioPlayerSoundInternal(
                named: name,
                withExtension: ext,
                fromBundle: bundle,
                volume: volume,
                style: style,
                tag: tag
            )
        }
    }

    /// Plays a custom sound file located at the specified file system path.
    ///
    /// This method uses `AVAudioPlayer` to play audio from a user-selected file, such as one picked via a file picker.
    /// It supports optional tagging to avoid overlapping playback of logically grouped sounds.
    ///
    /// - Parameters:
    ///   - path: Full file path to the audio file.
    ///   - volume: Playback volume (default is `1.0`).
    ///   - tag: Optional logical channel ID. If set, any currently playing sound with the same tag will be stopped before this plays.
    ///
    /// ### Example:
    /// ```
    /// soundManager.playCustomSound(from: "/User/sounds/welcome.mp3", tag: "vpnState")
    /// ```
    func playCustomSound(from path: String, volume: Float = 1.0, tag: String? = nil) {
        let cacheKey = path

        // Stop tagged player if needed
        if let tag = tag, let existing = taggedPlayers[tag] {
            existing.stop()
            taggedPlayers.removeValue(forKey: tag)
        }

        let url = URL(fileURLWithPath: path)

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            player.play()

            if let tag = tag {
                taggedPlayers[tag] = player
            } else {
                audioPlayers[cacheKey] = player
            }

        } catch {
            logger.logE("SoundManager", "Failed to play custom sound from path: \(path), error: \(error.localizedDescription)")
        }
    }

    func quickPlay(named name: String, extension ext: String = "caf") {
        playSound(named: name, withExtension: ext, volume: 1.0, style: .instant)
    }

    func pauseSound(named name: String) {
        guard let player = audioPlayers[name], player.isPlaying else { return }
        player.pause()
    }

    func resumeSound(named name: String) {
        guard let player = audioPlayers[name], !player.isPlaying else { return }
        player.play()
    }

    // SystemSoundID

    private func playSystemSoundInternal(
        named name: String,
        withExtension ext: String,
        fromBundle bundle: Bundle
    ) {
        let cacheKey = "\(name).\(ext)"

        if let soundID = systemSounds[cacheKey] {
            AudioServicesPlaySystemSound(soundID)
            return
        }

        // 💡 Use subdirectory: "Sounds" since we are storing files in a real folder reference
        guard let soundURL = bundle.url(forResource: name, withExtension: ext, subdirectory: defaultSoundFolder) else {
            logger.logE("SoundManager", "Sound file not found in Sounds/: \(name).\(ext)")
            return
        }

        var soundID: SystemSoundID = 0
        AudioServicesCreateSystemSoundID(soundURL as CFURL, &soundID)
        systemSounds[cacheKey] = soundID
        AudioServicesPlaySystemSound(soundID)
    }

    // AVAudioPlayer

    private func playAudioPlayerSoundInternal(
        named name: String,
        withExtension ext: String,
        fromBundle bundle: Bundle,
        volume: Float,
        style: SoundPlayStyle,
        tag: String?
    ) {
        let cacheKey = "\(name).\(ext)"

        // Stop and clean up existing tagged player
        if let tag = tag, let existing = taggedPlayers[tag] {
            existing.stop()
            taggedPlayers.removeValue(forKey: tag)
        }

        guard let soundURL = bundle.url(forResource: name, withExtension: ext, subdirectory: defaultSoundFolder) else {
            logger.logE("SoundManager", "Sound file not found in Sounds/: \(name).\(ext)")
            return
        }

        do {
            let player = try AVAudioPlayer(contentsOf: soundURL)
            player.volume = volume
            player.numberOfLoops = (style == .looped) ? -1 : 0
            player.prepareToPlay()
            player.play()

            if let tag = tag {
                taggedPlayers[tag] = player
            } else {
                audioPlayers[cacheKey] = player
            }

            if case let .fadeOut(after) = style {
                DispatchQueue.main.asyncAfter(deadline: .now() + after) {
                    if let tag = tag {
                        self.fadeOutAndRemoveTagged(tag: tag)
                    } else {
                        self.fadeOutSound(named: cacheKey)
                    }
                }
            }

        } catch {
            logger.logE("SoundManager", "AVAudioPlayer Error: \(error.localizedDescription)")
        }
    }

    // Fade Out

    private func fadeOutSound(named name: String, duration: TimeInterval = 1.0) {
        guard let player = audioPlayers[name], player.isPlaying else { return }

        let fadeSteps = 25
        let delay = duration / Double(fadeSteps)
        let volumeStep = player.volume / Float(fadeSteps)

        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * Double(i)) {
                player.volume = max(player.volume - volumeStep, 0.0)
                if player.volume <= 0.01 {
                    player.stop()
                    self.audioPlayers.removeValue(forKey: name)
                }
            }
        }
    }

    private func fadeOutAndRemoveTagged(tag: String, duration: TimeInterval = 1.0) {
        guard let player = taggedPlayers[tag], player.isPlaying else { return }

        let fadeSteps = 25
        let delay = duration / Double(fadeSteps)
        let volumeStep = player.volume / Float(fadeSteps)

        for i in 0..<fadeSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + delay * Double(i)) {
                player.volume = max(player.volume - volumeStep, 0.0)
                if player.volume <= 0.01 {
                    player.stop()
                    self.taggedPlayers.removeValue(forKey: tag)
                }
            }
        }
    }
}
