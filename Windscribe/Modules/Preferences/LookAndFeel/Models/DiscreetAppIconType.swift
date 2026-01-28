//
//  DiscreetAppIconType.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2026-01-16.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

enum DiscreetAppIconType: String, CaseIterable, Hashable {
    case og = "OG"
    case clock = "Clock"
    case calculator = "Calculator"
    case eighty = "80"
    case vapor = "Vapor"
    case glitch = "Glitch"
    case neon = "Neon"
    case sixtyFour = "64"
    case windpass = "WindPass"
    case bsvpn = "BSVPN"
    case dittbuck = "DittBuck"

    var displayName: String {
        switch self {
        case .og:
            return "Classic"
        default:
            return rawValue
        }
    }

    var preferenceValue: String {
        return rawValue
    }

    var assetCatalogName: String {
        return "AppIcon-\(rawValue)"
    }

    var section: IconSection {
        switch self {
        case .clock, .calculator:
            return .discreet
        case .og, .eighty, .vapor, .glitch, .neon, .sixtyFour:
            return .windscribe
        case .windpass, .bsvpn, .dittbuck:
            return .other
        }
    }

    static func fromRaw(value: String) -> DiscreetAppIconType {
        return DiscreetAppIconType(rawValue: value) ?? .og
    }

    var menuOption: MenuOption {
        MenuOption(title: displayName, fieldKey: preferenceValue)
    }

    var iconImageName: String {
        switch self {
        case .og:
            return ImagesAsset.LookFeel.windscribeDefaultIcon
        case .clock:
            return ImagesAsset.LookFeel.iconClockPreview
        case .calculator:
            return ImagesAsset.LookFeel.iconCalculatorPreview
        case .eighty:
            return ImagesAsset.LookFeel.icon80Preview
        case .vapor:
            return ImagesAsset.LookFeel.iconVaporPreview
        case .glitch:
            return ImagesAsset.LookFeel.iconGlitchPreview
        case .neon:
            return ImagesAsset.LookFeel.iconNeonPreview
        case .sixtyFour:
            return ImagesAsset.LookFeel.icon64Preview
        case .windpass:
            return ImagesAsset.LookFeel.iconWindpassPreview
        case .bsvpn:
            return ImagesAsset.LookFeel.iconBsvpnPreview
        case .dittbuck:
            return ImagesAsset.LookFeel.iconDittbuckPreview
        }
    }
}

enum IconSection: String, CaseIterable {
    case discreet = "Discreet"
    case windscribe = "Windscribe"
    case other = "Other"

    var title: String {
        return rawValue
    }

    func icons(from allIcons: [DiscreetAppIconType]) -> [DiscreetAppIconType] {
        return allIcons.filter { $0.section == self }
    }
}
