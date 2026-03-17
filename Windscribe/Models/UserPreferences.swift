//
//  UserPreferences.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-19.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

// NOTE: This class is only ever used in Migration it no longer needs any implementation
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
    dynamic var showServerNetLoad: Bool = false
    dynamic var protocolType: String = ""
    dynamic var port: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }
}
