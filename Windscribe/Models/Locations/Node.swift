//
//  Node.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-12.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct NodeModel: Equatable {
    let ip1: String
    let ip2: String
    let ip3: String
    let hostname: String
    let dnsHostname: String
    let forceDisconnect: Bool
    let weight: Int
}

@objcMembers class Node: Object, Decodable {
    dynamic var ip: String = ""
    dynamic var ip2: String = ""
    dynamic var ip3: String = ""
    dynamic var hostname: String = ""
    dynamic var dnsHostname: String = ""
    dynamic var weight: Int = 0
    dynamic var group: String = ""
    dynamic var gps: String = ""
    dynamic var forceDisconnect: Bool = false

    enum CodingKeys: String, CodingKey {
        case ip
        case ip2
        case ip3
        case hostname
        case dnsHostname = "dns_hostname"
        case weight
        case group
        case gps
        case forceDisconnect = "force_disconnect"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        ip = try container.decodeIfPresent(String.self, forKey: .ip) ?? ""
        ip2 = try container.decodeIfPresent(String.self, forKey: .ip2) ?? ""
        ip3 = try container.decodeIfPresent(String.self, forKey: .ip3) ?? ""
        hostname = try container.decodeIfPresent(String.self, forKey: .hostname) ?? ""
        dnsHostname = try container.decodeIfPresent(String.self, forKey: .dnsHostname) ?? ""
        weight = try container.decodeIfPresent(Int.self, forKey: .weight) ?? 0
        group = try container.decodeIfPresent(String.self, forKey: .group) ?? ""
        gps = try container.decodeIfPresent(String.self, forKey: .gps) ?? ""
        forceDisconnect = try container.decodeIfPresent(Int.self, forKey: .forceDisconnect) == 1 ? true : false
    }

    func getNodeModel() -> NodeModel {
        return NodeModel(ip1: ip,
                         ip2: ip2,
                         ip3: ip3,
                         hostname: hostname,
                         dnsHostname: dnsHostname,
                         forceDisconnect: forceDisconnect,
                         weight: weight)
    }
}

class StaticIPNode: Node {}

@objcMembers class Favourite: Object, Decodable {
    @Persisted(primaryKey: true) var id: String
    @Persisted var pinnedIp: String?
    @Persisted var pinnedNodeIp: String?

    convenience init(id: String,
                     pinnedIp: String? = nil,
                     pinnedNodeIp: String? = nil) {
        self.init()
        self.id = id
        self.pinnedIp = pinnedIp
        self.pinnedNodeIp = pinnedNodeIp
    }

    convenience init(from: FavouriteModel) {
        self.init()
        self.id = from.id
        self.pinnedIp = from.pinnedIp
        self.pinnedNodeIp = from.pinnedNodeIp
    }

    func getModel() -> FavouriteModel {
        .init(from: self)
    }
}

struct FavouriteModel: Equatable {
    let id: String
    let pinnedIp: String?
    let pinnedNodeIp: String?

    init(from: Favourite) {
        self.id = from.id
        self.pinnedIp = from.pinnedIp
        self.pinnedNodeIp = from.pinnedNodeIp
    }

    init(id: String,
         pinnedIp: String? = nil,
         pinnedNodeIp: String? = nil) {
        self.id = id
        self.pinnedIp = pinnedIp
        self.pinnedNodeIp = pinnedNodeIp
    }

    func getObject() -> Favourite {
        .init(from: self)
    }
}

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@available(*, deprecated, message: "Use Favourite instead")
@objcMembers class FavNode: Object, Decodable {
    dynamic var groupId: String = ""
    dynamic var serverName: String = ""
    dynamic var countryCode: String = ""
    dynamic var hostname: String = ""
    dynamic var cityName: String = ""
    dynamic var nickName: String = ""
    dynamic var dnsHostname: String = ""
    dynamic var ipAddress: String = ""
    dynamic var customConfigId: String?
    dynamic var isPremiumOnly: Bool = false
    dynamic var pingIp: String = ""
    dynamic var pingHost: String = ""
    dynamic var linkSpeed: String = ""
    dynamic var health: Int = 0
}

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@available(*, deprecated, message: "Don't use it anymore it is here for old data migration purposes only")
class LastConnectedNode: FavNode { }

struct BestLocationModel {
    let serverName: String
    let countryCode: String
    let hostname: String?
    let cityName: String
    let nickName: String
    let dnsHostname: String
    let ipAddress: String?
    let groupId: Int
    let linkSpeed: String
    let health: Int

    init(node: NodeModel, group: GroupModel, server: ServerModel) {
        serverName = group.city
        countryCode = server.countryCode
        hostname = node.hostname
        cityName = group.city
        nickName = group.nick
        dnsHostname = server.dnsHostname
        ipAddress = node.ip2
        groupId = group.id
        linkSpeed = group.linkSpeed
        health = group.health
    }
}

// NOTE: This class is only ever used in Migration it no longer needs any implementation
@objcMembers class BestLocation: Object, Decodable {
    dynamic var serverName: String = ""
    dynamic var countryCode: String = ""
    dynamic var hostname: String = ""
    dynamic var cityName: String = ""
    dynamic var nickName: String = ""
    dynamic var dnsHostname: String = ""
    dynamic var ipAddress: String = ""
    dynamic var groupId: Int = 0
    dynamic var linkSpeed: String = "1000"
    dynamic var health: Int = 0
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
