//
//  LookAndFeelSettingsViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-05-08.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum LookAndFeelImportAlertType {
    case customImportFailed
    case customImportSucceeded
    case customExportFailed
    case customExportSucceeded
    case resetSucceeded
    case importFailed
    case importSucceeded
    case empty

    var title: String {
        switch self {
        case .customImportFailed:
            return TextsAsset.CustomLocationNames.importTitleFailed
        case .customImportSucceeded:
            return TextsAsset.CustomLocationNames.importTitleSuccess
        case .customExportFailed:
            return TextsAsset.CustomLocationNames.exportTitleFailed
        case .customExportSucceeded:
            return TextsAsset.CustomLocationNames.exportTitleSuccess
        case .resetSucceeded:
            return TextsAsset.CustomLocationNames.resetTitleSuccess
        case .importFailed:
            return TextsAsset.CustomAssetsAlert.failedTitle
        case .importSucceeded:
            return TextsAsset.CustomAssetsAlert.successTitle
        default:
            return ""
        }
    }

    var message: String {
        switch self {
        case .customImportFailed:
            return TextsAsset.CustomLocationNames.failedImporting
        case .customImportSucceeded:
            return TextsAsset.CustomLocationNames.successfullyImported
        case .customExportFailed:
            return TextsAsset.CustomLocationNames.failedExporting
        case .customExportSucceeded:
            return TextsAsset.CustomLocationNames.successfullyExported
        case .resetSucceeded:
            return TextsAsset.CustomLocationNames.resetSuccessful
        case .importFailed:
            return TextsAsset.CustomAssetsAlert.failedMessage
        case .importSucceeded:
            return TextsAsset.CustomAssetsAlert.successMessage
        default:
            return ""
        }
    }
}

protocol LookAndFeelSettingsViewModel: PreferencesBaseViewModel {
    var isImporterPresented: Bool { get set }
    var showAlert: Bool { get set }
    var alertType: LookAndFeelImportAlertType { get set }
    var entries: [LookAndFeelEntryType] { get set }

    func entrySelected(_ entry: LookAndFeelEntryType,
                       action: MenuEntryActionResponseType)
}

final class LookAndFeelSettingsViewModelImpl: PreferencesBaseViewModelImpl, LookAndFeelSettingsViewModel {
    @Published var isImporterPresented: Bool = false
    @Published var alertType: LookAndFeelImportAlertType = .empty
    @Published var showAlert: Bool = false
    @Published var entries: [LookAndFeelEntryType] = []

    private let preferences: Preferences
    private let backgroundFileManager: BackgroundFileManaging
    private let soundFileManager: SoundFileManaging
    private let serverRepository: ServerRepository

    private var appearance: String = ""
    private var aspectRatio: BackgroundAspectRatioType = .stretch
    private var backgroundConnect: BackgroundEffectType = .flag
    private var backgroundDisconnect: BackgroundEffectType = .flag
    private var soundEffectConnect: SoundEffectType = .none
    private var soundEffectDisconnect: SoundEffectType = .none
    private var serverDocumentInfo: DocumentFormatInfo?
    private let lookAndFeelRepository: LookAndFeelRepositoryType

    init(logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         hapticFeedbackManager: HapticFeedbackManager,
         preferences: Preferences,
         backgroundFileManager: BackgroundFileManaging,
         soundFileManager: SoundFileManaging,
         serverRepository: ServerRepository) {
        self.preferences = preferences
        self.backgroundFileManager = backgroundFileManager
        self.soundFileManager = soundFileManager
        self.serverRepository = serverRepository
        self.lookAndFeelRepository = lookAndFeelRepository

        super.init(logger: logger,
                   lookAndFeelRepository: lookAndFeelRepository,
                   hapticFeedbackManager: hapticFeedbackManager)

        serverDocumentInfo = getServersDocumentFormatInfo()
    }

    override func bindSubjects() {
        super.bindSubjects()

        if let soundConnectRaw = preferences.getSoundEffectConnect() {
            soundEffectConnect = SoundEffectType.fromRaw(value: soundConnectRaw)
        }
        if let soundDisconnectRaw = preferences.getSoundEffectDisconnect() {
            soundEffectDisconnect = SoundEffectType.fromRaw(value: soundDisconnectRaw)
        }
        aspectRatio = lookAndFeelRepository.backgroundCustomAspectRatio
        backgroundConnect = lookAndFeelRepository.backgroundEffectConnect
        backgroundDisconnect = lookAndFeelRepository.backgroundEffectDisconnect
    }

