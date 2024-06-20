//
//  ClosestCountry.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-26.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

struct ClosestCountry: Decodable {
    let countryCode: String?

    enum CodingKeys: String, CodingKey {
        case data = "data"
        case countryCode = "country_code"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        self.countryCode = try data.decodeIfPresent(String.self, forKey: .countryCode) ?? ""
    }
}
