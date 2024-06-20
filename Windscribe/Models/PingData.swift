//
//  PingData.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-12.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
@objcMembers class PingData: Object {
    dynamic var ip: String = ""
    dynamic var latency = -1

    convenience init(ip: String, latency: Int) {
        self.init()
        self.ip = ip
        self.latency = latency
    }

    override static func primaryKey() -> String? {
        return "ip"
    }
    override var description: String {
        return "IP: \(ip) Latency: \(latency)"
    }
}
