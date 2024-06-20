//
//  APIDebug.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-21.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation

struct APIDebug: Decodable {

    let debug: String?
    let success: Bool?

    enum CodingKeys: String, CodingKey {
        case data
        case debug
        case success
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        debug = try data.decodeIfPresent(String.self, forKey: .debug)
        success = try data.decodeIfPresent(Int.self, forKey: .success) == 1 ? true : false
    }
}
