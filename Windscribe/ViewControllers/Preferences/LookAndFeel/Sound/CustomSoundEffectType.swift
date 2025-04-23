//
//  CustomSoundEffectType.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-04-15.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum SoundAssetDomainType {
    case connect
    case disconnect
}

enum SoundEffectType {
    case none
    case bundled(subtype: SoundEffectSubtype)
    case custom

    init(mainCategory: String, subtypeTitle: String? = nil) {
        switch mainCategory {
        case TextsAsset.General.none:
            self = .none
        case TextsAsset.General.bundled:
            if let subtypeTitle = subtypeTitle {
                let subtype = SoundEffectSubtype(rawValue: subtypeTitle) ?? .arcade
                self = .bundled(subtype: subtype)

            } else {
                self = .bundled(subtype: .arcade)
                return
            }
        case TextsAsset.General.custom:
            self = .custom
        default:
            self = .none
        }
    }

    var mainCategory: String {
        switch self {
        case .none:
            return TextsAsset.General.none
        case .bundled:
            return TextsAsset.General.bundled
        case .custom:
            return TextsAsset.General.custom
        }
    }

    var bundledSubtype: SoundEffectSubtype? {
        switch self {
        case .bundled(let subtype):
            return subtype
        default:
            return nil
        }
    }
}

extension SoundEffectType {
    static func fromRaw(value: String) -> SoundEffectType {
        if value == Fields.Values.none {
            return .none
        } else if value == Fields.Values.custom {
            return .custom
        } else if let subtype = SoundEffectSubtype(rawValue: value) {
            return .bundled(subtype: subtype)
        } else {
            return .none
        }
    }

    var preferenceValue: String {
        switch self {
        case .none:
            return Fields.Values.none
        case .custom:
            return Fields.Values.custom
        case .bundled(let subtype):
            return subtype.rawValue
        }
    }
}

extension SoundEffectType: Equatable {
    static func == (lhs: SoundEffectType, rhs: SoundEffectType) -> Bool {
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

enum SoundEffectSubtype: String, CaseIterable {
    case arcade = "Arcade"
    case boing = "Boing"
    case fart = "Fart"
    case sword = "Sword"
    case windscribe = "Windscribe"

    var displayName: String {
        return rawValue
    }

    var assetName: String {
        switch self {
        case .arcade: return "arcade_sound.mp3"
        case .boing: return "boing_sound.mp3"
        case .fart: return "fart_sound.mp3"
        case .sword: return "sword_sound.mp3"
        case .windscribe: return "windscribe_sound.mp3"
        }
    }
}
