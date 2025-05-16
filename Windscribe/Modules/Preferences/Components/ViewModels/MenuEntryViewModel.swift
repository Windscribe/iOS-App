//
//  MenuEntryViewModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 06/05/2025.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum MenuEntryActionType: Hashable {
    case multiple(currentOption: String, options: [String])
    case single(isSelected: Bool)
    case button(title: String?)
    case link(title: String?)
    case secondary(title: String?)
    case info(title: String?)
    case none(title: String)

    var imageName: String? {
        switch self {
        case .multiple:
            ImagesAsset.DarkMode.dropDownIcon
        case let .single(isSelected):
            isSelected ? ImagesAsset.SwitchButton.on : ImagesAsset.SwitchButton.off
        case .button, .secondary:
            ImagesAsset.serverWhiteRightArrow
        case .link:
            ImagesAsset.externalLink
        default:
            nil
        }
    }
}

protocol MenuEntryItemType: Hashable {
    var id: Int { get }
    var title: String { get }
    var icon: String { get }
    var message: String? { get }
    var mainAction: MenuEntryActionType? { get }
    var secondaryAction: [MenuEntryActionType] { get }
}
