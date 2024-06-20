//
//  Server.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-12.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct ServerModel {
    let id: Int?
    let name: String?
    let countryCode: String?
    let status: Bool?
    let premiumOnly: Bool?
    let dnsHostname: String?
    let groups: [GroupModel]?
    let locType: String?

    init(id: Int, name: String,
         countryCode: String,
         status: Bool,
         premiumOnly: Bool,
         dnsHostname: String,
         groups: [GroupModel],
         locType: String) {
        self.id = id
        self.name = name
        self.countryCode = countryCode
        self.status = status
        self.premiumOnly = premiumOnly
        self.dnsHostname = dnsHostname
        self.groups = groups
        self.locType = locType
    }

    init(name: String) {
        self.id = nil
        self.name = name
        self.countryCode = nil
        self.status = nil
        self.premiumOnly = nil
        self.dnsHostname = nil
        self.groups = nil
        self.locType = nil
    }

    func isForStreaming() -> Bool {
        return locType == "streaming"
    }

    /// Calculates average health from groups. Groups with health == 0 (Pro location for free user)
    /// are ignored.
    /// - Returns: Average health
    func getServerHealth() -> Int {
        if let availableGroups = groups {
            let totalHealth = availableGroups .filter {
                $0.health! > 0
            }.reduce(0) { x, y in
                x + y.health!
            }
            if totalHealth > 0 {
                let numberOfGroups = availableGroups.filter {$0.health! > 0}.count
                return totalHealth/numberOfGroups
            }
        }
        return 0
     }
}

@objcMembers class Server: Object, Decodable {

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

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case name = "name"
        case countryCode = "country_code"
        case status = "status"
        case premiumOnly = "premium_only"
        case shortname = "short_name"
        case p2p = "p2p"
        case timezone = "tz"
        case timezoneOffset = "tz_offset"
        case forceExpand = "force_expand"
        case dnsHostname = "dns_hostname"
        case groups = "groups"
        case locType = "loc_type"
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        name = try container.decodeIfPresent(String.self, forKey: .name) ?? ""
        countryCode = try container.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
        status = try container.decodeIfPresent(Int.self, forKey: .status)  == 1 ? true : false
        premiumOnly = try container.decodeIfPresent(Int.self, forKey: .premiumOnly)  == 1 ? true : false
        shortName = try container.decodeIfPresent(String.self, forKey: .shortname) ?? ""
        p2p = try container.decodeIfPresent(Int.self, forKey: .p2p)  == 1 ? true : false
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone) ?? ""
        timezoneOffset = try container.decodeIfPresent(String.self, forKey: .timezoneOffset) ?? ""
        forceExpand = try container.decodeIfPresent(Int.self, forKey: .forceExpand)  == 1 ? true : false
        dnsHostname = try container.decodeIfPresent(String.self, forKey: .dnsHostname) ?? ""
        if let groupsArray = try container.decodeIfPresent([Group].self, forKey: .groups) {
            self.setGroups(array: groupsArray)
        }
        locType = try container.decodeIfPresent(String.self, forKey: .locType) ?? ""
    }

    func setGroups(array: [Group]) {
        groups.removeAll()
        groups.append(objectsIn: array.sorted(by: { $0.city < $1.city }))
    }

    func getServerModel() -> ServerModel? {
        return ServerModel(id: self.id, name: self.name, countryCode: self.countryCode, status: self.status, premiumOnly: self.premiumOnly, dnsHostname: self.dnsHostname, groups: groups.map({$0.getGroupModel()}), locType: self.locType)
    }

}

@objcMembers class Info: Object, Decodable {
    dynamic var countryOverride: String?
    enum CodingKeys: String, CodingKey {
        case countryOverride = "country_override"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let country = try container.decodeIfPresent(String.self, forKey: .countryOverride) {
            self.countryOverride = country
        }
    }
}

struct ServerList: Decodable {
    let servers = List<Server>()
    dynamic var info: Info?

    enum CodingKeys: String, CodingKey {
        case data
        case info
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let serversArray = try container.decode([Server].self, forKey: .data)
        self.info = try container.decode(Info.self, forKey: .info)
        self.setServers(array: serversArray)
    }

    func setServers(array: [Server]) {
        servers.removeAll()
        servers.append(objectsIn: array)
    }
}
