//
//  DynamicWireGuardConnect.swift
//  Windscribe
//
//  Created by Thomas on 12/03/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

@objcMembers class DynamicWireGuardConnect: Decodable {
    dynamic var address: String?
    dynamic var dns: String?

    enum CodingKeys: String, CodingKey {
        case data
        case config
        case address = "Address"
        case dns = "DNS"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        let config = try data.nestedContainer(keyedBy: CodingKeys.self, forKey: .config)
        address = try config.decodeIfPresent(String.self, forKey: .address)
        dns = try config.decodeIfPresent(String.self, forKey: .dns)
    }
}
