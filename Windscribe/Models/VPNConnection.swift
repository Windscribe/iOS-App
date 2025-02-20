//
//  VPNConnection.swift
//  Windscribe
//
//  Created by Yalcin on 2019-10-10.
//  Copyright © 2019 Windscribe. All rights reserved.
//
import Foundation
import Realm
import RealmSwift

struct VPNConnectionModel {
    let id: String?
    let hostname: String?
    let serverAddress: String?
    let protocolType: String?
    let port: String?
    let createdAt: Date?

    init(id: String,
         hostname: String,
         serverAddress: String,
         protocolType: String,
         port: String,
         createdAt: Date) {
        self.id = id
        self.hostname = hostname
        self.serverAddress = serverAddress
        self.protocolType = protocolType
        self.port = port
        self.createdAt = createdAt
    }
}

@objcMembers class VPNConnection: Object {
    dynamic var id: String = ""
    dynamic var hostname: String = ""
    dynamic var serverAddress: String = ""
    dynamic var protocolType: String = ""
    dynamic var port: String = ""
    dynamic var createdAt: Date = .init()

    convenience init(id: String,
                     hostname: String,
                     serverAddress: String,
                     protocolType: String,
                     port: String) {
        self.init()
        self.id = id
        self.hostname = hostname
        self.serverAddress = serverAddress
        self.protocolType = protocolType
        self.port = port
    }

    override static func primaryKey() -> String? {
        return "id"
    }

    func getModel() -> VPNConnectionModel {
        return VPNConnectionModel(id: id,
                                  hostname: hostname,
                                  serverAddress: serverAddress,
                                  protocolType: protocolType,
                                  port: port,
                                  createdAt: createdAt)
    }
}