    override func reloadItems() {
        appearance = isDarkMode ? DefaultValues.appearance.localized : TextsAsset.lightAppearance

        entries = [
            .appearance(currentOption: appearance),
            .background(ratio: aspectRatio,
                        connected: backgroundConnect,
                        customConnectedFile: getShortPath(from: lookAndFeelRepository.backgroundCustomConnectPath),
                        disconnected: backgroundDisconnect,
                        customDisconnectedFile: getShortPath(from: lookAndFeelRepository.backgroundCustomDisconnectPath)),
            .sound(connected: soundEffectConnect,
                   customConnectedFile: getShortPath(from: preferences.getCustomSoundEffectPathConnect()),
                   disconnected: soundEffectDisconnect,
                   customDisconnectedFile: getShortPath(from: preferences.getCustomSoundEffectPathDisconnect())),
            .customLocation(documentInfo: serverDocumentInfo)
        ]
    }

    private func getShortPath(from longPath: String?) -> String {
        guard let longPath else { return TextsAsset.General.custom }
        return URL(fileURLWithPath: longPath).lastPathComponent
    }

    func entrySelected(_ entry: LookAndFeelEntryType, action: MenuEntryActionResponseType) {
        actionSelected(action)

        switch entry {
        case .appearance:
            if case let .multiple(newOption, _) = action {
                preferences.saveDarkMode(darkMode: newOption == DefaultValues.appearance)
            }
        case .background:
            if case let .multiple(newOption, parentId) = action {
                if parentId == LookAndFeelSecondaryEntryIDs.backgroundRatio.id {
                    aspectRatio = BackgroundAspectRatioType(aspectRatioType: newOption)
                    lookAndFeelRepository.updateBackgroundCustomAspectRatio(aspectRatio: aspectRatio)
                } else if parentId == LookAndFeelSecondaryEntryIDs.backgroundConnected.id {
                    backgroundConnect = BackgroundEffectType(mainCategory: newOption)
                    lookAndFeelRepository.updateBackgroundEffectConnect(effect: backgroundConnect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.backgroundDisconnected.id {
                    backgroundDisconnect = BackgroundEffectType(mainCategory: newOption)
                    lookAndFeelRepository.updateBackgroundEffectDisconnect(effect: backgroundDisconnect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledConnectedBackgrounds.id {
                    guard let subtype = BackgroundEffectSubtype(rawValue: newOption) else { return }
                    backgroundConnect = BackgroundEffectType.bundled(subtype: subtype)
                    lookAndFeelRepository.updateBackgroundEffectConnect(effect: backgroundConnect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledDisconnectedBackgrounds.id {
                    guard let subtype = BackgroundEffectSubtype(rawValue: newOption) else { return }
                    backgroundDisconnect = BackgroundEffectType.bundled(subtype: subtype)
                    lookAndFeelRepository.updateBackgroundEffectDisconnect(effect: backgroundDisconnect)
                }
            } else if case let .file(selecteURL, parentId) = action {
                guard let selecteURL = selecteURL else {

                    return
                }
                if parentId == LookAndFeelSecondaryEntryIDs.fileContentConnect.id {
                    saveImageURL(pickedImageFile: selecteURL, for: .connect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.fileContentDisconnect.id {
                    saveImageURL(pickedImageFile: selecteURL, for: .disconnect)
                }
            }
        case .sound:
            if case let .multiple(newOption, parentId) = action {
                if parentId == LookAndFeelSecondaryEntryIDs.soundConnected.id {
                    let subType = getSoundEffectSubType(from: newOption)
                    soundEffectConnect = SoundEffectType(mainCategory: newOption,
                                                         subtypeTitle: subType)
                    preferences.saveSoundEffectConnect(value: subType ?? newOption)
                } else if parentId == LookAndFeelSecondaryEntryIDs.soundDisconnected.id {
                    let subType = getSoundEffectSubType(from: newOption)
                    soundEffectDisconnect = SoundEffectType(mainCategory: newOption,
                                                            subtypeTitle: subType)
                    preferences.saveSoundEffectDisconnect(value: subType ?? newOption)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledConnectedSounds.id {
                    guard let subtype = SoundEffectSubtype(rawValue: newOption) else { return }
                    soundEffectConnect = SoundEffectType.bundled(subtype: subtype)
                    preferences.saveSoundEffectConnect(value: newOption)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledDisconnectedSounds.id {
                    guard let subtype = SoundEffectSubtype(rawValue: newOption) else { return }
                    soundEffectDisconnect = SoundEffectType.bundled(subtype: subtype)
                    preferences.saveSoundEffectDisconnect(value: newOption)
                }
            } else if case let .file(selecteURL, parentId) = action {
                guard let selecteURL = selecteURL else {

                    return
                }
                if parentId == LookAndFeelSecondaryEntryIDs.fileContentConnect.id {
                    saveSoundURL(pickedSoundFile: selecteURL, for: .connect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.fileContentDisconnect.id {
                    saveSoundURL(pickedSoundFile: selecteURL, for: .disconnect)
                }
            }
        case .customLocation:
            if case let .button(parentId) = action {
                if parentId == LookAndFeelSecondaryEntryIDs.customNameReset.id {
                    resetLocations()
                }
            } else if case let .file(selecteURL, _) = action {
                guard let selecteURL = selecteURL else {
                    return
                }
                importLocationFile(pickedLocationFile: selecteURL)
            } else if case let .buttonFileExport(success, _) = action {
                showAlert(for: success ? .customExportSucceeded : .customExportFailed)
            }
        }
        reloadItems()
    }

    private func getSoundEffectSubType(from newOption: String) -> String? {
        if newOption == Fields.Values.bundled,
           let first = SoundEffectSubtype.allCases.first {
            return first.rawValue
        }
        return nil
    }
}

extension LookAndFeelSettingsViewModelImpl {
    private func saveImageURL(pickedImageFile fileURL: URL, for domain: BackgroundAssetDomainType) {
        backgroundFileManager.saveImageFile(from: fileURL, for: domain) { [weak self] copiedURL in
            guard let self = self, let copiedURL = copiedURL else {
                self?.showAlert(for: .importFailed)
                return
            }
            showAlert(for: .importSucceeded)
            saveCustomBackgroundPath(domain: domain, path: copiedURL.path)
        }
    }

    private func saveSoundURL(pickedSoundFile fileURL: URL, for domain: SoundAssetDomainType) {
        soundFileManager.saveSoundFile(from: fileURL, for: domain) { [weak self] copiedURL in
            guard let self = self, let copiedURL = copiedURL else {
                self?.showAlert(for: .importFailed)
                return
            }
            showAlert(for: .importSucceeded)
            saveCustomSoundPath(domain: domain, path: copiedURL.path)
        }
    }

    private func saveCustomBackgroundPath(domain: BackgroundAssetDomainType, path: String) {
        DispatchQueue.main.async {
            switch domain {
            case .connect:
                self.lookAndFeelRepository.updateBackgroundCustomConnectPath(path: path)
            case .disconnect:
                self.lookAndFeelRepository.updateBackgroundCustomDisconnectPath(path: path)
            case .aspectRatio:
                return
            }
            self.reloadItems()
        }
    }

    private func saveCustomSoundPath(domain: SoundAssetDomainType, path: String) {
        DispatchQueue.main.async {
            switch domain {
            case .connect:
                self.preferences.saveCustomSoundEffectPathConnect(path)
            case .disconnect:
                self.preferences.saveCustomSoundEffectPathDisconnect(path)
            }
            self.reloadItems()
        }
    }

    private func showAlert(for alertType: LookAndFeelImportAlertType) {
        self.alertType = alertType
        showAlert = true
    }
}

extension LookAndFeelSettingsViewModelImpl {
    private func importLocationFile(pickedLocationFile fileURL: URL) {
        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            do {
                let jsonData = try Data(contentsOf: fileURL)
                let regionList = try JSONDecoder().decode([ExportedRegion].self, from: jsonData)
                serverRepository.updateRegions(with: regionList)
                logger.logI("LookAndFeelSettingsViewModel", "Import Locations finished")
                showAlert(for: .customImportSucceeded)
            } catch {
                showAlert(for: .customImportFailed)
                logger.logE("LookAndFeelSettingsViewModel", "Import Locations failed, \(error.localizedDescription)")
            }
        }
    }

    private func getServersDocumentFormatInfo() -> DocumentFormatInfo? {
        logger.logI("LookAndFeelSettingsViewModel", "Export Locations pressed")
        let serverModels = serverRepository.currentServerModels
        guard !serverModels.isEmpty else {
            logger.logI("LookAndFeelSettingsViewModel", "Export Locations failed, no local servers to export")
            return nil
        }

        do {
            let jsonData = try buildLocationsJsonString(serverModels: serverModels)
            return DocumentFormatInfo(fileData: jsonData, type: .json, tempFileName: "besugo.json")
        } catch {
            logger.logE("LookAndFeelSettingsViewModel", "Export Locations failed, \(error.localizedDescription)")
            return nil
        }
        logger.logI("LookAndFeelSettingsViewModel", "Export Locations successful")
    }

    private func resetLocations() {
        serverRepository.updateRegions(with: [])
        showAlert(for: .resetSucceeded)
    }

    private func buildLocationsJsonString(serverModels: [ServerModel]) throws -> Data {
        let regions: [ExportedRegion] = serverModels.compactMap { ExportedRegion(model: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(regions)
    }
}
