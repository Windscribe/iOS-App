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

extension SoundAssetDomainType {
    var tag: String {
        switch self {
        case .connect:
            return "vpnConnect"
        case .disconnect:
            return "vpnDisconnect"
        }
    }
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
    case fartDeluxe = "Fart Deluxe"
    case fart = "Fart"
    case ghostWind = "Ghost Wind"
    case popCan = "Pop Can"
    case scifi = "Sci Fi"
    case subPing = "Sub Ping"
    case sword = "Sword"
    case videoGame = "Video Game"
    case windscribe = "Windscribe"
    case wizBy = "Wiz By"

    var displayName: String {
        return rawValue
    }

    var turnOnAssetName: String {
        switch self {
        case .arcade: return "ws_button_arcadeon"
        case .boing:  return "ws_button_boingon"
        case .fartDeluxe: return "ws_button_multifarton"
        case .fart: return "ws_button_farton"
        case .ghostWind: return "ws_button_ghostwindon"
        case .popCan: return "ws_button_popcanon"
        case .scifi: return "ws_button_scifion"
        case .subPing: return "ws_button_subpingon"
        case .sword: return "ws_button_swordon"
        case .videoGame: return "ws_button_videogameon"
        case .windscribe: return "ws_button_windscribeon"
        case .wizBy: return "ws_button_wizbyon"
        }
    }

    var turnOffAssetName: String {
        switch self {
        case .arcade: return "ws_button_arcadeoff"
        case .boing:  return "ws_button_boingoff"
        case .fartDeluxe: return "ws_button_multifartoff"
        case .fart: return "ws_button_fartoff"
        case .ghostWind: return "ws_button_ghostwindoff"
        case .popCan: return "ws_button_popcanoff"
        case .scifi: return "ws_button_scifioff"
        case .subPing: return "ws_button_subpingoff"
        case .sword: return "ws_button_swordoff"
        case .videoGame: return "ws_button_videogameoff"
        case .windscribe: return "ws_button_windscribeoff"
        case .wizBy: return "ws_button_wizbyoff"
        }
    }
}
