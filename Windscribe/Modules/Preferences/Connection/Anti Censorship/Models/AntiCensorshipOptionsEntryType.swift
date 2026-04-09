//
//  AntiCensorshipOptionsEntryType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 24/03/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

enum AntiCensorshipOptionsEntryType: MenuEntryHeaderType, Hashable {
    case info,
         protocolTweaks(isSelected: Bool, paramSelected: String, paramOptions: [MenuOption]),
         routingType(selectedRoutingType: String, routingOptions: [MenuOption])

    var id: Int {
        switch self {
        case .info: 1
        case .protocolTweaks: 2
        case .routingType: 3
        }
    }

    var title: String {
        switch self {
        case .info: ""
        case .protocolTweaks: TextsAsset.Connection.circumventCensorship
        case .routingType: TextsAsset.Connection.serverRouting
        }
    }

    var icon: String {
        switch self {
        case .info: ""
        case .protocolTweaks: ImagesAsset.Connection.circumventCensorship
        case .routingType: ""
        }
    }

    var message: String? { nil }

    var action: MenuEntryActionType? {
        switch self {
        case let .protocolTweaks(isSelected, _, _):
                .toggle(isSelected: isSelected, parentId: id)
        case let .routingType(selectedRoutingType, routingOptions):
                .multiple(currentOption: selectedRoutingType, options: routingOptions, parentId: id)
        default: nil
        }
    }

    var secondaryEntries: [MenuSecondaryEntryItem] {
        makeSecondaryEntries()
            .map {
                MenuSecondaryEntryItem(entry: $0)
            }
    }

    func makeSecondaryEntries() -> [AntiCensorshipOptionsSecondaryType] {
        switch self {
        case .info: return [.circumventCensorshipInfo]
        case let .protocolTweaks(isSelected, paramSelected, paramOptions):
            if isSelected {
                return [.protocolTweaksInfo,
                        .wgUnlockMenu(currentOption: paramSelected, options: paramOptions)]
            } else {
                return [.protocolTweaksInfo]
            }
        case let .routingType(selectedRoutingType, routingOptions):
            return [.serverpedeInfo]
        }
    }
}

enum AntiCensorshipOptionsSecondaryIDs: Int {
    case circumventCensorshipInfo = 100,
         protocolTweaksInfo,
         wgUnlockMenu,
         serverpedeInfo

    var id: Int { rawValue }
}

enum AntiCensorshipOptionsSecondaryType: MenuEntryItemType, Hashable {
    case circumventCensorshipInfo,
         protocolTweaksInfo,
         wgUnlockMenu(currentOption: String, options: [MenuOption]),
         serverpedeInfo

    var id: Int {
        switch self {
        case .circumventCensorshipInfo:
            AntiCensorshipOptionsSecondaryIDs.circumventCensorshipInfo.id
        case .protocolTweaksInfo:
            AntiCensorshipOptionsSecondaryIDs.protocolTweaksInfo.id
        case .wgUnlockMenu:
            AntiCensorshipOptionsSecondaryIDs.wgUnlockMenu.id
        case .serverpedeInfo:
            AntiCensorshipOptionsSecondaryIDs.serverpedeInfo.id
        }
    }

    var title: String {
        switch self {
        case .circumventCensorshipInfo: ""
        case .protocolTweaksInfo: ""
        case .wgUnlockMenu: TextsAsset.Connection.configuration
        case .serverpedeInfo: ""
        }
    }

    var icon: String { "" }

    var message: String? { nil }

    var action: MenuEntryActionType? {
        switch self {
        case .circumventCensorshipInfo:
                .infoLink(message: TextsAsset.Connection.antiCensorshipInfoDescription, parentId: id)
        case .protocolTweaksInfo:
                .infoLink(message: TextsAsset.Connection.protocolTweaksDescription, parentId: id)
        case let .wgUnlockMenu(currentOption, options):
                .multiple(currentOption: currentOption, options: options, parentId: id)
        case .serverpedeInfo:
                .infoLink(message: TextsAsset.Connection.serverRoutingDescription, parentId: id)
        }
    }
}
