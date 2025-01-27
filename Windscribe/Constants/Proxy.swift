//
//  Proxy.swift
//  Windscribe
//
//  Created by Ginder Singh on 2022-12-08.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation

enum Proxy {
    /// Proxy listens on all interfaces (0.0.0.0:port) using loopback adress does not work.
    static let localAddress = "localhost"
    static let mtu = 1280
    static let internalProtocol = "tcp"
    static let wstunnelPath = "/tcp/127.0.0.1/1194"
    static let defaultProxyPort = "1194"
    static let localEndpoint = "127.0.0.1:\(defaultProxyPort)"
}
