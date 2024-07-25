//
//  Node.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-12.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct NodeModel {
    let ip1: String?
    let ip2: String?
    let ip3: String?
    let hostname: String?
    let dnsHostname: String?
    let forceDisconnect: Bool

    init(
        ip1: String,
        ip2: String,
        ip3: String,
        hostname: String,
        dnsHostname: String,
        forceDisconnect: Bool) {
            self.ip1 = ip1
            self.ip2 = ip2
            self.ip3 = ip3
            self.hostname = hostname
            self.dnsHostname = dnsHostname
            self.forceDisconnect = forceDisconnect
    }
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
        case ip = "ip"
        case ip2 = "ip2"
        case ip3 = "ip3"
        case hostname = "hostname"
        case dnsHostname = "dns_hostname"
        case weight = "weight"
        case group = "group"
        case gps = "gps"
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
        gps = try container.decodeIfPresent(String.self, forKey: .gps)  ?? ""
        forceDisconnect = try container.decodeIfPresent(Int.self, forKey: .forceDisconnect)  == 1 ? true : false
    }

    func getNodeModel() -> NodeModel {
        return NodeModel(ip1: ip,
                         ip2: ip2,
                         ip3: ip3,
                         hostname: hostname,
                         dnsHostname: dnsHostname,
                         forceDisconnect: forceDisconnect)
    }

}

class StaticIPNode: Node {}

struct FavNodeModel {

    let groupId: String?
    let serverName: String?
    let countryCode: String?
    let hostname: String?
    let cityName: String?
    let nickName: String?
    let dnsHostname: String?
    let ipAddress: String?
    let pingIp: String?
    let linkSpeed: String?
    let health: Int?
    let isPremiumOnly: Bool?

    init(groupId: String,
         serverName: String,
         countryCode: String,
         hostname: String,
         cityName: String,
         nickName: String,
         dnsHostname: String,
         ipAddress: String,
         pingIp: String,
         linkSpeed: String,
         health: Int,
         isPremiumOnly: Bool) {
        self.groupId = groupId
        self.serverName = serverName
        self.countryCode = countryCode
        self.hostname = hostname
        self.cityName = cityName
        self.nickName = nickName
        self.dnsHostname = dnsHostname
        self.ipAddress = ipAddress
        self.pingIp = pingIp
        self.linkSpeed = linkSpeed
        self.health = health
        self.isPremiumOnly = isPremiumOnly
    }

    init(node: NodeModel,
         group: GroupModel,
         server: ServerModel) {
        if let groupId = group.id {
            self.groupId = "\(groupId)"
        } else {
            self.groupId = node.hostname
        }
        self.serverName = group.city
        self.countryCode = server.countryCode
        self.hostname = node.hostname
        self.cityName = group.city
        self.nickName = group.nick
        self.dnsHostname = server.dnsHostname
        self.ipAddress = node.ip2
        self.pingIp = group.pingIp
        self.linkSpeed = group.linkSpeed
        self.health = group.health
        self.isPremiumOnly = group.premiumOnly
    }

}

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

    convenience init(node: Node,
                     group: Group,
                     server: Server) {
        self.init()
        self.groupId = "\(group.id)"
        self.serverName = server.name
        self.countryCode = server.countryCode
        self.hostname = node.hostname
        self.cityName = group.city
        self.nickName = group.nick
        self.dnsHostname = server.dnsHostname
        self.ipAddress = node.ip2
        self.pingIp = group.pingIp
        self.pingHost = group.pingHost
        self.linkSpeed = group.linkSpeed
        self.health = group.health
        self.isPremiumOnly = group.premiumOnly
    }

    convenience init(node: NodeModel,
                     group: GroupModel,
                     server: ServerModel) {
        self.init()
        guard let groupId = group.id else { return }
        self.groupId = "\(groupId)"
        self.serverName = server.name ?? ""
        self.countryCode = server.countryCode ?? ""
        self.hostname = node.hostname ?? ""
        self.cityName = group.city ?? ""
        self.nickName = group.nick ?? ""
        self.dnsHostname = server.dnsHostname ?? ""
        self.ipAddress = node.ip2 ?? ""
        self.pingIp = group.pingIp ?? ""
        self.pingHost = group.pingHost ?? ""
        self.linkSpeed = group.linkSpeed ?? "1000"
        self.health = group.health ?? 0
        self.isPremiumOnly = group.premiumOnly ?? false
    }

    override static func primaryKey() -> String? {
        return "hostname"
    }

    func getFavNodeModel() -> FavNodeModel? {
        return FavNodeModel(groupId: groupId,
                            serverName: serverName,
                            countryCode: countryCode,
                            hostname: hostname,
                            cityName: cityName,
                            nickName: nickName,
                            dnsHostname: dnsHostname,
                            ipAddress: ipAddress,
                            pingIp: pingIp,
                            linkSpeed: linkSpeed,
                            health: health,
                            isPremiumOnly: isPremiumOnly)
    }

}

