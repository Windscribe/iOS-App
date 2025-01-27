//
//  MyIP.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

@objcMembers class MyIP: Object, Decodable {
    dynamic var id: String = "MyIp"
    dynamic var userIp: String = ""
    dynamic var isOurIp: Bool = false
    enum CodingKeys: String, CodingKey {
        case data
        case userIp = "user_ip"
        case ourIp = "our_ip"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        userIp = try data.decode(String.self, forKey: .userIp)
        isOurIp = data.contains(.ourIp)
    }

    override var description: String {
        return "UserIp: \(userIp) isOurIp: \(isOurIp)"
    }

    override static func primaryKey() -> String? {
        return "id"
    }
}
