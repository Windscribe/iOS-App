//
//  AutomaticMode.swift
//  Windscribe
//
//  Created by Yalcin on 2019-05-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Realm
import Swinject

@objcMembers class AutomaticMode: Object, Decodable {
    static let shared: AutomaticMode = AutomaticMode()
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

    func increaseFailCount(type: String) {
        let logger = Assembler.resolve(FileLogger.self)
        logger.logD(self, "Automatic Connection Mode: Increase fail count for \(type)")
        switch type {
        case TextsAsset.General.protocols[0]:
            wgFailed += 1
        case TextsAsset.General.protocols[1]:
            ikev2Failed += 1
        case TextsAsset.General.protocols[2]:
            udpFailed += 1
        case TextsAsset.General.protocols[3]:
            tcpFailed += 1
        case TextsAsset.General.protocols[4]:
            stealthFailed += 1
        case TextsAsset.General.protocols[5]:
            wsTunnelFailed += 1
        default:
            return
        }
    }

    func resetFailCounts() {
        ikev2Failed = 0
        udpFailed = 0
        tcpFailed = 0
        wgFailed = 0
        wsTunnelFailed = 0
        stealthFailed = 0

    }
}