class LastConnectedNode: FavNode {

    var staticIPCredentials = List<LastConnectedNodeStaticIPCredentials>()
    dynamic var connectedAt: Date = Date()

    convenience init(selectedNode: SelectedNode) {
        self.init()
        self.serverName = selectedNode.cityName
        self.countryCode = selectedNode.countryCode
        self.hostname = selectedNode.hostname
        self.cityName = selectedNode.cityName
        self.nickName = selectedNode.nickName
        self.dnsHostname = selectedNode.dnsHostname
        self.ipAddress = selectedNode.serverAddress
        staticIPCredentials.removeAll()
        if let staticIPCredential = selectedNode.staticIPCredentials {
            staticIPCredentials.append(LastConnectedNodeStaticIPCredentials(staticIPCredentials: staticIPCredential))
        }
        if let customConfigModel = selectedNode.customConfig {
            self.customConfigId = customConfigModel.id
        }
        self.groupId = "\(selectedNode.groupId)"
    }

}

struct BestLocationModel {

    let serverName: String?
    let countryCode: String?
    let hostname: String?
    let cityName: String?
    let nickName: String?
    let dnsHostname: String?
    let ipAddress: String?
    let groupId: Int?
    let linkSpeed: String?
    let health: Int?

    init(serverName: String,
         countryCode: String,
         hostname: String,
         cityName: String,
         nickName: String,
         dnsHostname: String,
         ipAddress: String,
         groupId: Int,
         linkSpeed: String,
         health: Int) {
        self.serverName = serverName
        self.countryCode = countryCode
        self.hostname = hostname
        self.cityName = cityName
        self.nickName = nickName
        self.dnsHostname = dnsHostname
        self.ipAddress = ipAddress
        self.groupId = groupId
        self.linkSpeed = linkSpeed
        self.health = health
    }

    init(node: NodeModel,
         group: GroupModel,
         server: ServerModel) {
        self.serverName = group.city
        self.countryCode = server.countryCode
        self.hostname = node.hostname
        self.cityName = group.city
        self.nickName = group.nick
        self.dnsHostname = server.dnsHostname
        self.ipAddress = node.ip2
        self.groupId = group.id
        self.linkSpeed = group.linkSpeed
        self.health = group.health
    }

}

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

    convenience init(node: NodeModel,
                     group: GroupModel,
                     server: ServerModel) {
        self.init()
        self.serverName = group.city ?? ""
        self.countryCode = server.countryCode ?? ""
        self.hostname = node.hostname ?? ""
        self.cityName = group.city ?? ""
        self.nickName = group.nick ?? ""
        self.dnsHostname = server.dnsHostname ?? ""
        self.ipAddress = node.ip2 ?? ""
        self.groupId = group.id ?? 0
        self.linkSpeed = group.linkSpeed ?? "1000"
        self.health = group.health ?? 0
    }

    override static func primaryKey() -> String? {
        return "cityName"
    }

    func getBestLocationModel() -> BestLocationModel {
        return BestLocationModel(serverName: serverName,
                                 countryCode: countryCode,
                                 hostname: hostname,
                                 cityName: cityName,
                                 nickName: nickName,
                                 dnsHostname: dnsHostname,
                                 ipAddress: ipAddress,
                                 groupId: groupId,
                                 linkSpeed: linkSpeed,
                                 health: health)
    }

}
