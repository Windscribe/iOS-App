//
//  CustomPlaybackManager.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-23.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

protocol CustomSoundPlaybackManaging {
    func playSound(for domain: SoundAssetDomainType)
}

class CustomSoundPlaybackManager: CustomSoundPlaybackManaging {
    private let preferences: Preferences
    private let soundManager: SoundManaging

    init(preferences: Preferences, soundManager: SoundManaging) {
        self.preferences = preferences
        self.soundManager = soundManager
    }

    /// Plays a sound effect based on the current user preferences for a given domain (e.g., connect or disconnect).
    ///
    /// This method supports three types of sound effects:
    /// - `.none`: No sound will be played.
    /// - `.bundled`: A predefined internal sound will be played using `SoundManager`.
    /// - `.custom`: A user-selected sound file will be loaded from the file system and played.
    ///
    /// The type of sound effect and any associated custom file path are retrieved from `Preferences`.
    /// Custom sounds are expected to be picked via UIDocumentPicker and stored as full file paths.
    ///
    /// - Parameter domain: The logical domain for the sound effect (e.g., `.connect`, `.disconnect`)
    func playSound(for domain: SoundAssetDomainType) {
        // Load the saved string preference for this domain
        let rawValue: String = {
            switch domain {
            case .connect:
                return preferences.getSoundEffectConnect() ?? ""
            case .disconnect:
                return preferences.getSoundEffectDisconnect() ?? ""
            }
        }()

        // Convert the raw preference value into a strongly typed SoundEffectType
        let effectType = SoundEffectType.fromRaw(value: rawValue)

        // Decide how to play based on the effect type
        switch effectType {
        case .custom:
            // Load the stored path to the custom file
            let path: String? = {
                switch domain {
                case .connect:
                    return preferences.getCustomSoundEffectPathConnect()
                case .disconnect:
                    return preferences.getCustomSoundEffectPathDisconnect()
                }
            }()

            // Play the user-provided sound file
            if let path = path {
                soundManager.stopAllSounds()
                soundManager.playCustomSound(from: path, volume: 1.0, tag: domain.tag)
            }

        case .bundled(let subtype):
            var urlAssetName = ""

            switch domain {
            case .connect:
                urlAssetName = subtype.turnOnAssetName
            case .disconnect:
               urlAssetName = subtype.turnOffAssetName
            }
            soundManager.stopAllSounds()
            // Play a bundled/internal sound asset
            soundManager.playSound(
                named: urlAssetName,
                withExtension: "m4a",
                fromBundle: .main,
                volume: 1.0,
                style: .instant,
                tag: domain.tag)

        case .none:
            //  No-op
            break
        }
    }
}
