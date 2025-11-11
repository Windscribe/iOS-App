//
//  Group.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-07.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import Swinject

struct GroupModel {
    let id: Int
    let countryCode: String?
    let city: String
    let nick: String
    let premiumOnly: Bool
    let nodes: [NodeModel]
    let bestNode: NodeModel?
    let bestNodeHostname: String
    let wgPublicKey: String
    let ovpnX509: String
    let pingIp: String
    let linkSpeed: String
    let health: Int
    let pingHost: String
    let wasEdited: Bool

    init(id: Int,
         countryCode: String? = nil,
         city: String,
         nick: String,
         premiumOnly: Bool,
         nodes: [NodeModel],
         bestNode: NodeModel?,
         bestNodeHostname: String,
         wgPublicKey: String,
         ovpnX509: String,
         pingIp: String,
         linkSpeed: String,
         health: Int,
         pingHost: String,
         wasEdited: Bool) {
        self.id = id
        self.countryCode = countryCode
        self.city = city
        self.nick = nick
        self.premiumOnly = premiumOnly
        self.nodes = nodes
        self.bestNode = bestNode
        self.bestNodeHostname = bestNodeHostname
        self.wgPublicKey = wgPublicKey
        self.pingIp = pingIp
        self.ovpnX509 = ovpnX509
        self.linkSpeed = linkSpeed
        self.health = health
        self.pingHost = pingHost
        self.wasEdited = wasEdited
    }

    func getCustomGroupModel(customCity: String = "", customNick: String = "", countryCode: String? = nil) -> GroupModel {
        let wasEdited = (!customCity.isEmpty && customCity != city) ||
        (!customNick.isEmpty && customNick != nick)
        return GroupModel(id: id,
                          countryCode: countryCode,
                          city: customCity.isEmpty ? city : customCity,
                          nick: customNick.isEmpty ? nick : customNick,
                          premiumOnly: premiumOnly,
                          nodes: nodes,
                          bestNode: bestNode,
                          bestNodeHostname: bestNodeHostname,
                          wgPublicKey: wgPublicKey,
                          ovpnX509: ovpnX509,
                          pingIp: pingIp,
                          linkSpeed: linkSpeed,
                          health: health,
                          pingHost: pingHost,
                          wasEdited: wasEdited)
    }

    func canConnect() -> Bool {
        guard let bestNode = bestNode else { return false }
        return bestNodeHostname != "" || (!bestNode.forceDisconnect)
    }

    func isNodesAvailable() -> Bool {
        guard !nodes.isEmpty else {
            return false
        }
        for node in nodes where !node.forceDisconnect {
            return true
        }
        return false
    }
}

struct FavouriteGroupModel {
    var pinnedIp: String?
    var pinnedNodeIp: String?
    var groupModel: GroupModel

    init(favourite: Favourite, groupModel: GroupModel) {
        self.pinnedIp = favourite.pinnedIp
        self.pinnedNodeIp = favourite.pinnedNodeIp
        self.groupModel = groupModel
    }
}

@objcMembers class Group: Object, Decodable {
    dynamic var id: Int = 0
    dynamic var city: String = ""
    dynamic var nick: String = ""
    dynamic var premiumOnly: Bool = false
    dynamic var gps: String = ""
    dynamic var timezone: String = ""
    var nodes = RealmSwift.List<Node>()
    var bestNode: Node? {
        return nodes.filter { $0.hostname == self.bestNodeHostname }.last
    }

    dynamic var bestNodeHostname: String = ""
    dynamic var wgPublicKey: String = ""
    dynamic var ovpnX509: String = ""
    dynamic var pingIp: String = ""
    dynamic var linkSpeed: String = ""
    dynamic var health: Int = 0
    dynamic var pingHost: String = ""

    enum CodingKeys: String, CodingKey {
        case id
        case city
        case nick
        case premiumOnly = "pro"
        case gps
        case timezone = "tz"
        case nodes
        case wgPublicKey = "wg_pubkey"
        case ovpnX509 = "ovpn_x509"
        case pingIp = "ping_ip"
        case linkSpeed = "link_speed"
        case health
        case pingHost = "ping_host"
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decodeIfPresent(Int.self, forKey: .id) ?? 0
        city = try container.decodeIfPresent(String.self, forKey: .city) ?? ""
        nick = try container.decodeIfPresent(String.self, forKey: .nick) ?? ""
        premiumOnly = try container.decodeIfPresent(Int.self, forKey: .premiumOnly) == 1 ? true : false
        gps = try container.decodeIfPresent(String.self, forKey: .gps) ?? ""
        timezone = try container.decodeIfPresent(String.self, forKey: .timezone) ?? ""
        wgPublicKey = try container.decodeIfPresent(String.self, forKey: .wgPublicKey) ?? ""
        ovpnX509 = try container.decodeIfPresent(String.self, forKey: .ovpnX509) ?? ""
        pingIp = try container.decodeIfPresent(String.self, forKey: .pingIp) ?? ""
        // In "WS" server list contains linkSpeed either string/int
        if let linkValue = try? container.decodeIfPresent(String.self, forKey: .linkSpeed) {
            linkSpeed = linkValue
        } else if let linkValue = try? container.decodeIfPresent(Int.self, forKey: .linkSpeed) {
            linkSpeed = String(linkValue)
        } else {
            linkSpeed = "1000"
        }
        health = try container.decodeIfPresent(Int.self, forKey: .health) ?? 0
        if let nodesArray = try container.decodeIfPresent([Node].self, forKey: .nodes) {
            setNodes(array: nodesArray)
        }
        pingHost = try container.decodeIfPresent(String.self, forKey: .pingHost) ?? ""
        setBestNode(advanceRepository: Assembler.resolve(AdvanceRepository.self))
    }

    func setNodes(array: [Node]) {
        nodes.removeAll()
        nodes.append(objectsIn: array)
    }

    func setBestNode(advanceRepository: AdvanceRepository) {
        if nodes.count > 0 {
            let forceNode = advanceRepository.getForcedNode()
            if let forceNode = forceNode, nodes.map({ $0.hostname }).contains(forceNode) {
                bestNodeHostname = forceNode
                return
            }
            let filteredNodes = nodes.filter { $0.forceDisconnect == false }
            var weightCounter = nodes.reduce(0) { $0 + $1.weight }
            if weightCounter >= 1 {
                let randomNumber = arc4random_uniform(UInt32(weightCounter))
                weightCounter = 0
                for node in filteredNodes {
                    weightCounter += node.weight
                    if randomNumber < weightCounter {
                        bestNodeHostname = node.hostname
                        return
                    }
                }
            }
            bestNodeHostname = filteredNodes.last?.hostname ?? ""
            return
        }
    }

    func getGroupModel(customCity: String = "", customNick: String = "", countryCode: String? = nil) -> GroupModel {
        let wasEdited = (!customCity.isEmpty && customCity != city) ||
        (!customNick.isEmpty && customNick != nick)
        return GroupModel(id: id,
                          countryCode: countryCode,
                          city: customCity.isEmpty ? city : customCity,
                          nick: customNick.isEmpty ? nick : customNick,
                          premiumOnly: premiumOnly,
                          nodes: nodes.map { $0.getNodeModel() },
                          bestNode: bestNode?.getNodeModel(),
                          bestNodeHostname: bestNodeHostname,
                          wgPublicKey: wgPublicKey,
                          ovpnX509: ovpnX509,
                          pingIp: pingIp,
                          linkSpeed: linkSpeed,
                          health: health,
                          pingHost: pingHost,
                          wasEdited: wasEdited)
    }
}
