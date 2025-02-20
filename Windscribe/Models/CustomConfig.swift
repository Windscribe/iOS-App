//
//  CustomConfig.swift
//  Windscribe
//
//  Created by Yalcin on 2019-08-02.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import Realm
import RealmSwift

struct CustomConfigModel: Equatable {
    let id: String?
    let name: String?
    let serverAddress: String?
    let protocolType: String?
    let port: String?
    let username: String?
    let password: String?
    let authRequired: Bool?

    init(id: String,
         name: String,
         serverAddress: String,
         protocolType: String,
         port: String,
         username: String = "",
         password: String = "",
         authRequired: Bool = false) {
        self.id = id
        self.name = name
        self.serverAddress = serverAddress
        self.protocolType = protocolType
        self.port = port
        self.username = username
        self.password = password
        self.authRequired = authRequired
    }
}

@objcMembers class CustomConfig: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var serverAddress: String = ""
    dynamic var protocolType: String = ""
    dynamic var port: String = ""
    dynamic var username: String = ""
    dynamic var password: String = ""
    dynamic var authRequired: Bool = false

    convenience init(id: String,
                     name: String,
                     serverAddress: String,
                     protocolType: String,
                     port: String,
                     username: String = "",
                     password: String = "",
                     authRequired: Bool = false) {
        self.init()
        self.id = id
        self.name = name
        self.serverAddress = serverAddress
        self.protocolType = protocolType
        self.port = port
        self.username = username
        self.password = password
        self.authRequired = authRequired
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    func getModel() -> CustomConfigModel {
        return CustomConfigModel(id: id,
                                 name: name,
                                 serverAddress: serverAddress,
                                 protocolType: protocolType,
                                 port: port,
                                 username: username,
                                 password: password,
                                 authRequired: authRequired)
    }
}
