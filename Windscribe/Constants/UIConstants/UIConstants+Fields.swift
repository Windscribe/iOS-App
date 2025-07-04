//
//  UIConstants+Fields.swift
//  Windscribe
//
//  Created by Thomas on 08/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation

enum Fields {
    static let connectionMode = "Connection Mode"
    static let protocolType = "Protocol"
    static let port = "Port"
    static let language = "Language"
    static let displayLatency = "Display Latency"
    static let orderLocationsBy = "Order Locations By"
    static let appearance = "Appearance"
    static let firewall = "Firewall"
    static let killSwitch = "Kill Switch"
    static let allowLan = "Allow Lan"
    static let autoSecureNewSwitch = "Auto Secure New Networks"
    static let configuredLocation = "ConfiguredLocation"
    static let hapticFeedback = "Haptic Feedback"
    static let showServerHealth = "Show Server Health"

    static var appearances: [String] {
        return ["Light", "Dark"]
    }

    static var connectionModes: [String] {
        [Values.auto, Values.manual]
    }

    static var connectedDNSOptions: [String] {
        [Values.auto, Values.custom]
    }

    static var orderPreferences: [String] {
        return [Values.geography, Values.alphabet, Values.latency]
    }

    enum WifiNetwork {
        static let trustStatus = "Trust Status"
        static let preferredProtocolStatus = "Pref Proto Status"
        static let preferredProtocol = "Preferred Protocol"
        static let preferredPort = "Preferred Port"
        static let dontAskAgainForPreferredProtocol = "Dont Ask Again For Preferred Protocol"
    }

    enum Values {
        static let auto = "Auto"
        static let manual = "Manual"
        static let custom = "Custom"
        static let none = "None"
        static let flag = "Flags"
        static let bundled = "Bundled"
        static let stretch = "Stretch"
        static let fill = "Fill"
        static let tile = "Tile"
        static let ms = "MS"
        static let bars = "Bars"
        static let latency = "Latency"
        static let geography = "Geography"
        static let alphabet = "Alphabet"
        static let dark = "Dark"
        static let light = "Light"
        static let bestLocation = "Best Location"
    }
}

enum ReuseIdentifiers {
    static let serverSectionCellReuseIdentifier = "server-section-cell"
    static let nodeCellReuseIdentifier = "node-cell"
    static let favNodeCellReuseIdentifier = "fav-node-cell"
    static let staticIPCellReuseIdentifier = "static-ip-cell"
    static let customConfigCellReuseIdentifier = "custom-config-cell"
    static let preferencesCellReuseIdentifier = "preferences-cell"
    static let bestLocationCellReuseIdentifier = "best-location-cell"
    static let leaderboardCellReuseIdentifier = "leaderboard-cell"
}
