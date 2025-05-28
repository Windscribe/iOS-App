//
//  APIMessage.swift
//  Windscribe
//
//  Created by Yalcin on 2019-11-14.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

class APIMessage: Decodable {
    var message: String = ""
    var success: Bool = false

    enum CodingKeys: String, CodingKey {
        case data
        case message
        case success
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        message = try data.decodeIfPresent(String.self, forKey: .message) ?? ""
        success = try data.decodeIfPresent(Int.self, forKey: .success) == 1 ? true : false
    }
}
