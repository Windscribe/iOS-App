//
//  MyIP.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift

/// DEPRECATED - Issue #911: This model is deprecated and will be removed in a future version (v3.10.0+).
/// IP addresses are now stored as String in Preferences instead of Realm.
/// This class is kept temporarily for migration support from older app versions.
/// - Old approach: Stored IP in Realm using /myip API (can be blocked in restrictive regions)
/// - New approach: Store IP as String in Preferences using pingTest() API (more reliable)
@available(*, deprecated, message: "Use Preferences.getCurrentIpAddress() instead. Will be removed in v3.10.0+")
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
