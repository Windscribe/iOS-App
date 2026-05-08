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

protocol ServerCredentialType {
    var username: String { get }
    var password: String { get }

    func getModel() -> ServerCredentialsModel
}

extension ServerCredentialType {
    func getModel() -> ServerCredentialsModel {
        .init(from: self)
    }
}

@objcMembers class StaticIPCredentials: Object, ServerCredentialType, Decodable {
    dynamic var username: String = ""
    dynamic var password: String = ""

    enum CodingKeys: String, CodingKey {
        case username
        case password
    }

    required convenience init(from decoder: Decoder) throws {
        self.init()
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        password = try container.decodeIfPresent(String.self, forKey: .password) ?? ""
    }

    convenience init(username: String, password: String) {
        self.init()
        self.username = username
        self.password = password
    }
}

struct ServerCredentialsModel: ServerCredentialType, Codable, Equatable, Sendable {
    let username: String
    let password: String

    init(from: ServerCredentialType) {
        username = from.username
        password = from.password
    }

    init(username: String, password: String) {
        self.username = username
        self.password = password
    }
}

@objcMembers class ServerCredentials: Object, ServerCredentialType, Decodable {
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

    convenience init(username: String, password: String) {
        self.init()
        self.username = username
        self.password = password
    }
}

@objcMembers class OpenVPNServerCredentials: ServerCredentials {
    dynamic var id: String = "OpenVPNServerCredentials"
    override class func primaryKey() -> String? {
        return "id"
    }
}

@objcMembers class IKEv2ServerCredentials: ServerCredentials {
    dynamic var id: String = "IKEv2ServerCredentials"
    override class func primaryKey() -> String? {
        return "id"
    }
}
