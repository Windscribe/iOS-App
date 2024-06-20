//
//  WebSession.swift
//  Windscribe
//
//  Created by Ginder Singh on 2021-11-12.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation

@objcMembers class WebSession: Decodable {
    var tempSession: String = ""

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case tempSession = "temp_session"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        tempSession = try data.decodeIfPresent(String.self, forKey: .tempSession) ?? ""
    }
}
