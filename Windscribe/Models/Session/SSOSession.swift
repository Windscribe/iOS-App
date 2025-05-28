//
//  SSOSession.swift
//  Windscribe
//
//  Created by Ginder Singh on 2025-05-28.
//  Copyright © 2025 Windscribe. All rights reserved.
//

enum SSOSessionType: String {
    case apple
    case google

    var ssoID: String {
        switch self {
        case .apple:
            return "apple"
        case .google:
            return "google"
        }
    }
}

@objcMembers class SSOSession: Decodable {

    var sessionAuth: String = ""
    var isNewUserUser: Bool = false

    enum CodingKeys: String, CodingKey {
        case data
        case sessionAuth = "session_auth_hash"
        case isNewUserUser = "is_new_user"
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)

        sessionAuth = try data.decode(String.self, forKey: .sessionAuth)
        isNewUserUser = try data.decode(Bool.self, forKey: .isNewUserUser)
    }
}
