//
//  XPressLoginVerifyResponse.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 26/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
class XPressLoginVerifyResponse: Decodable {
    var sessionAuth: String = ""
    

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case sessionAuth = "session_auth_hash"
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        self.sessionAuth = try data.decodeIfPresent(String.self, forKey: .sessionAuth) ?? ""
    }
}
