//
//  ServerMachineModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct ServerMachinesListModel: Decodable, Equatable {
    let servers: [ServerMachineModel]
    let revision: Int64
    let backup: Int

    var hasBakcup: Bool { backup == 1 }

    enum CodingKeys: String, CodingKey {
        case data
        case servers
        case revision
        case backup
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        servers = try data.decodeIfPresent([ServerMachineModel].self, forKey: .servers) ?? []
        revision = try data.decodeIfPresent(Int64.self, forKey: .revision) ?? 0
        backup = try data.decodeIfPresent(Int.self, forKey: .backup) ?? 0
    }

    init(servers: [ServerMachineModel], revision: Int64, backup: Int) {
        self.servers = servers
        self.revision = revision
        self.backup = backup
    }
}

struct DisabledServerModel: Codable, Equatable, Sendable {
    let id: Int
}

struct ServerMachineModel: Codable, Equatable, Sendable, Hashable {
    let id: Int
    let hostname: String
    let ip: String
    let ip2: String
    let ip3: String
    let ipv6: Int
    let datacenterId: Int
    let weight: Int
    let netLoad: Int
    let sclass: Int

    enum CodingKeys: String, CodingKey {
        case id
        case hostname = "host"
        case ip
        case ip2
        case ip3
        case ipv6
        case datacenterId = "dc_id"
        case weight
        case netLoad = "net_load"
        case sclass = "s_class"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? -1
        self.hostname = try container.decodeIfPresent(String.self, forKey: .hostname) ?? ""
        ip = try container.decodeIfPresent(String.self, forKey: .ip) ?? ""
        ip2 = try container.decodeIfPresent(String.self, forKey: .ip2) ?? ""
        ip3 = try container.decodeIfPresent(String.self, forKey: .ip3) ?? ""
        ipv6 = try container.decodeIfPresent(Int.self, forKey: .ipv6) ?? 0
        self.datacenterId = try container.decodeIfPresent(Int.self, forKey: .datacenterId) ?? -1
        weight = try container.decodeIfPresent(Int.self, forKey: .weight) ?? 0
        netLoad = try container.decodeIfPresent(Int.self, forKey: .netLoad) ?? 0
        sclass = try container.decodeIfPresent(Int.self, forKey: .sclass) ?? 0
    }

    init(id: Int,
         hostname: String,
         ip: String,
         ip2: String,
         ip3: String,
         ipv6: Int,
         datacenterId: Int,
         weight: Int,
         netLoad: Int,
         sclass: Int) {
        self.id = id
        self.hostname = hostname
        self.ip = ip
        self.ip2 = ip2
        self.ip3 = ip3
        self.ipv6 = ipv6
        self.datacenterId = datacenterId
        self.weight = weight
        self.netLoad = netLoad
        self.sclass = sclass
    }

    init(from object: ServerMachineObject) {
        self.id = object.id
        self.hostname = object.hostname
        self.ip = object.ip
        self.ip2 = object.ip2
        self.ip3 = object.ip3
        self.ipv6 = object.ipv6
        self.datacenterId = object.datacenterId
        self.weight = object.weight
        self.netLoad = object.netLoad
        self.sclass = object.sclass
    }

    init(from node: NodeModel) {
        self.id = 0
        self.hostname = node.hostname
        self.ip = node.ip1
        self.ip2 = node.ip2
        self.ip3 = node.ip3
        self.ipv6 = 0
        self.datacenterId = 0
        self.weight = node.weight
        self.netLoad = 0
        self.sclass = 0
    }
}

@objcMembers class ServerMachineObject: Object {
    dynamic var id: Int = 0
    dynamic var hostname: String = ""
    dynamic var ip: String = ""
    dynamic var ip2: String = ""
    dynamic var ip3: String = ""
    dynamic var ipv6: Int = 0
    dynamic var datacenterId: Int = 0
    dynamic var weight: Int = 0
    dynamic var netLoad: Int = 0
    dynamic var sclass: Int = 0

    override static func primaryKey() -> String? {
        return "id"
    }

    convenience init(from model: ServerMachineModel) {
        self.init()
        self.id = model.id
        self.hostname = model.hostname
        self.ip = model.ip
        self.ip2 = model.ip2
        self.ip3 = model.ip3
        self.ipv6 = model.ipv6
        self.datacenterId = model.datacenterId
        self.weight = model.weight
        self.netLoad = model.netLoad
        self.sclass = model.sclass
    }
}

struct NodeModel: Equatable, Codable {
    let ip1: String
    let ip2: String
    let ip3: String
    let hostname: String
    let dnsHostname: String
    let forceDisconnect: Bool
    let weight: Int
}
