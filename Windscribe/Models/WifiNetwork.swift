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

protocol WifiNetworkProtocol: Equatable {
    var SSID: String { get }
    var status: Bool { get }
    var protocolType: String { get }
    var port: String { get }
    var preferredProtocolStatus: Bool { get }
    var preferredProtocol: String { get }
    var preferredPort: String { get }
    var popupDismissCount: Int { get }
    var dontAskAgainForPreferredProtocol: Bool { get }
}

@objcMembers class WifiNetwork: Object, WifiNetworkProtocol, Decodable {
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
                     preferredProtocolStatus: Bool = false) {
        self.init()
        self.SSID = SSID
        self.status = status
        self.protocolType = protocolType
        self.port = port
        self.preferredProtocol = preferredProtocol
        self.preferredPort = preferredPort
        self.preferredProtocolStatus = preferredProtocolStatus
    }

    convenience init(from: any WifiNetworkProtocol) {
        self.init()
        self.SSID = from.SSID
        self.status = from.status
        self.protocolType = from.protocolType
        self.port = from.port
        self.preferredProtocolStatus = from.preferredProtocolStatus
        self.preferredProtocol = from.preferredProtocol
        self.preferredPort = from.preferredPort
        self.popupDismissCount = from.popupDismissCount
        self.dontAskAgainForPreferredProtocol = from.dontAskAgainForPreferredProtocol
    }

    override static func primaryKey() -> String? {
        return "SSID"
    }
}

struct WifiNetworkModel: WifiNetworkProtocol, Hashable {
    var SSID: String
    var status: Bool
    var protocolType: String
    var port: String
    var preferredProtocolStatus: Bool
    var preferredProtocol: String
    var preferredPort: String
    var popupDismissCount: Int
    var dontAskAgainForPreferredProtocol: Bool

    init(from: any WifiNetworkProtocol) {
        self.init(SSID: from.SSID,
                  status: from.status,
                  protocolType: from.protocolType,
                  port: from.port,
                  preferredProtocol: from.preferredProtocol,
                  preferredPort: from.preferredPort,
                  preferredProtocolStatus: from.preferredProtocolStatus)
        self.popupDismissCount = from.popupDismissCount
        self.dontAskAgainForPreferredProtocol = from.dontAskAgainForPreferredProtocol
    }

    init(SSID: String,
         status: Bool,
         protocolType: String,
         port: String,
         preferredProtocol: String,
         preferredPort: String,
         preferredProtocolStatus: Bool = false) {
        self.SSID = SSID
        self.status = status
        self.protocolType = protocolType
        self.port = port
        self.preferredProtocol = preferredProtocol
        self.preferredPort = preferredPort
        self.preferredProtocolStatus = preferredProtocolStatus
        self.popupDismissCount = 0
        self.dontAskAgainForPreferredProtocol = false
    }
}

enum WifiNetworkValues {
    case status(value: Bool)
    case protocolType(value: String)
    case port(value: String)
    case preferredProtocol(value: String)
    case preferredPort(value: String)
    case preferredProtocolStatus(value: Bool)
    case popupDismissCount(value: Int)
    case dontAskAgainForPreferredProtocol(value: Bool)
}
