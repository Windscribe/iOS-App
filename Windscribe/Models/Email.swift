//
//  Email.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-20.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class Email: Object, Decodable {
    dynamic var email: String = ""

    enum CodingKeys: String, CodingKey {
        case data
        case email
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        email = try data.decodeIfPresent(String.self, forKey: .email) ?? ""
    }
}
