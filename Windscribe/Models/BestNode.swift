//
//  BestNode.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct BestNodeModel {
    let hostname: String?
    let minTime: Int?
    let pingIp: String?

    init(hostname: String,
         minTime: Int,
         pingIp: String)
    {
        self.hostname = hostname
        self.minTime = minTime
        self.pingIp = pingIp
    }
}

@objcMembers class BestNode: Object {
    dynamic var hostname: String = ""
    dynamic var pingIp: String = ""
    dynamic var minTime: Int = 0

    convenience init(hostname: String,
                     minTime: Int,
                     pingIp: String)
    {
        self.init()
        if hostname == "" {
            self.hostname = pingIp
        } else {
            self.hostname = hostname
        }
        self.minTime = minTime
        self.pingIp = pingIp
    }

    override static func primaryKey() -> String? {
        return "hostname"
    }

    func getModel() -> BestNodeModel? {
        return BestNodeModel(hostname: hostname,
                             minTime: minTime,
                             pingIp: pingIp)
    }
}
