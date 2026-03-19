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
         circunventCensorship(isSelected: Bool, paramSelected: String, paramOptions: [MenuOption]),
         serverpede(isSelected: Bool, paramSelected: String, paramOptions: [MenuOption]),
         ipStack(
            selectedEgressOption: String, egressOptions: [MenuOption],
            selectedIngressOption: String, ingressOptions: [MenuOption]
         )

    var id: Int {
        switch self {
        case .networkOptions: 1
        case .connectionMode: 2
        case .alwaysOn: 3
        case .connectedDns: 4
        case .allowLan: 5
        case .circunventCensorship: 6
        case .serverpede: 7
        case .ipStack: 8
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
        case .serverpede: TextsAsset.Connection.useServerpede
        case .ipStack: TextsAsset.Connection.ipStack
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
        case .serverpede: ImagesAsset.Connection.circumventCensorship
        case .ipStack: ImagesAsset.Connection.preferredProtocol
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
        case .serverpede: nil
        case .ipStack: nil
        }
    }
    var action: MenuEntryActionType? {
        switch self {
        case .networkOptions: .button(title: "", parentId: id)
        case let .connectionMode(currentOption, options, _, _, _, _): .multiple(currentOption: currentOption, options: options, parentId: id)
        case let .alwaysOn(isSelected): .toggle(isSelected: isSelected, parentId: id)
        case let .connectedDns(currentOption, _, options): .multiple(currentOption: currentOption, options: options, parentId: id)
        case let .allowLan(isSelected): .toggle(isSelected: isSelected, parentId: id)
        case let .circunventCensorship(isSelected, _, _): .toggle(isSelected: isSelected, parentId: id)
        case let .serverpede(isSelected, _, _): .toggle(isSelected: isSelected, parentId: id)
        case .ipStack: .none(title: "", parentId: id)
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
        case .networkOptions:
            return [.networkOptionsInfo]
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
        case let .circunventCensorship(isSelected, paramSelected, paramOptions):
            if isSelected {
                return [.circunventCensorshipInfo, .wgUnlockMenu(currentOption: paramSelected, options: paramOptions)]
            } else {
                return [.circunventCensorshipInfo]
            }
        case let .serverpede(isSelected, paramSelected, paramOptions):
            if isSelected {
                return [.serverpedInfo, .backupMenu(currentOption: paramSelected, options: paramOptions)]
            } else {
                return [.serverpedInfo]
            }
        case let .ipStack(selectedEgress, egressOptions, selectedIngress, ingressOptions):
            return [.ipStackInfo, .egressMenu(currentOption: selectedEgress, options: egressOptions)]

        default:
            return []
        }
    }
}

enum ConnectionSecondaryEntryIDs: Int {
    case networkOptionsInfo = 100,
         connectionModeInfo,
         protocolMenu,
         portMenu,
         connectedDnsInfo,
         connectedDnsCustom,
         allowLanInfo,
         circunventCensorshipInfo,
         wgUnlockMenu,
         serverpedInfo,
         backupMenu,
         ipStackInfo,
         ipStackEgressMenu,
         ipStackIngressMenu

    var id: Int { rawValue }
}

enum ConnectionSecondaryType: MenuEntryItemType, Hashable {
    case networkOptionsInfo,
         connectionModeInfo,
         protocolMenu(currentOption: String, options: [MenuOption]),
         portMenu(currentOption: String, options: [MenuOption]),
         connectedDnsInfo,
         connectedDnsCustom(value: String),
         allowLanInfo,
         circunventCensorshipInfo,
         wgUnlockMenu(currentOption: String, options: [MenuOption]),
         serverpedInfo,
         backupMenu(currentOption: String, options: [MenuOption]),
         ipStackInfo,
         egressMenu(currentOption: String, options: [MenuOption]),
         ingressMenu(currentOption: String, options: [MenuOption])

    var id: Int {
        switch self {
        case .networkOptionsInfo:
            ConnectionSecondaryEntryIDs.networkOptionsInfo.id
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
        case .wgUnlockMenu:
            ConnectionSecondaryEntryIDs.wgUnlockMenu.id
        case .serverpedInfo:
            ConnectionSecondaryEntryIDs.serverpedInfo.id
        case .backupMenu:
            ConnectionSecondaryEntryIDs.backupMenu.id
        case .ipStackInfo:
            ConnectionSecondaryEntryIDs.ipStackInfo.id
        case .egressMenu:
            ConnectionSecondaryEntryIDs.ipStackEgressMenu.id
        case .ingressMenu:
            ConnectionSecondaryEntryIDs.ipStackIngressMenu.id
        }
    }
    var title: String {
        switch self {
        case .protocolMenu: TextsAsset.Connection.protocolType
        case .portMenu: TextsAsset.Connection.port
        case .wgUnlockMenu: TextsAsset.Connection.configuration
        case .backupMenu: TextsAsset.Connection.backup
        case .egressMenu: TextsAsset.Connection.egress
        case .ingressMenu: TextsAsset.Connection.ingress
        default: ""
        }
    }
    var icon: String { "" }
    var message: String? { nil }
    var action: MenuEntryActionType? {
        switch self {
        case .networkOptionsInfo:
                .infoLink(message: TextsAsset.Connection.networkOptionsDescription, parentId: id)
        case .connectionModeInfo:
                .infoLink(message: TextsAsset.Connection.connectionModeDescription, parentId: id)
        case let .protocolMenu(currentOption, options),
            let .portMenu(currentOption, options),
            let .egressMenu(currentOption, options),
            let .ingressMenu(currentOption, options):
                .multiple(currentOption: currentOption, options: options, parentId: id)
        case .connectedDnsInfo:
                .infoLink(message: TextsAsset.Connection.connectedDNSDescription, parentId: id)
        case let .connectedDnsCustom(value):
                .field(value: value, placeHolder: TextsAsset.Connection.connectedDNSValueFieldDescription, parentId: id)
        case .allowLanInfo:
                .infoLink(message: TextsAsset.Connection.allowLanDescription, parentId: id)
        case .circunventCensorshipInfo:
                .infoLink(message: TextsAsset.Connection.circumventCensorshipDescription, parentId: id)
        case let .wgUnlockMenu(currentOption, options):
                .multiple(currentOption: currentOption, options: options, parentId: id)
        case .serverpedInfo:
                .infoLink(message: TextsAsset.Connection.serverpedeDescription, parentId: id)
        case let .backupMenu(currentOption, options):
                .multiple(currentOption: currentOption, options: options, parentId: id)
        case .ipStackInfo:
                .infoLink(message: TextsAsset.Connection.ipStackDescription, parentId: id)

        }
    }
}
