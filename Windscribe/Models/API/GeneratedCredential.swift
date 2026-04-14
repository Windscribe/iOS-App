//
//  GeneratedCredential.swift
//  Windscribe
//
//  Created by Anthony on 2026-04-08.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

struct GeneratedCredential: Decodable {
    var value: String = ""

    enum CodingKeys: String, CodingKey {
        case data
        case username
        case password
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        if let username = try data.decodeIfPresent(String.self, forKey: .username) {
            value = username
        } else if let password = try data.decodeIfPresent(String.self, forKey: .password) {
            value = password
        }
    }
}
