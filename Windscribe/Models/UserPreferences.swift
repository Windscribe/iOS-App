//
//  UserPreferences.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-19.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Realm

@objcMembers class UserPreferences: Object {
    dynamic var id: String = "1"
    dynamic var connectionMode: String = ""
    dynamic var language: String = ""
    dynamic var latencyType: String = ""
    dynamic var orderLocationsBy: String = ""
    dynamic var appearance: String = ""
    dynamic var firewall: Bool = true
    dynamic var killSwitch: Bool = false
    dynamic var allowLan: Bool = false
    dynamic var autoSecureNewNetworks: Bool = true
    dynamic var hapticFeedback: Bool = true
    dynamic var showServerHealth: Bool = false
    dynamic var protocolType: String = ""
    dynamic var port: String = ""

    convenience init(connectionMode: String,
                     language: String,
                     latencyType: String,
                     orderLocationsBy: String,
                     protocolType: String,
                     port: String,
                     appearance: String,
                     firewall: Bool,
                     killSwiitch: Bool,
                     allowLan: Bool,
                     autoSecureNewNetworks: Bool,
                     hapticFeedback: Bool,
                     showServerHealth: Bool) {
        self.init()
        self.connectionMode = connectionMode
        self.language = language
        self.latencyType = latencyType
        self.orderLocationsBy = orderLocationsBy
        self.appearance = appearance
        self.firewall = firewall
        self.killSwitch = killSwiitch
        self.allowLan = allowLan
        self.autoSecureNewNetworks = autoSecureNewNetworks
        self.hapticFeedback = hapticFeedback
        self.protocolType = protocolType
        self.port = port
        self.showServerHealth = showServerHealth
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}
