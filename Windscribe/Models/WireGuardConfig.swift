//
//  WireGuardConfig.swift
//  Windscribe
//
//  Created by Yalcin on 2020-07-14.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class WireGuardConfig: Object, Decodable {
    dynamic var id: String = "WireGuardConfig"
    dynamic var privateKey: String?
    dynamic var address: String?
    dynamic var dns: String?
    dynamic var presharedKey: String?
    dynamic var allowedIPs: String?

    override class func primaryKey() -> String? {
        return "id"
    }

    enum CodingKeys: String, CodingKey {
        case data
        case config
        case privateKey = "PrivateKey"
        case address = "Address"
        case dns = "DNS"
        case presharedKey = "PresharedKey"
        case allowedIPs = "AllowedIPs"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        let config = try data.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        privateKey = try config.decodeIfPresent(String.self, forKey: .privateKey)
        address = try config.decodeIfPresent(String.self, forKey: .address)
        dns = try config.decodeIfPresent(String.self, forKey: .dns)
        presharedKey = try config.decodeIfPresent(String.self, forKey: .presharedKey)
        allowedIPs = try config.decodeIfPresent(String.self, forKey: .allowedIPs)
    }
}
