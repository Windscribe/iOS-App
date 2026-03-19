//
//  DynamicWireGuardConfig.swift
//  Windscribe
//
//  Created by Thomas on 10/03/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

class DynamicWireGuardConfig: Decodable {
    dynamic var id: String = "DynamicWireGuardConfig"
    dynamic var presharedKey: String?
    dynamic var allowedIPs: String?
    dynamic var allowedIPsV6: String?
    dynamic var hashedCIDR: [String]?
    dynamic var hashedCIDRv6: [String]?

    enum CodingKeys: String, CodingKey {
        case data
        case config
        case presharedKey = "PresharedKey"
        case allowedIPs = "AllowedIPs"
        case allowedIPsV6 = "AllowedIPsV6"
        case hashedCIDR = "HashedCIDR"
        case hashedCIDRv6 = "HashedCIDRv6"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        let config = try data.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        presharedKey = try config.decodeIfPresent(String.self, forKey: .presharedKey)
        allowedIPs = try config.decodeIfPresent(String.self, forKey: .allowedIPs)
        allowedIPsV6 = try config.decodeIfPresent(String.self, forKey: .allowedIPsV6)
        hashedCIDR = try config.decodeIfPresent([String].self, forKey: .hashedCIDR)
        hashedCIDRv6 = try config.decodeIfPresent([String].self, forKey: .hashedCIDRv6)
    }
}
