//
//  DefaultValues.swift
//  Windscribe
//
//  Created by Bushra Sagir on 2024-01-08.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

enum DefaultValues {
    static let latencyType = "Bars"
    static let orderLocationsBy = "Geography"
    static let appSkin = "Alpha"
    static let appearance = "Dark"
    static let language = "English"
    static let `protocol` = "WireGuard"
    static let port = "443"
    static let connectedDNS = "Auto"
    static let connectionMode = "Auto"
    static let appID = "1129435228"
    static let customDNSValue = DNSValue(type: .empty, value: "", servers: [])
    static let darkMode = true
    static let serverHealth = false
    static let firewallMode = true
    static let killSwitch = false
    static let allowLANMode = false
    static let autoSecureNewNetworks = true
    static let hapticFeedback = true
    static let showServerHealth = false
    static let circumventCensorship = false
    static let aspectRatio = "Stretch"
}
