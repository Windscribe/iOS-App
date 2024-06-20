//
//  DynamicWireGuardConfig.swift
//  Windscribe
//
//  Created by Thomas on 10/03/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

@objcMembers class DynamicWireGuardConfig: Decodable {
    dynamic var id: String = "DynamicWireGuardConfig"
    dynamic var presharedKey: String?
    dynamic var allowedIPs: String?

    enum CodingKeys: String, CodingKey {
        case data
        case config
        case presharedKey = "PresharedKey"
        case allowedIPs = "AllowedIPs"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        let config = try data.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        presharedKey = try config.decodeIfPresent(String.self, forKey: .presharedKey)
        allowedIPs = try config.decodeIfPresent(String.self, forKey: .allowedIPs)
    }
}
