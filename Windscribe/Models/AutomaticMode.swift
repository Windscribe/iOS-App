//
//  AutomaticMode.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@objcMembers class AutomaticMode: Object, Decodable {
    static let shared: AutomaticMode = .init()
    dynamic var SSID: String = ""
    dynamic var ikev2Failed: Int = 0
    dynamic var udpFailed: Int = 0
    dynamic var tcpFailed: Int = 0
    dynamic var wgFailed: Int = 0
    dynamic var wsTunnelFailed: Int = 0
    dynamic var stealthFailed: Int = 0

    override static func primaryKey() -> String? {
        return "SSID"
    }
}
