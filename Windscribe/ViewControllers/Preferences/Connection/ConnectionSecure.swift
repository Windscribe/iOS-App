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
            return TextsAsset.Connection.killSwitch
        case .allowLan:
            return TextsAsset.Connection.allowLan
        case .autoSecure:
            return TextsAsset.Connection.autoSecureNew
        case .hapticFeeback:
            return TextsAsset.General.hapticFeedback
        case .circumventCensorship:
            return TextsAsset.Connection.circumventCensorship
        case .connectedDNS:
            return TextsAsset.Connection.connectedDNS
        case .customBackground:
            return TextsAsset.General.customBackground
        }
    }

    var description: String {
        switch self {
        case .firewall:
            return TextsAsset.firewallDescription
        case .killSwitch:
            return TextsAsset.Connection.killSwitchDescription
        case .allowLan:
            return TextsAsset.Connection.allowLanDescription
        case .autoSecure:
            return TextsAsset.Connection.autoSecureNewDescription
        case .hapticFeeback:
            return "Explain me!".localized
        case .circumventCensorship:
            return TextsAsset.Connection.circumventCensorshipDescription
        case .connectedDNS:
            return TextsAsset.Connection.connectedDNSDescription
        case .customBackground:
            return TextsAsset.PreferencesDescription.customBackground
        }
    }
}
