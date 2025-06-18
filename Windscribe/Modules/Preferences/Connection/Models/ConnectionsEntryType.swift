//
//  ConnectionsEntryType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 26/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum ConnectionsEntryType: MenuEntryHeaderType, Hashable {
    case networkOptions,
         connectionMode(currentOption: String, options: [MenuOption],
                        protocolSelected: String, protocolOptions: [MenuOption],
                        portSelected: String, portOptions: [MenuOption]),
         alwaysOn(isSelected: Bool),
         connectedDns(currentOption: String, customValue: String, options: [MenuOption]),
         allowLan(isSelected: Bool),
         circunventCensorship(isSelected: Bool)

    var id: Int {
        switch self {
        case .networkOptions: 1
        case .connectionMode: 2
        case .alwaysOn: 3
        case .connectedDns: 4
        case .allowLan: 5
        case .circunventCensorship: 6
        }
    }
    var title: String {
        switch self {
        case .networkOptions: TextsAsset.Connection.networkOptions
        case .connectionMode: TextsAsset.Connection.connectionMode
        case .alwaysOn: TextsAsset.Connection.killSwitch
        case .connectedDns: TextsAsset.Connection.connectedDNS
        case .allowLan: TextsAsset.Connection.allowLan
        case .circunventCensorship: TextsAsset.Connection.circumventCensorship
        }
    }
    var icon: String {
        switch self {
        case .networkOptions: ""
        case .connectionMode: ImagesAsset.Connection.connectionMode
        case .alwaysOn: ImagesAsset.Connection.killSwitch
        case .connectedDns: ImagesAsset.Connection.connectedDNS
        case .allowLan: ImagesAsset.Connection.allowLan
        case .circunventCensorship: ImagesAsset.Connection.circumventCensorship
        }
    }
    var message: String? {
        switch self {
        case .networkOptions: nil
        case .connectionMode: nil
        case .alwaysOn: TextsAsset.Connection.killSwitchDescription
        case .connectedDns: nil
        case .allowLan: nil
        case .circunventCensorship: nil
        }
    }
    var action: MenuEntryActionType? {
        switch self {
        case .networkOptions: .button(title: "", parentId: id)
        case let .connectionMode(currentOption, options, _, _, _, _): .multiple(currentOption: currentOption, options: options, parentId: id)
        case let .alwaysOn(isSelected): .toggle(isSelected: isSelected, parentId: id)
        case let .connectedDns(currentOption, _, options): .multiple(currentOption: currentOption, options: options, parentId: id)
        case let .allowLan(isSelected): .toggle(isSelected: isSelected, parentId: id)
        case let .circunventCensorship(isSelected): .toggle(isSelected: isSelected, parentId: id)
        }
    }
    var secondaryEntries: [MenuSecondaryEntryItem] {
        makeSecondaryEntries()
            .map {
                MenuSecondaryEntryItem(entry: $0)
            }
    }

    func makeSecondaryEntries() -> [ConnectionSecondaryType] {
        switch self {
        case let .connectionMode(currentOption, _, protocolSelected, protocolOptions, portSelected, portOptions):
            if currentOption == TextsAsset.General.manual {
                return [.connectionModeInfo,
                        .protocolMenu(currentOption: protocolSelected, options: protocolOptions),
                        .portMenu(currentOption: portSelected, options: portOptions)]
            }
            return [.connectionModeInfo]
        case let .connectedDns(currentOption, customValue, _):
            if currentOption == TextsAsset.General.custom {
                let value: String = customValue.isEmpty ? TextsAsset.Connection.connectedDNSValueFieldDescription : customValue
                return [.connectedDnsInfo,
                 .connectedDnsCustom(value: value)]
            } else {
                return [.connectedDnsInfo]
            }
        case .allowLan:
            return [.allowLanInfo]
        case .circunventCensorship:
            return [.circunventCensorshipInfo]
        default:
            return []
        }
    }
}

enum ConnectionSecondaryEntryIDs: Int {
    case connectionModeInfo = 100,
         protocolMenu,
         portMenu,
         connectedDnsInfo,
         connectedDnsCustom,
         allowLanInfo,
         circunventCensorshipInfo

    var id: Int { rawValue }
}

enum ConnectionSecondaryType: MenuEntryItemType, Hashable {
    case connectionModeInfo,
         protocolMenu(currentOption: String, options: [MenuOption]),
         portMenu(currentOption: String, options: [MenuOption]),
         connectedDnsInfo,
         connectedDnsCustom(value: String),
         allowLanInfo,
         circunventCensorshipInfo

    var id: Int {
        switch self {
        case .connectionModeInfo:
            ConnectionSecondaryEntryIDs.connectionModeInfo.id
        case .protocolMenu:
            ConnectionSecondaryEntryIDs.protocolMenu.id
        case .portMenu:
            ConnectionSecondaryEntryIDs.portMenu.id
        case .connectedDnsInfo:
            ConnectionSecondaryEntryIDs.connectedDnsInfo.id
        case .connectedDnsCustom:
            ConnectionSecondaryEntryIDs.connectedDnsCustom.id
        case .allowLanInfo:
            ConnectionSecondaryEntryIDs.allowLanInfo.id
        case .circunventCensorshipInfo:
            ConnectionSecondaryEntryIDs.circunventCensorshipInfo.id
        }
    }
    var title: String {
        switch self {
        case .protocolMenu: TextsAsset.Connection.protocolType
        case .portMenu: TextsAsset.Connection.port
        default: ""
        }
    }
    var icon: String { "" }
    var message: String? { nil }
    var action: MenuEntryActionType? {
        switch self {
        case .connectionModeInfo:
                .infoLink(message: makeInfoLink(from: TextsAsset.Connection.connectionModeDescription), parentId: id)
        case let .protocolMenu(currentOption, options),
            let .portMenu(currentOption, options):
                .multiple(currentOption: currentOption, options: options, parentId: id)
        case .connectedDnsInfo:
                .infoLink(message: makeInfoLink(from: TextsAsset.Connection.connectedDNSDescription), parentId: id)
        case let .connectedDnsCustom(value):
                .field(value: value, placeHolder: TextsAsset.Connection.connectedDNSValueFieldDescription, parentId: id)
        case .allowLanInfo:
                .infoLink(message: makeInfoLink(from: TextsAsset.Connection.allowLanDescription), parentId: id)
        case .circunventCensorshipInfo:
                .infoLink(message: makeInfoLink(from: TextsAsset.Connection.circumventCensorshipDescription), parentId: id)
        }
    }
}
