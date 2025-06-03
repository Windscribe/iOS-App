//
//  NetworkSettingsEntryTpe.swift
//  Windscribe
//
//  Created by Andre Fonseca on 29/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum NetworkSettingsEntryTpe: MenuEntryHeaderType, Hashable {
    case autoSecure(isSelected: Bool),
         preferredProtocol(isSelected: Bool,
                           protocolSelected: String, protocolOptions: [String],
                           portSelected: String, portOptions: [String]),
         forget

    var id: Int {
        switch self {
        case .autoSecure: 1
        case .preferredProtocol: 2
        case .forget: 3
        }
    }
    var title: String {
        switch self {
        case .autoSecure: TextsAsset.Connection.autoSecure
        case .preferredProtocol: TextsAsset.PreferredProtocol.title
        case .forget: ""
        }
    }
    var icon: String {
        switch self {
        case .autoSecure: ImagesAsset.Connection.autoSecure
        case .preferredProtocol: ImagesAsset.Connection.preferredProtocol
        default: ""
        }
    }
    var message: String? {
        switch self {
        case .autoSecure: TextsAsset.Connection.autoSecureSettingsDescription
        case .preferredProtocol: TextsAsset.PreferredProtocol.newDescription
        default: nil
        }
    }
    var action: MenuEntryActionType? {
        switch self {
        case let .autoSecure(isSelected), let .preferredProtocol(isSelected, _, _, _, _):
                .toggle(isSelected: isSelected, parentId: id)
        case .forget:
                .none(title: TextsAsset.forgetNetwork, parentId: id)
        }
    }
    var secondaryEntries: [MenuSecondaryEntryItem] {
        makeSecondaryEntries()
            .map {
                MenuSecondaryEntryItem(entry: $0)
            }
    }

    func makeSecondaryEntries() -> [NetworkSettingsSecondaryType] {
        switch self {
        case let .preferredProtocol(isSelected, protocolSelected, protocolOptions, portSelected, portOptions):
            if isSelected {
                return [.protocolMenu(currentOption: protocolSelected, options: protocolOptions),
                        .portMenu(currentOption: portSelected, options: portOptions)]
            }
            return []
        default:
            return []
        }
    }
}

enum NetworkSettingsSecondaryIDs: Int {
    case protocolMenu = 1,
         portMenu
    var id: Int { rawValue }
}

enum NetworkSettingsSecondaryType: MenuEntryItemType, Hashable {
    case protocolMenu(currentOption: String, options: [String]),
         portMenu(currentOption: String, options: [String])
    var id: Int {
        switch self {
        case .protocolMenu: NetworkSettingsSecondaryIDs.protocolMenu.id
        case .portMenu: NetworkSettingsSecondaryIDs.portMenu.id
        }
    }
    var title: String {
        switch self {
        case .protocolMenu: TextsAsset.Connection.protocolType
        case .portMenu: TextsAsset.Connection.port
        }
    }
    var icon: String { "" }
    var message: String? { nil }
    var action: MenuEntryActionType? {
        switch self {
        case let .protocolMenu(currentOption, options),
            let .portMenu(currentOption, options):
                .multiple(currentOption: currentOption, options: options, parentId: id)
        }
    }
}
