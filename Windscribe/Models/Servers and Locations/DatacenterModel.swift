//
//  DatacenterModel.swift
//  Windscribe
//
//  Created by Andre Fonseca on 27/02/2026.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct DatacenterModel: Codable, Equatable, Sendable {
    enum DatacenterStatus: Int {
        case available = 0
        case isPro = 1
        case underMantainance = 2
    }

    let id: Int
    let city: String
    let nick: String
    let iata: String
    fileprivate let status: Int
    let gps: String
    let tz: String
    let p2p: Int
    let isPremium: Int
    let wgPubkey: String
    let wgEndpoint: String
    let ovpnX509: String
    let linkSpeed: Int

    var locationId: Int = 0
    var servers: [ServerMachineModel] = [] {
        didSet {
            guard !servers.isEmpty else {
                netLoad = 0
                pingServer = nil
                return
            }

            guard  Set(oldValue) != Set(servers) else {
                return
            }

            if let randomServer = servers.randomElement() {
                netLoad = randomServer.netLoad
                pingServer = randomServer
            }
        }
    }

    private(set) var netLoad: Int = 0
    private(set) var pingServer: ServerMachineModel?

    var isPremiumOnly: Bool {
        return quickStatus == .isPro || isPremium == 1
    }

    var isUnderMantainance: Bool {
        quickStatus == .underMantainance
    }

    private var quickStatus: DatacenterStatus {
        let hasServers = servers.count > 0

        if status == 1, hasServers {
            // Available: has servers
            return .available
        } else if status == 1 && !hasServers {
            // Pro required: enabled but no servers available
            return .isPro
        }
        return .underMantainance
    }

    enum CodingKeys: String, CodingKey {
        case id
        case city
        case nick
        case iata
        case status
        case gps
        case tz
        case p2p
        case isPremium = "premium"
        case wgPubkey = "wg_pubkey"
        case wgEndpoint = "wg_endpoint"
        case ovpnX509 = "ovpn_x509"
        case linkSpeed = "link_speed"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? -1
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        nick = try container.decodeIfPresent(String.self, forKey: .nick) ?? ""
        iata = try container.decodeIfPresent(String.self, forKey: .iata) ?? ""
        status = try container.decodeIfPresent(Int.self, forKey: .status) ?? 0
        gps = try container.decodeIfPresent(String.self, forKey: .gps) ?? ""
        tz = try container.decodeIfPresent(String.self, forKey: .tz) ?? ""
        p2p = try container.decodeIfPresent(Int.self, forKey: .p2p) ?? 0
        isPremium = try container.decodeIfPresent(Int.self, forKey: .isPremium) ?? 0
        wgPubkey = try container.decodeIfPresent(String.self, forKey: .wgPubkey) ?? ""
        wgEndpoint = try container.decodeIfPresent(String.self, forKey: .wgEndpoint) ?? ""
        ovpnX509 = try container.decodeIfPresent(String.self, forKey: .ovpnX509) ?? ""
        linkSpeed = try container.decodeIfPresent(Int.self, forKey: .linkSpeed) ?? 0
    }

    init(id: Int, city: String, nick: String, iata: String, status: Int, gps: String, tz: String, p2p: Int, isPremium: Int, wgPubkey: String, wgEndpoint: String, ovpnX509: String, linkSpeed: Int) {
        self.id = id
        self.city = city
        self.nick = nick
        self.iata = iata
        self.status = status
        self.gps = gps
        self.tz = tz
        self.p2p = p2p
        self.isPremium = isPremium
        self.wgPubkey = wgPubkey
        self.wgEndpoint = wgEndpoint
        self.ovpnX509 = ovpnX509
        self.linkSpeed = linkSpeed
    }

    init(from object: DatacenterObject) {
        self.id = object.id
        self.city = object.city
        self.nick = object.nick
        self.iata = object.iata
        self.status = object.status
        self.gps = object.gps
        self.tz = object.tz
        self.p2p = object.p2p
        self.isPremium = object.isPremium
        self.wgPubkey = object.wgPubkey
        self.wgEndpoint = object.wgEndpoint
        self.ovpnX509 = object.ovpnX509
        self.linkSpeed = object.linkSpeed
    }

    func getCustomDatacenter(withCity cityName: String, andNick nickname: String) -> DatacenterModel {
        var newDatacenter = DatacenterModel(id: id,
                                            city: cityName,
                                            nick: nickname,
                                            iata: iata,
                                            status: status,
                                            gps: gps,
                                            tz: tz,
                                            p2p: p2p,
                                            isPremium: isPremium,
                                            wgPubkey: wgPubkey,
                                            wgEndpoint: wgEndpoint,
                                            ovpnX509: ovpnX509,
                                            linkSpeed: linkSpeed)
        newDatacenter.servers = servers
        return newDatacenter
    }

    func getStatus(hasAccess: Bool) -> DatacenterStatus {
        let hasAtLeastOneServer = servers.count > 0             // at least one server in inventory
        let isEnabled           = status == 1                   // location active in backend
        let isPremiumLocation   = isPremium == 1            // location is flagged premium/pro

        if isEnabled, hasAtLeastOneServer {
            return .available                                   // active + at least one server → connectable
        } else if !hasAccess, isPremiumLocation {
            return .isPro                                       // user lacks access on a premium location → show star + "Upgrade"
        } else {
            return .underMantainance                            // everything else → disabled (pylon icon)
        }
    }
}

@objcMembers class DatacenterObject: Object {
    dynamic var id: Int = 0
    dynamic var city: String = ""
    dynamic var nick: String = ""
    dynamic var iata: String = ""
    dynamic var status: Int = 0
    dynamic var gps: String = ""
    dynamic var tz: String = ""
    dynamic var p2p: Int = 0
    dynamic var isPremium: Int = 0
    dynamic var wgPubkey: String = ""
    dynamic var wgEndpoint: String = ""
    dynamic var ovpnX509: String = ""
    dynamic var linkSpeed: Int = 0

    override static func primaryKey() -> String? {
        return "id"
    }

    convenience init(from model: DatacenterModel) {
        self.init()
        self.id = model.id
        self.city = model.city
        self.nick = model.nick
        self.iata = model.iata
        self.status = model.status
        self.gps = model.gps
        self.tz = model.tz
        self.p2p = model.p2p
        self.p2p = model.p2p
        self.isPremium = model.isPremium
        self.wgPubkey = model.wgPubkey
        self.wgEndpoint = model.wgEndpoint
        self.ovpnX509 = model.ovpnX509
        self.linkSpeed = model.linkSpeed
    }
}

struct BestLocationModel {
    let datacenterName: String
    let countryCode: String
    let cityName: String
    let nickName: String
    let datacenterId: Int
    let linkSpeed: Int
    let netLoad: Int

    init(datacenter: DatacenterModel, location: LocationModel) {
        datacenterName = datacenter.city
        countryCode = location.countryCode
        cityName = datacenter.city
        nickName = datacenter.nick
        datacenterId = datacenter.id
        linkSpeed = datacenter.linkSpeed
        netLoad = datacenter.netLoad
    }
}
