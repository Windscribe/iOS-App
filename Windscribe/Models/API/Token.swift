//
//  Token.swift
//  Windscribe
//
//  Created by Yalcin on 2020-01-14.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation

@objcMembers class Token: Decodable {
    var id: String = ""
    var token: String = ""
    var signature: String = ""
    var time: Double = 0

    enum CodingKeys: String, CodingKey {
        case data
        case id
        case token
        case signature
        case time
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        id = try data.decodeIfPresent(String.self, forKey: .id) ?? ""
        token = try data.decodeIfPresent(String.self, forKey: .token) ?? ""
        signature = try data.decodeIfPresent(String.self, forKey: .signature) ?? ""
        time = try data.decodeIfPresent(Double.self, forKey: .time) ?? 0.0
    }
}
