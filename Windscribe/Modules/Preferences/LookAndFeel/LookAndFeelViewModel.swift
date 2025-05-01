//
//  LookAndFeelViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-16.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

protocol LookAndFeelViewModelType: UIDocumentPickerDelegate {
    var isDarkMode: BehaviorSubject<Bool> { get }
    var alertPublishSubject: PublishSubject<CustomLocationsAlertType> { get }
    var themeManager: ThemeManager { get }
    var alertManager: AlertManagerV2 { get }

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
    func getCustomSoundPath(for domain: SoundAssetDomainType) -> String?

    // Version
    func getVersion() -> String

    // Custom Locations
    func exportLocations(presentClosure: (_ tempURL: URL) -> Void)
    func resetLocations()
}

class LookAndFeelViewModel: NSObject, LookAndFeelViewModelType {

    // Dependencies
    let preferences: Preferences
    let themeManager: ThemeManager
    let localDB: LocalDatabase
    let logger: FileLogger
    let alertManager: AlertManagerV2
    let serverRepository: ServerRepository

    // State
    let disposeBag = DisposeBag()
    let isDarkMode = BehaviorSubject<Bool>(value: DefaultValues.darkMode)
    let alertPublishSubject = PublishSubject<CustomLocationsAlertType>()

    let soundEffectConnect = BehaviorSubject<SoundEffectType>(value: .none)
    let soundEffectDisconnect = BehaviorSubject<SoundEffectType>(value: .none)

    let backgroundConnect = BehaviorSubject<BackgroundEffectType>(value: .none)
    let backgroundDisconnect = BehaviorSubject<BackgroundEffectType>(value: .none)

    init(preferences: Preferences,
         themeManager: ThemeManager,
         logger: FileLogger,
         alertManager: AlertManagerV2,
         localDB: LocalDatabase,
         serverRepository: ServerRepository) {
        self.preferences = preferences
        self.themeManager = themeManager
        self.localDB = localDB
        self.logger = logger
        self.alertManager = alertManager
        self.serverRepository = serverRepository
        super.init()
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

    func exportLocations(presentClosure: (_ tempURL: URL) -> Void) {
        logger.logI("GeneralViewModel", "Export Locations pressed")
        let serverModels = serverRepository.currentServerModels
        guard !serverModels.isEmpty else {
            logger.logI("GeneralViewModel", "Export Locations failed, no local servers to export")
            alertPublishSubject.onNext(.failedExport)
            return
        }

        do {
            let jsonData = try buildLocationsJsonString(serverModels: serverModels)
            try saveJSONToFile(jsonData: jsonData, presentClosure: presentClosure)
        } catch {
            alertPublishSubject.onNext(.failedExport)
            logger.logE("GeneralViewModel", "Export Locations failed, \(error.localizedDescription)")
            return
        }
        logger.logI("GeneralViewModel", "Export Locations successful")
    }

    func resetLocations() {
        serverRepository.updateRegions(with: [])
        alertPublishSubject.onNext(.successfulReset)
    }

    private func saveJSONToFile(jsonData: Data, presentClosure: (_ tempURL: URL) -> Void) throws {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("windscribe-servers.json")
        try jsonData.write(to: tempURL)
            presentClosure(tempURL)
    }

    private func buildLocationsJsonString(serverModels: [ServerModel]) throws -> Data {
        let regions: [ExportedRegion] = serverModels.compactMap { ExportedRegion(model: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(regions)
    }
}

extension LookAndFeelViewModel: UIDocumentPickerDelegate {
    func documentPicker(_: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let fileURL = urls.first else { return }
        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            do {
                let jsonData = try Data(contentsOf: fileURL)
                let regionList = try JSONDecoder().decode([ExportedRegion].self, from: jsonData)
                serverRepository.updateRegions(with: regionList)
                logger.logI("GeneralViewModel", "Import Locations finished")
            } catch {
                alertPublishSubject.onNext(.failedImport)
                logger.logE("GeneralViewModel", "Import Locations failed, \(error.localizedDescription)")
            }
            alertPublishSubject.onNext(.successfulImport)
        }
    }
}
