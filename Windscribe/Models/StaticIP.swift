//
//  StaticIP.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-04.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct StaticIPModel {
    let id: Int?
    let staticIP: String?
    let connectIP: String?
    let type: String?
    let name: String?
    let countryCode: String?
    let deviceName: String?
    let cityName: String?
    let expiry: Date?
    let isActive: Bool
    let credentials: [StaticIPCredentialsModel]?
    let bestNode: NodeModel?
    let wgPublicKey: String?
    let ovpnX509: String?
    let wgIp: String?
    let pingHost: String?

    init(id: Int,
         staticIP: String,
         connectIP: String,
         type: String,
         name: String,
         countryCode: String,
         deviceName: String,
         cityName: String,
         expiry: Date?,
         isActive: Bool,
         credentials: [StaticIPCredentialsModel],
         bestNode: NodeModel,
         wgPublicKey: String,
         ovpnX509: String,
         wgIp: String,
         pingHost: String) {
        self.id = id
        self.staticIP = staticIP
        self.connectIP = connectIP
        self.type = type
        self.name = name
        self.countryCode = countryCode
        self.deviceName = deviceName
        self.expiry = expiry
        self.isActive = isActive
        self.cityName = cityName
        self.credentials = credentials
        self.bestNode = bestNode
        self.wgPublicKey = wgPublicKey
        self.wgIp = wgIp
        self.ovpnX509 = ovpnX509
        self.pingHost = pingHost
    }
}

@objcMembers class StaticIP: Object, Decodable {
    dynamic var id: Int = 0
    dynamic var ipId: Int = 0
    dynamic var staticIP: String = ""
    dynamic var type: String = ""
    dynamic var name: String = ""
    dynamic var countryCode: String = ""
    dynamic var shortName: String = ""
    dynamic var cityName: String = ""
    dynamic var serverId: Int = 0
    dynamic var expiry: Date?
    dynamic var isActive: Bool = true
    dynamic var connectIP: String = ""
    dynamic var wgIp: String = ""
    dynamic var wgPublicKey: String = ""
    dynamic var ovpnX509: String = ""
    dynamic var pingIP: String = ""
    dynamic var pingHost: String = ""
    dynamic var deviceName: String = ""

    var nodes = List<StaticIPNode>()
    var ports = List<PortDetails>()
    var credentials = List<StaticIPCredentials>()
    var bestNode: Node? {
        var weightCounter = nodes.reduce(0) { $0 + $1.weight }
        if weightCounter >= 1 {
            let randomNumber = Int.random(in: 1 ... weightCounter)
            weightCounter = 0
            for node in nodes {
                weightCounter += node.weight
                if randomNumber < weightCounter {
                    return node
                }
            }
        }
        return nodes.last
    }

    enum CodingKeys: String, CodingKey {
        case id
        case ipId = "ip_id"
        case staticIP = "static_ip"
        case type
        case name
        case countryCode = "country_code"
        case shortName = "short_name"
        case cityName = "city_name"
        case serverId = "server_id"
        case expiry
        case isActive = "status"
        case connectIP = "connect_ip"
        case wgIp = "wg_ip"
        case wgPublicKey = "wg_pubkey"
        case ovpnX509 = "ovpn_x509"
        case pingIP = "ping_ip"
        case pingHost = "ping_host"
        case deviceName = "device_name"
        case node
        case ports
        case credentials
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let data = try decoder.container(keyedBy: CodingKeys.self)

