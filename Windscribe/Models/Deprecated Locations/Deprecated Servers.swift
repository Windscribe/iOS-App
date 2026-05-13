//
//  Server.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-12.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@available(*, deprecated, message: "Use LocationModel instead")
@objcMembers class Server: Object {
    dynamic var id: Int = 0
    dynamic var name: String = ""
    dynamic var countryCode: String = ""
    dynamic var status: Bool = false
    dynamic var premiumOnly: Bool = false
    dynamic var shortName: String = ""
    dynamic var p2p: Bool = false
    dynamic var timezone: String = ""
    dynamic var timezoneOffset: String = ""
    dynamic var forceExpand: Bool = false
    dynamic var dnsHostname: String = ""
    var groups = List<Group>()
    dynamic var locType: String = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    func getLocationModel() -> LocationModel {
        LocationModel(id: id,
                      name: name,
                      countryCode: countryCode,
                      shortName: shortName,
                      sortOrder: 0,
                      continent: "",
                      datacenters: Array(groups).map { $0.getDatacenterModel() })
    }
}

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@available(*, deprecated, message: "Use DatacenterModel instead")
@objcMembers class Group: Object {
    dynamic var id: Int = 0
    dynamic var city: String = ""
    dynamic var nick: String = ""
    dynamic var premiumOnly: Bool = false
    dynamic var gps: String = ""
    dynamic var timezone: String = ""
    dynamic var bestNodeHostname: String = ""
    dynamic var wgPublicKey: String = ""
    dynamic var ovpnX509: String = ""
    dynamic var pingIp: String = ""
    dynamic var linkSpeed: String = ""
    dynamic var health: Int = 0
    dynamic var pingHost: String = ""
    var nodes = RealmSwift.List<Node>()

    override static func primaryKey() -> String? {
        return "id"
    }

    func getDatacenterModel() -> DatacenterModel {
        DatacenterModel(id: id,
                        city: city,
                        nick: nick,
                        iata: "",
                        status: 0,
                        gps: "",
                        tz: timezone,
                        p2p: 1,
                        isPremium: premiumOnly ? 1 : 0,
                        wgPubkey: wgPublicKey,
                        wgEndpoint: "",
                        ovpnX509: ovpnX509,
                        linkSpeed: Int(linkSpeed) ?? 0)
    }
}

@available(*, deprecated, message: "Do Not use, no replacement")
@objcMembers class Info: Object {
    dynamic var countryOverride: String?
}

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@available(*, deprecated, message: "Use Favourite instead")
@objcMembers class FavNode: Object, Decodable {
    dynamic var groupId: String = ""
}

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@objcMembers class BestLocation: Object, Decodable {
    dynamic var groupId: Int = 0
    dynamic var id = "BestLocation"

    override static func primaryKey() -> String? {
        return "id"
    }
}

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@objcMembers class BestNode: Object {
    dynamic var hostname: String = ""
    dynamic var pingIp: String = ""
    dynamic var minTime: Int = 0

    override static func primaryKey() -> String? {
        return "hostname"
    }

}
