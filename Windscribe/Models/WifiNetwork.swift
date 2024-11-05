//
//  WifiNetwork.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-05.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class WifiNetwork: Object, Decodable {
    dynamic var SSID: String = ""
    dynamic var status: Bool = false
    dynamic var protocolType: String = wireGuard
    dynamic var port: String = "443"
    dynamic var preferredProtocolStatus: Bool = false
    dynamic var preferredProtocol: String = wireGuard
    dynamic var preferredPort: String = "443"
    dynamic var popupDismissCount: Int = 0
    dynamic var dontAskAgainForPreferredProtocol: Bool = false

    var textualStatus: String {
        return status ? TextsAsset.NetworkSecurity.trusted : TextsAsset.NetworkSecurity.untrusted
    }

    convenience init(SSID: String,
                     status: Bool,
                     protocolType: String,
                     port: String,
                     preferredProtocol: String,
                     preferredPort: String,
                     preferredProtocolStatus: Bool = false)
    {
        self.init()
        self.SSID = SSID
        self.status = status
        self.protocolType = protocolType
        self.port = port
        self.preferredProtocol = preferredProtocol
        self.preferredPort = preferredPort
        self.preferredProtocolStatus = preferredProtocolStatus
    }

    override static func primaryKey() -> String? {
        return "SSID"
    }
}