        id = try data.decodeIfPresent(Int.self, forKey: .id) ?? 0
        ipId = try data.decodeIfPresent(Int.self, forKey: .ipId) ?? 0
        staticIP = try data.decodeIfPresent(String.self, forKey: .staticIP) ?? ""
        type = try data.decodeIfPresent(String.self, forKey: .type) ?? ""
        name = try data.decodeIfPresent(String.self, forKey: .name) ?? ""
        countryCode = try data.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
        shortName = try data.decodeIfPresent(String.self, forKey: .shortName) ?? ""
        cityName = try data.decodeIfPresent(String.self, forKey: .cityName) ?? ""
        serverId = try data.decodeIfPresent(Int.self, forKey: .serverId) ?? 0
        if let expiryString = try data.decodeIfPresent(String.self, forKey: .expiry) {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            expiry = dateFormatter.date(from: expiryString)
        }
        isActive = (try data.decodeIfPresent(Int.self, forKey: .isActive) ?? 0) == 1
        connectIP = try data.decodeIfPresent(String.self, forKey: .connectIP) ?? ""
        wgIp = try data.decodeIfPresent(String.self, forKey: .wgIp) ?? ""
        wgPublicKey = try data.decodeIfPresent(String.self, forKey: .wgPublicKey) ?? ""
        ovpnX509 = try data.decodeIfPresent(String.self, forKey: .ovpnX509) ?? ""
        pingIP = try data.decodeIfPresent(String.self, forKey: .pingIP) ?? ""
        pingHost = try data.decodeIfPresent(String.self, forKey: .pingHost) ?? ""
        deviceName = try data.decodeIfPresent(String.self, forKey: .deviceName) ?? ""
        if let staticIPNode = try data.decodeIfPresent(StaticIPNode.self, forKey: .node) {
            setStaticIPNodes(object: staticIPNode)
        }
        if let portDetails = try data.decodeIfPresent([PortDetails].self, forKey: .ports) {
            setPortDetails(array: portDetails)
        }
        if let staticIPCredentials = try data.decodeIfPresent(StaticIPCredentials.self, forKey: .credentials) {
            setStaticIPCredentials(object: staticIPCredentials)
        }
    }

    func setStaticIPNodes(object: StaticIPNode) {
        nodes.removeAll()
        nodes.append(object)
    }

    func setPortDetails(array: [PortDetails]) {
        ports.removeAll()
        ports.append(objectsIn: array)
    }

    func setStaticIPCredentials(object: StaticIPCredentials) {
        credentials.removeAll()
        credentials.append(object)
    }

    func getStaticIPModel() -> StaticIPModel? {
        guard let username = credentials.first?.username,
              let password = credentials.first?.password,
              let bestNodeModel = bestNode?.getNodeModel() else { return nil }
        let credentialsModel = StaticIPCredentialsModel(username: username, password: password)

        return StaticIPModel(id: id,
                             staticIP: staticIP,
                             connectIP: connectIP,
                             type: type,
                             name: name,
                             countryCode: countryCode,
                             deviceName: deviceName,
                             cityName: cityName,
                             expiry: expiry,
                             isActive: isActive,
                             credentials: [credentialsModel],
                             bestNode: bestNodeModel,
                             wgPublicKey: wgPublicKey,
                             ovpnX509: ovpnX509,
                             wgIp: wgIp,
                             pingHost: pingHost)
    }
}

@objcMembers class PortDetails: Object, Decodable {
    dynamic var extPort: Int = 0
    dynamic var intPort: Int = 0

    enum CodingKeys: String, CodingKey {
        case extPort = "ext_port"
        case intPort = "int_port"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        extPort = try container.decodeIfPresent(Int.self, forKey: .extPort) ?? 0
        intPort = try container.decodeIfPresent(Int.self, forKey: .intPort) ?? 0
    }
}

struct StaticIPList: Decodable {
    let staticIPs = List<StaticIP>()

    enum CodingKeys: String, CodingKey {
        case data
        case staticIps = "static_ips"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        if let staticIPsArray = try data.decodeIfPresent([StaticIP].self, forKey: .staticIps) {
            setStaticIPs(array: staticIPsArray)
        }
    }

    func setStaticIPs(array: [StaticIP]) {
        staticIPs.removeAll()
        staticIPs.append(objectsIn: array)
    }
}
