//
//  PreferencesImpl+LookAndFeel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-09-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

extension PreferencesImpl {
    // Aspect Ratio
    func saveAspectRatio(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.aspectRatio)
    }

    func getAspectRatio() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.aspectRatio)
    }

    func aspectRatio() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.aspectRatio, type: String.self)
    }

    // Sounds
    func saveSoundEffectConnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.connectSoundEffect)
    }

    func getSoundEffectConnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.connectSoundEffect)
    }

    func saveSoundEffectDisconnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.disconnectSoundEffect)
    }

    func getSoundEffectDisconnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.disconnectSoundEffect)
    }

    func saveCustomSoundEffectPathConnect(_ path: String) {
        sharedDefault?.set(path, forKey: SharedKeys.customSoundEffectPathConnect)
    }

    func saveCustomSoundEffectPathDisconnect(_ path: String) {
        sharedDefault?.set(path, forKey: SharedKeys.customSoundEffectPathDisconnect)
    }

    func getCustomSoundEffectPathConnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.customSoundEffectPathConnect)
    }

    func getCustomSoundEffectPathDisconnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.customSoundEffectPathDisconnect)
    }

    // Backgrounds
    func saveBackgroundEffectConnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.connectBackgroundEffect)
    }

    func getBackgroundEffectConnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.connectBackgroundEffect)
    }

    func backgroundEffectConnect() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.connectBackgroundEffect, type: String.self)
    }

    func saveBackgroundCustomConnectPath(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.connectBackgroundCustomPath)
    }

    func getBackgroundCustomConnectPath() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.connectBackgroundCustomPath)
    }

    func backgroundCustomConnectPath() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.connectBackgroundCustomPath, type: String.self)
    }

    func saveBackgroundEffectDisconnect(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.disconnectBackgroundEffect)
    }

    func getBackgroundEffectDisconnect() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.disconnectBackgroundEffect)
    }

    func backgroundEffectDisconnect() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.disconnectBackgroundEffect, type: String.self)
    }

    func saveBackgroundCustomDisconnectPath(value: String) {
        sharedDefault?.set(value, forKey: SharedKeys.disconnectBackgroundCustomPath)
    }

    func getBackgroundCustomDisconnectPath() -> String? {
        return sharedDefault?.string(forKey: SharedKeys.disconnectBackgroundCustomPath)
    }

    func backgroundCustomDisconnectPath() -> AnyPublisher<String?, Never> {
        return observeKeyEmpty(SharedKeys.disconnectBackgroundCustomPath, type: String.self)
    }

    // Custom Locations Names
    func saveCustomLocationsNames(value: [ExportedRegion]) {
        saveObject(object: value, forKey: SharedKeys.customLocationNames)
    }

    func getCustomLocationsNames() -> [ExportedRegion] {
        getObject(forKey: SharedKeys.customLocationNames) ?? []
    }
}
