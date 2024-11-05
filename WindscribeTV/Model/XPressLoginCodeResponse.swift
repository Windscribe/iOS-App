//
//  XPressLoginCodeResponse.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 25/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class XPressLoginCodeResponse: Decodable {
    var signature: String = ""
    var time: Int = 0
    var ttl: Int = 0
    var xPressLoginCode: String = ""

    enum CodingKeys: String, CodingKey {
        case data
        case signature = "sig"
        case time
        case ttl
        case xPressLoginCode = "xpress_code"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        signature = try data.decodeIfPresent(String.self, forKey: .signature) ?? ""
        time = try data.decodeIfPresent(Int.self, forKey: .time) ?? 0
        ttl = try data.decodeIfPresent(Int.self, forKey: .ttl) ?? 0
        xPressLoginCode = try data.decodeIfPresent(String.self, forKey: .xPressLoginCode) ?? ""
    }
}
