//
//  APIEmailSent.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-04.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation

struct APIEmailSent: Decodable {
    let emailSent: Bool?

    enum CodingKeys: String, CodingKey {
        case data
        case emailSent = "email_sent"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        emailSent = try data.decodeIfPresent(Int.self, forKey: .emailSent) == 1 ? true : false
    }
}
