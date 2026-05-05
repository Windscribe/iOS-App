//
//  PortMap.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-08.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class PortMap: Object, Decodable {
    dynamic var connectionProtocol: String = ""
    dynamic var heading: String = ""
    dynamic var use: String = ""
    var ports = List<String>()
    var legacyPorts = List<String>()

    enum CodingKeys: String, CodingKey {
        case connectionProtocol = "protocol"
        case heading
        case use
        case ports
        case legacyPorts = "legacy_ports"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let data = try decoder.container(keyedBy: CodingKeys.self)
        connectionProtocol = try data.decodeIfPresent(String.self, forKey: .connectionProtocol) ?? ""
        heading = try data.decodeIfPresent(String.self, forKey: .heading) ?? ""
        use = try data.decodeIfPresent(String.self, forKey: .use) ?? ""
        if let portsArray = try data.decodeIfPresent([String].self, forKey: .ports) {
            setPortsArray(array: portsArray)
        }
        if let legacyPortsArray = try data.decodeIfPresent([String].self, forKey: .legacyPorts) {
            setLegacyPortsArray(array: legacyPortsArray)
        }
    }

    func setPortsArray(array: [String]) {
        ports.removeAll()
        ports.append(objectsIn: array)
    }

    func setLegacyPortsArray(array: [String]) {
        legacyPorts.removeAll()
        legacyPorts.append(objectsIn: array)
    }

    override class func primaryKey() -> String? {
        return "connectionProtocol"
    }

    convenience init(from model: PortMapModel) {
        self.init()
        connectionProtocol = model.connectionProtocol
        heading = model.heading
        use = model.use
        setPortsArray(array: model.ports)
        setLegacyPortsArray(array: model.legacyPorts)
    }

    func getModel() -> PortMapModel {
        .init(from: self)
    }
}

struct PortMapModel: Equatable {
    let connectionProtocol: String
    let heading: String
    let use: String
    let ports: [String]
    let legacyPorts: [String]

    init(from: PortMap) {
        connectionProtocol = from.connectionProtocol
        heading = from.heading
        use = from.use
        ports = Array(from.ports)
        legacyPorts = Array(from.legacyPorts)
    }

    init(connectionProtocol: String,
         heading: String,
         use: String,
         ports: [String],
         legacyPorts: [String]) {
        self.connectionProtocol = connectionProtocol
        self.heading = heading
        self.use = use
        self.ports = ports
        self.legacyPorts = legacyPorts
    }
}

struct PortMapList: Decodable {
    let portMaps = List<PortMap>()
    let suggested: SuggestedPorts?

    enum CodingKeys: String, CodingKey {
        case data
        case portmap
        case suggested
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        suggested = try data.decodeIfPresent(SuggestedPorts.self, forKey: .suggested)
        if let portMapsArray = try data.decodeIfPresent([PortMap].self, forKey: .portmap) {
            setPortMaps(array: portMapsArray)
        }
    }

    func setPortMaps(array: [PortMap]) {
        portMaps.removeAll()
        portMaps.append(objectsIn: array)
    }
}
