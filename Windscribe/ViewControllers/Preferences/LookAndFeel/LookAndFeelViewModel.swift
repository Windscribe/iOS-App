//
//  LookAndFeelViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-16.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

protocol LookAndFeelViewModelType {
    var isDarkMode: BehaviorSubject<Bool> { get }
    var themeManager: ThemeManager { get }

    // Appearance
    func didSelectedAppearance(value: String)
    func getCurrentApperance() -> String

    // Aspect Ratio
    func getAspectRatio() -> BackgroundAspectRatioType
    func updateAspectRatioType(type: BackgroundAspectRatioType)

    // Background
    func getBackgroundEffect(for domain: BackgroundAssetDomainType) -> BackgroundEffectType
    func updateBackgroundEffectType(domain: BackgroundAssetDomainType, type: BackgroundEffectType)

    // Sound Effect
    func getSoundEffect(for domain: SoundAssetDomainType) -> SoundEffectType
    func updateSoundEffectType(domain: SoundAssetDomainType, type: SoundEffectType)
    func saveCustomSoundPath(domain: SoundAssetDomainType, path: String)

    // Version
    func getVersion() -> String
}

class LookAndFeelViewModel: LookAndFeelViewModelType {

    // Dependencies
    let preferences: Preferences
    let themeManager: ThemeManager

    // State
    let disposeBag = DisposeBag()
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)

    let soundEffectConnect = BehaviorSubject<SoundEffectType>(value: .none)
    let soundEffectDisconnect = BehaviorSubject<SoundEffectType>(value: .none)

    let backgroundConnect = BehaviorSubject<BackgroundEffectType>(value: .none)
    let backgroundDisconnect = BehaviorSubject<BackgroundEffectType>(value: .none)

    init(preferences: Preferences, themeManager: ThemeManager) {
        self.preferences = preferences
        self.themeManager = themeManager

        bindViews()
    }

    private func bindViews() {
        themeManager.darkTheme.subscribe { [weak self] data in
            self?.isDarkMode.onNext(data)
        }.disposed(by: disposeBag)

        guard let soundConnectRaw = preferences.getSoundEffectConnect(),
              let soundDisconnectRaw = preferences.getSoundEffectDisconnect(),
              let backgroundConnectRaw = preferences.getBackgroundEffectConnect(),
              let backgroundDisconnectRaw = preferences.getBackgroundEffectDisconnect()  else {
            return
        }

        backgroundConnect.onNext(BackgroundEffectType.fromRaw(value: backgroundConnectRaw))
        backgroundDisconnect.onNext(BackgroundEffectType.fromRaw(value: backgroundDisconnectRaw))

        soundEffectConnect.onNext(SoundEffectType.fromRaw(value: soundConnectRaw))
        soundEffectDisconnect.onNext(SoundEffectType.fromRaw(value: soundDisconnectRaw))
    }

    // Appearance
    func didSelectedAppearance(value: String) {
        guard let valueToSave = TextsAsset.LookFeel.getValue(displayText: value) else { return }
        preferences.saveAppearance(appearance: valueToSave)
        preferences.saveDarkMode(darkMode: valueToSave == DefaultValues.appearance)
    }

    func getCurrentApperance() -> String {
        if let isDarkMode = try? isDarkMode.value(), !isDarkMode {
            return "Light"
        }
        return DefaultValues.appearance
    }

    // Sound Effect
    func getSoundEffect(for domain: SoundAssetDomainType) -> SoundEffectType {
        let fieldValue: String = switch domain {
        case .connect:
            preferences.getSoundEffectConnect() ?? ""
        case .disconnect:
            preferences.getSoundEffectDisconnect() ?? ""
        }

        if fieldValue == Fields.Values.none {
            return .none
        } else if fieldValue == Fields.Values.custom {
            return .custom
        } else if let subtype = SoundEffectSubtype(rawValue: fieldValue) {
            return .bundled(subtype: subtype)
        } else {
            return .none
        }
    }

    func updateSoundEffectType(domain: SoundAssetDomainType, type: SoundEffectType) {
        switch domain {
        case .connect:
            soundEffectConnect.onNext(type)
            preferences.saveSoundEffectConnect(value: type.preferenceValue)

        case .disconnect:
            soundEffectDisconnect.onNext(type)
            preferences.saveSoundEffectDisconnect(value: type.preferenceValue)
        }
    }

    func saveCustomSoundPath(domain: SoundAssetDomainType, path: String) {
        switch domain {
        case .connect:
            preferences.saveCustomSoundEffectPathConnect(path)
        case .disconnect:
            preferences.saveCustomSoundEffectPathDisconnect(path)
        }
    }

    func getCustomSoundPath(for domain: SoundAssetDomainType) -> String? {
        switch domain {
        case .connect:
            return preferences.getCustomSoundEffectPathConnect()
        case .disconnect:
            return preferences.getCustomSoundEffectPathDisconnect()
        }
    }

    // Background
    func getBackgroundEffect(for domain: BackgroundAssetDomainType) -> BackgroundEffectType {
        let fieldValue: String = switch domain {
        case .connect:
            preferences.getBackgroundEffectConnect() ?? ""
        case .disconnect:
            preferences.getBackgroundEffectDisconnect() ?? ""
        default:
            ""
        }

        if fieldValue == Fields.Values.none {
            return .none
        } else if fieldValue == Fields.Values.custom {
            return .custom
        } else if let subtype = BackgroundEffectSubtype(rawValue: fieldValue) {
            return .bundled(subtype: subtype)
        } else {
            return .none
        }
    }

    func updateBackgroundEffectType(domain: BackgroundAssetDomainType, type: BackgroundEffectType) {
        switch domain {
        case .connect:
            backgroundConnect.onNext(type)
            preferences.saveBackgroundEffectConnect(value: type.preferenceValue)
        case .disconnect:
            backgroundDisconnect.onNext(type)
            preferences.saveBackgroundEffectDisconnect(value: type.preferenceValue)
        default:
            return
        }
    }

    func getAspectRatio() -> BackgroundAspectRatioType {
        let fieldValue = preferences.getAspectRatio() ?? ""

        switch fieldValue {
        case Fields.Values.stretch:
            return .stretch
        case Fields.Values.fill:
            return .fill
        case Fields.Values.tile:
            return .tile
        default:
            return .stretch
        }
    }

    func updateAspectRatioType(type: BackgroundAspectRatioType) {
        preferences.saveAspectRatio(value: type.preferenceValue)
    }

    func getVersion() -> String {
        guard let releaseNumber = Bundle.main.releaseVersionNumber,
              let buildNumber = Bundle.main.buildVersionNumber else {
            return ""
        }

        return "v\(releaseNumber) (\(buildNumber))"
    }
}
