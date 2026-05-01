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
    let id: String
    var name: String
    let serverAddress: String
    let protocolType: String
    let port: String
    var username: String
    var password: String
    let authRequired: Bool
    var saveCredentials: Bool

    init(from: CustomConfig) {
        self.id = from.id
        self.name = from.name
        self.serverAddress = from.serverAddress
        self.protocolType = from.protocolType
        self.port = from.port
        self.username = from.username
        self.password = from.password
        self.authRequired = from.authRequired
        self.saveCredentials = from.saveCredentials
    }

    func getRealmObject() -> CustomConfig {
        .init(id: id,
              name: name,
              serverAddress: serverAddress,
              protocolType: protocolType,
              port: port,
              username: username,
              password: password,
              authRequired: authRequired,
              saveCredentials: saveCredentials)
    }

    init(id: String,
         name: String,
         serverAddress: String,
         protocolType: String,
         port: String,
         username: String = "",
         password: String = "",
         authRequired: Bool = false,
         saveCredentials: Bool = true) {
        self.id = id
        self.name = name
        self.serverAddress = serverAddress
        self.protocolType = protocolType
        self.port = port
        self.username = username
        self.password = password
        self.authRequired = authRequired
        self.saveCredentials = saveCredentials
    }
}

@objcMembers class CustomConfig: Object {
    dynamic var id: String = ""
    dynamic var name: String = ""
    dynamic var serverAddress: String = ""
    dynamic var protocolType: String = ""
    dynamic var port: String = ""
    @available(*, deprecated, message: "Credentials are now stored in Keychain via Preferences. Use preferences.getCustomConfigCredentials(configId:) instead.")
    dynamic var username: String = ""
    @available(*, deprecated, message: "Credentials are now stored in Keychain via Preferences. Use preferences.getCustomConfigCredentials(configId:) instead.")
    dynamic var password: String = ""
    dynamic var authRequired: Bool = false
    dynamic var saveCredentials: Bool = true

    convenience init(id: String,
                     name: String,
                     serverAddress: String,
                     protocolType: String,
                     port: String,
                     username: String = "",
                     password: String = "",
                     authRequired: Bool = false,
                     saveCredentials: Bool = true) {
        self.init()
        self.id = id
        self.name = name
        self.serverAddress = serverAddress
        self.protocolType = protocolType
        self.port = port
        self.username = username
        self.password = password
        self.authRequired = authRequired
        self.saveCredentials = saveCredentials
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    func getModel() -> CustomConfigModel {
        .init(from: self)
    }
}
