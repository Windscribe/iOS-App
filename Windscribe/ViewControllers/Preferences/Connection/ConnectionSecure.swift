//
//	ConnectionSecure.swift
//	Windscribe
//
//	Created by Thomas on 24/05/2022.
//	Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

enum ConnectionSecure {
    case firewall
    case killSwitch
    case allowLan
    case autoSecure
    case locationLoad
    case hapticFeeback
    case circumventCensorship

    var title: String {
        switch self {
        case .firewall:
            return TextsAsset.firewall
        case .killSwitch:
            return TextsAsset.killSwitch
        case .allowLan:
            return TextsAsset.allowLan
        case .autoSecure:
            return TextsAsset.autoSecureNew
        case .locationLoad:
            return TextsAsset.General.showServerHealth
        case .hapticFeeback:
            return TextsAsset.General.hapticFeedback
        case .circumventCensorship:
            return TextsAsset.circumventCensorship
        }
    }

    var description: String {
        switch self {
        case .firewall:
            return TextsAsset.firewallDescription
        case .killSwitch:
            return TextsAsset.killSwitchDescription
        case .allowLan:
            return TextsAsset.allowLanDescription
        case .autoSecure:
            return TextsAsset.autoSecureNewDescription
        case .locationLoad:
            return "Explain me!".localize()
        case .hapticFeeback:
            return "Explain me!".localize()
        case .circumventCensorship:
            return TextsAsset.circumventCensorshipDescription
        }
    }
}
