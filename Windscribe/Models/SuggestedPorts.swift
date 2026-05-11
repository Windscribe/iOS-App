//
//  SuggestedPorts.swift
//  Windscribe
//
//  Created by Yalcin on 2020-04-07.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

struct SuggestedPortsModel: Equatable {
    let protocolType: String
    let port: String

    init(from: SuggestedPorts) {
        self.protocolType = from.protocolType
        self.port = from.port
    }

    init(protocolType: String, port: String) {
        self.protocolType = protocolType
        self.port = port
    }
}

@objcMembers class SuggestedPorts: Object, Decodable {
    dynamic var id: String = "SuggestedPorts"
    dynamic var protocolType: String = ""
    dynamic var port: String = ""

    override class func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case protocolType = "protocol"
        case port
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let data = try decoder.container(keyedBy: CodingKeys.self)
        protocolType = try data.decodeIfPresent(String.self, forKey: .protocolType) ?? ""
        if protocolType == "wg" {
            protocolType = VPNProtocolType.wireGuard.identifier
        }
        if let port = try data.decodeIfPresent(Int.self, forKey: .port) {
            self.port = String(port)
        } else {
            port = ""
        }
    }

    convenience init(from model: SuggestedPortsModel) {
        self.init()
        protocolType = model.protocolType
        port = model.port
    }

    func getModel() -> SuggestedPortsModel {
        .init(from: self)
    }
}
