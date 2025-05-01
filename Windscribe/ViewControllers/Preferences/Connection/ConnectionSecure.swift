//
//    ConnectionSecure.swift
//    Windscribe
//
//    Created by Thomas on 24/05/2022.
//    Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

enum ConnectionSecure {
    case firewall
    case killSwitch
    case allowLan
    case autoSecure
    case hapticFeeback
    case circumventCensorship
    case connectedDNS
    case customBackground

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
        case .hapticFeeback:
            return TextsAsset.General.hapticFeedback
        case .circumventCensorship:
            return TextsAsset.circumventCensorship
        case .connectedDNS:
            return TextsAsset.connectedDNS
        case .customBackground:
            return TextsAsset.General.customBackground
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
        case .hapticFeeback:
            return "Explain me!".localized
        case .circumventCensorship:
            return TextsAsset.circumventCensorshipDescription
        case .connectedDNS:
            return TextsAsset.connectedDNSDescription
        case .customBackground:
            return TextsAsset.PreferencesDescription.customBackground
        }
    }
}
