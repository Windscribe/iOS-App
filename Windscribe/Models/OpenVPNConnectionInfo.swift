//
//  OpenVPNConnectionInfo.swift
//  Windscribe
//
//  Created by Bushra Sagir on 18/04/23.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

class OpenVPNConnectionInfo: NSObject {
    let serverConfig: Data
    let ip: String
    let port: String
    let protocolName: String
    let username: String
    let password: String

    init(serverConfig: Data, ip: String, port: String, protocolName: String, username: String, password: String) {
        self.serverConfig = serverConfig
        self.ip = ip
        self.port = port
        self.username = username
        self.password = password
        self.protocolName = protocolName
    }
}
