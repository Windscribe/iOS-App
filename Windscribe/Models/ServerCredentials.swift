//
//  ServerCredentials.swift
//  Windscribe
//
//  Created by Yalcin on 2018-12-14.
//  Copyright © 2018 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

@objcMembers class ServerCredentials: Object, Decodable {
    dynamic var username: String = ""
    dynamic var password: String = ""

    enum CodingKeys: String, CodingKey {
        case data
        case username
        case password
    }

    required convenience init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        let username = try data.decodeIfPresent(String.self, forKey: .username) ?? ""
        let password = try data.decodeIfPresent(String.self, forKey: .password) ?? ""
        self.init(username: username, password: password)
    }

    convenience init(username: String,
                     password: String)
    {
        self.init()
        self.username = username
        self.password = password
    }
}

struct StaticIPCredentialsModel {
    let username: String?
    let password: String?

    init(username: String,
         password: String)
    {
        self.username = username
        self.password = password
    }
}

@objcMembers class StaticIPCredentials: Object, Decodable {
    dynamic var username: String = ""
    dynamic var password: String = ""

    convenience init(username: String,
                     password: String)
    {
        self.init()
        self.username = username
        self.password = password
    }

    func getModel() -> StaticIPCredentialsModel {
        return StaticIPCredentialsModel(username: username,
                                        password: password)
    }
}

class LastConnectedNodeStaticIPCredentials: StaticIPCredentials {
    convenience init(staticIPCredentials: StaticIPCredentialsModel) {
        self.init()
        username = staticIPCredentials.username ?? ""
        password = staticIPCredentials.password ?? ""
    }
}

class OpenVPNServerCredentials: ServerCredentials {
    dynamic var id: String = "OpenVPNServerCredentials"
    override class func primaryKey() -> String? {
        return "id"
    }
}

class IKEv2ServerCredentials: ServerCredentials {
    dynamic var id: String = "IKEv2ServerCredentials"
    override class func primaryKey() -> String? {
        return "id"
    }
}
