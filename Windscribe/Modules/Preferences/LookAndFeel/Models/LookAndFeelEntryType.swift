//
//  LookAndFeelEntryType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 15/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UniformTypeIdentifiers

enum LookAndFeelEntryType: MenuEntryHeaderType, Hashable {
    case appearance(currentOption: String),
         background(ratio: BackgroundAspectRatioType,
                    connected: BackgroundEffectType,
                    customConnectedFile: String,
                    disconnected: BackgroundEffectType,
                    customDisconnectedFile: String),
         sound(connected: SoundEffectType,
               customConnectedFile: String,
               disconnected: SoundEffectType,
               customDisconnectedFile: String),
         customLocation(documentInfo: DocumentFormatInfo?)

    var id: Int {
        switch self {
        case .appearance: 1
        case .background: 2
        case .sound: 3
        case .customLocation: 4
        }
    }
    var title: String {
        switch self {
        case .appearance: TextsAsset.LookFeel.appearanceTitle
        case .background: TextsAsset.LookFeel.appBackgroundTitle
        case .sound: TextsAsset.LookFeel.soundNotificationTitle
        case .customLocation: TextsAsset.LookFeel.renameLocationsTitle
        }
    }
    var icon: String {
        switch self {
        case .appearance: ImagesAsset.LookFeel.appearance
        case .background: ImagesAsset.LookFeel.appBackground
        case .sound: ImagesAsset.LookFeel.soundNotification
        case .customLocation: ImagesAsset.LookFeel.customLocation
        }
    }
    var message: String? {
        switch self {
        case .appearance: TextsAsset.LookFeel.appearanceDescription
        case .background: TextsAsset.LookFeel.appBackgroundDescription
        case .sound: TextsAsset.LookFeel.soundNotificationDescription
        case .customLocation: TextsAsset.LookFeel.renameLocationsDescription
        }
    }
    var action: MenuEntryActionType? {
        if case let .appearance(currentOption) = self {
            return .multiple(currentOption: currentOption,
                             options: TextsAsset.appearances,
                             parentId: id)
        }
        return nil
    }
    func makeSecondaryEntries() -> [LookAndFeelSecondaryEntryType] {
        switch self {
        case let .background(ratio,
                             connected, customConnectedFile,
                             disconnected, customDisconnectedFile):
            var entries: [LookAndFeelSecondaryEntryType] = [.backgroundRatio(effectType: ratio),
                            .backgroundDisconnected(effectType: disconnected)]
            if case let .bundled(subtype) = disconnected {
                entries.append(.bundledDisconnectedBackgrounds(currentOption: subtype.displayName))
            } else if case .custom = disconnected {
                entries.append(.fileContentDisconnect(fileName: customDisconnectedFile,
                                                      fileTypes: [.image]))
            }
            entries.append(.backgroundConnected(effectType: connected))
            if case let .bundled(subtype) = connected {
                entries.append(.bundledConnectedBackgrounds(currentOption: subtype.displayName))
            } else if case .custom = connected {
                entries.append(.fileContentConnect(fileName: customConnectedFile,
                                                   fileTypes: [.image]))
            }
            return entries
        case let .sound(connected, customConnectedFile,
                        disconnected, customDisconnectedFile):
            var entries: [LookAndFeelSecondaryEntryType] = [.soundDisconnected(effectType: disconnected)]
            if case let .bundled(subtype) = disconnected {
                entries.append(.bundledDisconnectedSounds(currentOption: subtype.displayName))
            } else if case .custom = disconnected {
                entries.append(.fileContentDisconnect(fileName: customDisconnectedFile,
                                                      fileTypes: [.audio]))
            }
            entries.append(.soundConnected(effectType: connected))
            if case let .bundled(subtype) = connected {
                entries.append(.bundledConnectedSounds(currentOption: subtype.displayName))
            } else if case .custom = connected {
                entries.append(.fileContentConnect(fileName: customConnectedFile,
                                                   fileTypes: [.audio]))
            }
            return entries
        case let .customLocation(documentInfo):
            return [
                .customNameImport,
                .customNameExport(documentInfo: documentInfo),
                .customNameReset
            ]
        default:
            return []
        }
    }
    var secondaryEntries: [MenuSecondaryEntryItem] {
        makeSecondaryEntries()
            .map {
                MenuSecondaryEntryItem(entry: $0)
            }
    }
}

enum LookAndFeelSecondaryEntryIDs: Int {
    case backgroundRatio = 1
    case backgroundConnected
    case backgroundDisconnected
    case soundConnected
    case soundDisconnected
    case customNameImport
    case customNameExport
    case customNameReset
    case fileContentConnect
    case fileContentDisconnect
    case bundledConnectedBackgrounds
    case bundledDisconnectedBackgrounds
    case bundledConnectedSounds
    case bundledDisconnectedSounds
}

enum LookAndFeelSecondaryEntryType: MenuEntryItemType, Hashable {
    case backgroundRatio(effectType: BackgroundAspectRatioType),
         backgroundConnected(effectType: BackgroundEffectType),
         backgroundDisconnected(effectType: BackgroundEffectType),
         soundConnected(effectType: SoundEffectType),
         soundDisconnected(effectType: SoundEffectType),
         fileContentConnect(fileName: String, fileTypes: [UTType]),
         fileContentDisconnect(fileName: String, fileTypes: [UTType]),
         bundledConnectedBackgrounds(currentOption: String),
         bundledDisconnectedBackgrounds(currentOption: String),
         bundledConnectedSounds(currentOption: String),
         bundledDisconnectedSounds(currentOption: String),
         customNameImport,
         customNameExport(documentInfo: DocumentFormatInfo?),
         customNameReset

