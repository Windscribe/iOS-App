//
//  BackgroundEffectType.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-22.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum BackgroundAssetDomainType {
    case aspectRatio
    case connect
    case disconnect
}

enum BackgroundAspectRatioType: String, CaseIterable {
    case stretch
    case fill
    case tile

    init(aspectRatioType: String) {
        switch aspectRatioType {
        case TextsAsset.General.stretch:
            self = .stretch
        case TextsAsset.General.fill:
           self = .fill
        case TextsAsset.General.tile:
            self = .tile
        default:
            self = .stretch
        }
    }

    var preferenceValue: String {
        switch self {
        case .stretch:
            return Fields.Values.stretch
        case .fill:
            return Fields.Values.fill
        case .tile:
            return Fields.Values.tile
        }
    }

    var category: String {
        switch self {
        case .stretch:
            return TextsAsset.General.stretch
        case .fill:
            return TextsAsset.General.fill
        case .tile:
            return TextsAsset.General.tile
        }
    }

    var menuOption: MenuOption {
        switch self {
        case .stretch:
            return MenuOption(title: TextsAsset.General.stretch,
                              fieldKey: Fields.Values.stretch)
        case .fill:
            return MenuOption(title: TextsAsset.General.fill,
                              fieldKey: Fields.Values.fill)
        case .tile:
            return MenuOption(title: TextsAsset.General.tile,
                              fieldKey: Fields.Values.tile)
        }
    }
}

enum BackgroundEffectType: Hashable {
    case none
    case flag
    case bundled(subtype: BackgroundEffectSubtype)
    case custom

    init(mainCategory: String, subtypeTitle: String? = nil) {
        switch mainCategory {
        case Fields.Values.none:
            self = .none
        case Fields.Values.flag:
            self = .flag
        case Fields.Values.bundled:
            if let subtypeTitle = subtypeTitle {
                let subtype = BackgroundEffectSubtype(rawValue: subtypeTitle) ?? .square
                self = .bundled(subtype: subtype)

            } else {
                self = .bundled(subtype: .square)
                return
            }
        case Fields.Values.custom:
            self = .custom
        default:
            self = .flag
        }
    }

    var mainCategory: String {
        switch self {
        case .none:
            return TextsAsset.General.none
        case .flag:
            return TextsAsset.General.flag
        case .bundled:
            return TextsAsset.General.bundled
        case .custom:
            return TextsAsset.General.custom
        }
    }

    var bundledSubtype: BackgroundEffectSubtype? {
        if case .bundled(let subtype) = self {
            return subtype
        }
        return nil
    }
}

extension BackgroundEffectType {
    static func fromRaw(value: String) -> BackgroundEffectType {
        if value == Fields.Values.none {
            return .none
        } else if value == Fields.Values.flag {
            return .flag
        } else if value == Fields.Values.custom {
            return .custom
        } else if let subtype = BackgroundEffectSubtype(rawValue: value) {
            return .bundled(subtype: subtype)
        } else {
            return .flag
        }
    }

    var preferenceValue: String {
        switch self {
        case .none:
            return Fields.Values.none
        case .flag:
            return Fields.Values.flag
        case .custom:
            return Fields.Values.custom
        case .bundled(let subtype):
            return subtype.rawValue
        }
    }
}

extension BackgroundEffectType: Equatable {
    static func == (lhs: BackgroundEffectType, rhs: BackgroundEffectType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.custom, .custom):
            return true
        case let (.bundled(a), .bundled(b)):
            return a == b
        default:
            return false
        }
    }
}

enum BackgroundEffectSubtype: String, CaseIterable {
    case square = "Square"
    case palm = "Palm"
    case city = "City"
    case stars = "Drip"
    case windscribe = "Windscribe"

    var displayName: String {
        rawValue
    }

    var assetName: String {
        switch self {
        case .square: return "bg_square"
        case .palm: return "bg_palm"
        case .city: return "bg_city"
        case .stars: return "bg_stars"
        case .windscribe: return "bg_windscribe"
        }
    }

    var menuOption: MenuOption {
        MenuOption(title: rawValue, fieldKey: rawValue)
    }
}
