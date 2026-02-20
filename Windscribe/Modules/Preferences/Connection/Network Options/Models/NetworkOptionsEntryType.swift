//
//  NetworkOptionsEntryType.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

struct NetworkEntryInfo: Hashable {
    let name: String
    let isSecured: Bool
}

enum NetworkOptionsEntryType: MenuEntryHeaderType, Hashable {
    case autoSecure(isSelected: Bool),
         network(info: NetworkEntryInfo),
         networkList(info: NetworkEntryInfo, otherNetworks: [NetworkEntryInfo])

    var id: Int {
        switch self {
        case .autoSecure: 1
        case .network: 2
        case .networkList: 3
        }}
    var title: String {
        switch self {
        case .autoSecure: TextsAsset.Connection.autoSecureNew
        case .network(let info), .networkList(let info, _): info.name
        }
    }
    var icon: String {
        switch self {
        case .autoSecure: ImagesAsset.Connection.autoSecure
        default: ""
        }
    }
    var message: String? { nil }
    var action: MenuEntryActionType? {
        switch self {
        case let .autoSecure(isSelected):
                .toggle(isSelected: isSelected, parentId: id)
        case let .network(info), let .networkList(info, _):
                .button(title: info.isSecured ? TextsAsset.NetworkSecurity.trusted : TextsAsset.NetworkSecurity.untrusted,
                        parentId: id)
        }
    }
    var secondaryEntries: [MenuSecondaryEntryItem] {
        makeSecondaryEntries()
            .map {
                MenuSecondaryEntryItem(entry: $0)
            }
    }

    func makeSecondaryEntries() -> [NetworkOptionsSecondaryType] {
        switch self {
        case .autoSecure:
            return [.autoSecureInfo]
        case let .networkList(_, otherNetworks):
            return otherNetworks.enumerated().map { .network(info: $1, index: $0) }
        default:
            return []
        }
    }
}

enum NetworkOptionsSecondaryType: MenuEntryItemType, Hashable {
    case autoSecureInfo,
         network(info: NetworkEntryInfo, index: Int)
    var id: Int {
        switch self {
        case .autoSecureInfo:
            return 10
        case let .network(_ , index):
            return index * 20
        }
    }
    var title: String {
        switch self {
        case .autoSecureInfo: ""
        case .network(let info, _): info.name
        }
    }
    var icon: String { "" }
    var message: String? { nil }

    var action: MenuEntryActionType? {
        switch self {
        case .autoSecureInfo:
                .infoLink(message: TextsAsset.Connection.autoSecureNewDescription, parentId: id)
        case let .network(info, _):
                .button(title: info.isSecured ? TextsAsset.NetworkSecurity.trusted : TextsAsset.NetworkSecurity.untrusted,
                        parentId: id)
        }
    }
}