    var backgroundEffectOptions: [String] {
        [TextsAsset.General.none,
         TextsAsset.General.flag,
         TextsAsset.General.bundled,
         TextsAsset.General.custom]
    }
    var soundEffectOptions: [String] {
        [TextsAsset.General.none,
         TextsAsset.General.bundled,
         TextsAsset.General.custom]
    }
    var ratioOptions: [String] {
        BackgroundAspectRatioType.allCases.map { $0.category }
    }
    var bundledBackgroundOptions: [String] {
        BackgroundEffectSubtype.allCases.map { $0.displayName }
    }
    var bundledSoundsOptions: [String] {
        SoundEffectSubtype.allCases.map { $0.displayName }
    }

    var id: Int {
        switch self {
        case .backgroundRatio:
            LookAndFeelSecondaryEntryIDs.backgroundRatio.rawValue
        case .backgroundConnected:
            LookAndFeelSecondaryEntryIDs.backgroundConnected.rawValue
        case .backgroundDisconnected:
            LookAndFeelSecondaryEntryIDs.backgroundDisconnected.rawValue
        case .soundConnected:
            LookAndFeelSecondaryEntryIDs.soundConnected.rawValue
        case .soundDisconnected:
            LookAndFeelSecondaryEntryIDs.soundDisconnected.rawValue
        case .customNameImport:
            LookAndFeelSecondaryEntryIDs.customNameImport.rawValue
        case .customNameExport:
            LookAndFeelSecondaryEntryIDs.customNameExport.rawValue
        case .customNameReset:
            LookAndFeelSecondaryEntryIDs.customNameReset.rawValue
        case .fileContentConnect:
            LookAndFeelSecondaryEntryIDs.fileContentConnect.rawValue
        case .fileContentDisconnect:
            LookAndFeelSecondaryEntryIDs.fileContentDisconnect.rawValue
        case .bundledConnectedBackgrounds:
            LookAndFeelSecondaryEntryIDs.bundledConnectedBackgrounds.rawValue
        case .bundledDisconnectedBackgrounds:
            LookAndFeelSecondaryEntryIDs.bundledDisconnectedBackgrounds.rawValue
        case .bundledConnectedSounds:
            LookAndFeelSecondaryEntryIDs.bundledConnectedSounds.rawValue
        case .bundledDisconnectedSounds:
            LookAndFeelSecondaryEntryIDs.bundledDisconnectedSounds.rawValue
        }
    }

    var title: String {
        switch self {
        case .backgroundRatio: TextsAsset.LookFeel.aspectRatioModeTitle
        case .backgroundConnected: TextsAsset.LookFeel.connectedActionTitle
        case .backgroundDisconnected: TextsAsset.LookFeel.disconnectedActionTitle
        case .soundConnected: TextsAsset.LookFeel.connectedActionTitle
        case .soundDisconnected: TextsAsset.LookFeel.disconnectedActionTitle
        case .customNameImport: TextsAsset.LookFeel.importActionTitle
        case .customNameExport: TextsAsset.LookFeel.exportActionTitle
        case .customNameReset: TextsAsset.LookFeel.resetActionTitle
        default: ""
        }
    }

    var icon: String { "" }

    var message: String? { nil }

    var action: MenuEntryActionType? {
        switch self {
        case let .backgroundRatio(effectType):
                .multiple(currentOption: effectType.category,
                          options: ratioOptions,
                          parentId: id)
        case let .backgroundConnected(effectType):
                .multiple(currentOption: effectType.mainCategory,
                          options: backgroundEffectOptions,
                          parentId: id)
        case let .backgroundDisconnected(effectType):
                .multiple(currentOption: effectType.mainCategory,
                          options: backgroundEffectOptions,
                          parentId: id)
        case let .soundConnected(effectType):
                .multiple(currentOption: effectType.mainCategory,
                          options: soundEffectOptions,
                          parentId: id)
        case let .soundDisconnected(effectType):
                .multiple(currentOption: effectType.mainCategory,
                          options: soundEffectOptions,
                          parentId: id)
        case let .bundledConnectedBackgrounds(currentOption):
                .multiple(currentOption: currentOption,
                          options: bundledBackgroundOptions,
                          parentId: id)
        case let .bundledDisconnectedBackgrounds(currentOption):
                .multiple(currentOption: currentOption,
                          options: bundledBackgroundOptions,
                          parentId: id)
        case let .bundledConnectedSounds(currentOption):
                .multiple(currentOption: currentOption,
                          options: bundledSoundsOptions,
                          parentId: id)
        case let .bundledDisconnectedSounds(currentOption):
                .multiple(currentOption: currentOption,
                          options: bundledSoundsOptions,
                          parentId: id)
        case .customNameImport:
                .buttonFile(title: "", fileTypes: [.json], parentId: id)
        case let .customNameExport(documentInfo):
                .buttonFileExport(title: "", documentInfo: documentInfo, parentId: id)
        case .customNameReset:
                .button(title: "", parentId: id)
        case let .fileContentConnect(fileName, fileTypes):
                .file(value: fileName, fileTypes: fileTypes, parentId: id)
        case let .fileContentDisconnect(fileName, fileTypes):
                .file(value: fileName, fileTypes: fileTypes, parentId: id)
        }
    }
}
