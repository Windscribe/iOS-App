//
//  ProxyInfo.swift
//  Windscribe
//
//  Created by Ginder Singh on 2022-12-07.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
/// Holds proxy informations.
/// learn more at https://gitlab.int.windscribe.com/ws/client/wstunnel
struct ProxyInfo {
    var remoteServer: String
    var remotePort = "443"
    var proxyType = ProxyType.wstunnel
    var text: String {
        return "local-proxy \(Proxy.defaultProxyPort) \(remoteServer) \(remotePort) \(proxyType.rawValue)"
    }

    var remoteEndpoint: String {
        if proxyType == .wstunnel {
            return "wss://\(remoteServer):\(remotePort)\(Proxy.wstunnelPath)"
        } else {
            return "https://\(remoteServer):\(remotePort)"
        }
    }

    init(remoteServer: String, remotePort: String = "443", proxyType: ProxyType = ProxyType.wstunnel) {
        self.remoteServer = remoteServer
        self.remotePort = remotePort
        self.proxyType = proxyType
    }

    init?(text: String) {
        let data = text.split(separator: " ")
        if data.count > 4 {
            remoteServer = String(data[2])
            remotePort = String(data[3])
            if let raw = Int(data[4]), let type = ProxyType(rawValue: raw) {
                proxyType = type
            }
        } else {
            return nil
        }
    }
}

enum ProxyType: Int {
    // Wraps OpenVPN TCP traffic in to websockets.
    case wstunnel = 1
    // Wraps OpenVPN TCP traffic in to Tls
    case stunnel = 2
}
