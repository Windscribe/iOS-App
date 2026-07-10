//
//  LookAndFeelViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 2026-05-26.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class LookAndFeelViewModel {

    // MARK: - State (read by the view)

    var alertType: LookAndFeelImportAlertType = .empty
    var showAlert: Bool = false

    var isNavigating: Bool = false

    private var appearance: String = ""
    private var aspectRatio: BackgroundAspectRatioType = .stretch
    private var backgroundConnect: BackgroundEffectType = .flag
    private var backgroundDisconnect: BackgroundEffectType = .flag
    private var soundEffectConnect: SoundEffectType = .none
    private var soundEffectDisconnect: SoundEffectType = .none
    private var discreetAppIconSelection: DiscreetAppIconType = .og
    private var serverDocumentInfo: DocumentFormatInfo?
    private var isObserving = false

    var entries: [LookAndFeelEntryType] {
        [
            .appearance(currentOption: appearance),
            .background(ratio: aspectRatio,
                        connected: backgroundConnect,
                        customConnectedFile: getShortPath(from: lookAndFeel.backgroundCustomConnectPath),
                        disconnected: backgroundDisconnect,
                        customDisconnectedFile: getShortPath(from: lookAndFeel.backgroundCustomDisconnectPath)),
            .sound(connected: soundEffectConnect,
                   customConnectedFile: getShortPath(from: preferencesReading.customSoundPathConnect),
                   disconnected: soundEffectDisconnect,
                   customDisconnectedFile: getShortPath(from: preferencesReading.customSoundPathDisconnect)),
            .discreetAppIcon(currentSelection: discreetAppIconSelection),
            .customLocation(documentInfo: serverDocumentInfo)
        ]
    }

    // MARK: - Dependencies (injected via init — protocols only)

    private let lookAndFeel: any LookAndFeelObserving
    private let lookAndFeelStoring: any LookAndFeelStoring
    private let hapticFeedback: any HapticFeedbacking
    private let preferencesReading: PreferencesReading
    private let preferencesWriting: PreferencesWriting
    private let backgroundFileStoring: any BackgroundFileStoring
    private let soundFileStoring: any SoundFileStoring
    private let locationNamesManaging: any LocationNamesManaging
    private let logger: any LogStoring

    // MARK: - Init

    init(
        lookAndFeel: any LookAndFeelObserving,
        lookAndFeelStoring: any LookAndFeelStoring,
        hapticFeedback: any HapticFeedbacking,
        preferencesReading: PreferencesReading,
        preferencesWriting: PreferencesWriting,
        backgroundFileStoring: any BackgroundFileStoring,
        soundFileStoring: any SoundFileStoring,
        locationNamesManaging: any LocationNamesManaging,
        logger: any LogStoring
    ) {
        self.lookAndFeel = lookAndFeel
        self.lookAndFeelStoring = lookAndFeelStoring
        self.hapticFeedback = hapticFeedback
        self.preferencesReading = preferencesReading
        self.preferencesWriting = preferencesWriting
        self.backgroundFileStoring = backgroundFileStoring
        self.soundFileStoring = soundFileStoring
        self.locationNamesManaging = locationNamesManaging
        self.logger = logger

        // Initialize state from services
        loadInitialState()
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        await observeDarkMode()
    }

    func refreshIconSelection() {
        if let customIconValue = preferencesReading.customAppIcon {
            discreetAppIconSelection = DiscreetAppIconType.fromRaw(value: customIconValue)
        }
    }

    // MARK: - Actions (called by the view)

    func entrySelected(_ entry: LookAndFeelEntryType, action: MenuEntryActionResponseType) {
        hapticFeedback.checkSettingsAction(action: action)

        switch entry {
        case .appearance:
            if case let .multiple(newOption, _) = action {
                lookAndFeelStoring.updateDarkMode(enabled: newOption == DefaultValues.appearance)
            }

        case .background:
            handleBackgroundAction(action: action)

        case .sound:
            handleSoundAction(action: action)

        case .discreetAppIcon:
            isNavigating = true

        case .customLocation:
            handleCustomLocationAction(action: action)
        }
    }

    // MARK: - Private Helpers

    private func loadInitialState() {
        appearance = lookAndFeel.isDarkMode ? DefaultValues.appearance.localized : TextsAsset.lightAppearance

        if let soundConnectRaw = preferencesReading.soundEffectConnect {
            soundEffectConnect = SoundEffectType.fromRaw(value: soundConnectRaw)
        }
        if let soundDisconnectRaw = preferencesReading.soundEffectDisconnect {
            soundEffectDisconnect = SoundEffectType.fromRaw(value: soundDisconnectRaw)
        }

        aspectRatio = lookAndFeel.backgroundCustomAspectRatio
        backgroundConnect = lookAndFeel.backgroundEffectConnect
        backgroundDisconnect = lookAndFeel.backgroundEffectDisconnect

        if let customIconValue = preferencesReading.customAppIcon {
            discreetAppIconSelection = DiscreetAppIconType.fromRaw(value: customIconValue)
        }

        serverDocumentInfo = getServersDocumentFormatInfo()
    }

    private func observeDarkMode() async {
        for await isDark in lookAndFeel.darkModeUpdates {
            appearance = isDark ? DefaultValues.appearance.localized : TextsAsset.lightAppearance
        }
    }

    private func getShortPath(from longPath: String?) -> String {
        guard let longPath else { return TextsAsset.General.custom }
        return URL(fileURLWithPath: longPath).lastPathComponent
    }

    private func handleBackgroundAction(action: MenuEntryActionResponseType) {
        Task {
            if case let .multiple(newOption, parentId) = action {
                if parentId == LookAndFeelSecondaryEntryIDs.backgroundRatio.id {
                    aspectRatio = BackgroundAspectRatioType(aspectRatioType: newOption)
                    lookAndFeelStoring.updateBackgroundCustomAspectRatio(aspectRatio: aspectRatio)
                } else if parentId == LookAndFeelSecondaryEntryIDs.backgroundConnected.id {
                    backgroundConnect = BackgroundEffectType(mainCategory: newOption)
                    lookAndFeelStoring.updateBackgroundEffectConnect(effect: backgroundConnect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.backgroundDisconnected.id {
                    backgroundDisconnect = BackgroundEffectType(mainCategory: newOption)
                    lookAndFeelStoring.updateBackgroundEffectDisconnect(effect: backgroundDisconnect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledConnectedBackgrounds.id {
                    guard let subtype = BackgroundEffectSubtype(rawValue: newOption) else { return }
                    backgroundConnect = BackgroundEffectType.bundled(subtype: subtype)
                    lookAndFeelStoring.updateBackgroundEffectConnect(effect: backgroundConnect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledDisconnectedBackgrounds.id {
                    guard let subtype = BackgroundEffectSubtype(rawValue: newOption) else { return }
                    backgroundDisconnect = BackgroundEffectType.bundled(subtype: subtype)
                    lookAndFeelStoring.updateBackgroundEffectDisconnect(effect: backgroundDisconnect)
                }
            } else if case let .file(selectedURL, parentId) = action {
                guard let selectedURL = selectedURL else { return }
                if parentId == LookAndFeelSecondaryEntryIDs.fileContentConnect.id {
                    await saveImageURL(pickedImageFile: selectedURL, for: .connect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.fileContentDisconnect.id {
                    await saveImageURL(pickedImageFile: selectedURL, for: .disconnect)
                }
            }
        }
    }

    private func handleSoundAction(action: MenuEntryActionResponseType) {
        Task {
            if case let .multiple(newOption, parentId) = action {
                if parentId == LookAndFeelSecondaryEntryIDs.soundConnected.id {
                    let subType = getSoundEffectSubType(from: newOption)
                    soundEffectConnect = SoundEffectType(mainCategory: newOption, subtypeTitle: subType)
                    lookAndFeelStoring.updateSoundEffectConnect(value: subType ?? newOption)
                } else if parentId == LookAndFeelSecondaryEntryIDs.soundDisconnected.id {
                    let subType = getSoundEffectSubType(from: newOption)
                    soundEffectDisconnect = SoundEffectType(mainCategory: newOption, subtypeTitle: subType)
                    lookAndFeelStoring.updateSoundEffectDisconnect(value: subType ?? newOption)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledConnectedSounds.id {
                    guard let subtype = SoundEffectSubtype(rawValue: newOption) else { return }
                    soundEffectConnect = SoundEffectType.bundled(subtype: subtype)
                    lookAndFeelStoring.updateSoundEffectConnect(value: newOption)
                } else if parentId == LookAndFeelSecondaryEntryIDs.bundledDisconnectedSounds.id {
                    guard let subtype = SoundEffectSubtype(rawValue: newOption) else { return }
                    soundEffectDisconnect = SoundEffectType.bundled(subtype: subtype)
                    lookAndFeelStoring.updateSoundEffectDisconnect(value: newOption)
                }
            } else if case let .file(selectedURL, parentId) = action {
                guard let selectedURL = selectedURL else { return }
                if parentId == LookAndFeelSecondaryEntryIDs.fileContentConnect.id {
                    await saveSoundURL(pickedSoundFile: selectedURL, for: .connect)
                } else if parentId == LookAndFeelSecondaryEntryIDs.fileContentDisconnect.id {
                    await saveSoundURL(pickedSoundFile: selectedURL, for: .disconnect)
                }
            }
        }
    }

    private func handleCustomLocationAction(action: MenuEntryActionResponseType) {
        if case let .button(parentId) = action {
            if parentId == LookAndFeelSecondaryEntryIDs.customNameReset.id {
                resetLocations()
            }
        } else if case let .file(selectedURL, _) = action {
            guard let selectedURL = selectedURL else { return }
            importLocationFile(pickedLocationFile: selectedURL)
        } else if case let .buttonFileExport(success, _) = action {
            showAlert(for: success ? .customExportSucceeded : .customExportFailed)
        }
    }

    private func getSoundEffectSubType(from newOption: String) -> String? {
        if newOption == Fields.Values.bundled,
           let first = SoundEffectSubtype.allCases.first {
            return first.rawValue
        }
        return nil
    }

    // MARK: - File Operations

    private func saveImageURL(pickedImageFile fileURL: URL, for domain: BackgroundAssetDomainType) async {
        if let copiedURL = await backgroundFileStoring.saveImageFile(from: fileURL, for: domain) {
            showAlert(for: .importSucceeded)
            switch domain {
            case .connect:
                lookAndFeelStoring.updateBackgroundCustomConnectPath(path: copiedURL.path)
            case .disconnect:
                lookAndFeelStoring.updateBackgroundCustomDisconnectPath(path: copiedURL.path)
            case .aspectRatio:
                break
            }
        } else {
            showAlert(for: .importFailed)
        }
    }

    private func saveSoundURL(pickedSoundFile fileURL: URL, for domain: SoundAssetDomainType) async {
        if let copiedURL = await soundFileStoring.saveSoundFile(from: fileURL, for: domain) {
            showAlert(for: .importSucceeded)
            switch domain {
            case .connect:
                lookAndFeelStoring.updateCustomSoundPathConnect(path: copiedURL.path)
            case .disconnect:
                lookAndFeelStoring.updateCustomSoundPathDisconnect(path: copiedURL.path)
            }
        } else {
            showAlert(for: .importFailed)
        }
    }

    // MARK: - Location Operations

    private func importLocationFile(pickedLocationFile fileURL: URL) {
        if fileURL.startAccessingSecurityScopedResource() {
            defer { fileURL.stopAccessingSecurityScopedResource() }
            do {
                let jsonData = try Data(contentsOf: fileURL)
                let regionList = try JSONDecoder().decode([ExportedRegion].self, from: jsonData)
                locationNamesManaging.updateRegions(with: regionList)
                logger.logI("LookAndFeelViewModel", "Import Locations finished")
                showAlert(for: .customImportSucceeded)
            } catch {
                showAlert(for: .customImportFailed)
                logger.logE("LookAndFeelViewModel", "Import Locations failed, \(error.localizedDescription)")
            }
        }
    }

    private func getServersDocumentFormatInfo() -> DocumentFormatInfo? {
        logger.logI("LookAndFeelViewModel", "Export Locations pressed")
        let locationModels = locationNamesManaging.currentLocationModels
        guard !locationModels.isEmpty else {
            logger.logI("LookAndFeelViewModel", "Export Locations failed, no local servers to export")
            return nil
        }

        do {
            let jsonData = try buildLocationsJsonString(locationModels: locationModels)
            logger.logI("LookAndFeelViewModel", "Export Locations successful")
            return DocumentFormatInfo(fileData: jsonData, type: .json, tempFileName: "besugo.json")
        } catch {
            logger.logE("LookAndFeelViewModel", "Export Locations failed, \(error.localizedDescription)")
            return nil
        }
    }

    private func resetLocations() {
        locationNamesManaging.updateRegions(with: [])
        showAlert(for: .resetSucceeded)
    }

    private func buildLocationsJsonString(locationModels: [LocationModel]) throws -> Data {
        let regions: [ExportedRegion] = locationModels.compactMap { ExportedRegion(model: $0) }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        return try encoder.encode(regions)
    }

    private func showAlert(for alertType: LookAndFeelImportAlertType) {
        self.alertType = alertType
        showAlert = true
    }
}
