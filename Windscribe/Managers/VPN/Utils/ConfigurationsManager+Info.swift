//
//  ConfigurationsManager+Info.swift
//  Windscribe
//
//  Created by Andre Fonseca on 31/10/2024.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension

extension ConfigurationsManager {
    func getIKEV2ConnectionInfo(manager: NEVPNManager?) -> VPNConnectionInfo? {
        guard let manager = manager else { return nil }
        #if os(iOS)
            return VPNConnectionInfo(selectedProtocol: iKEv2, selectedPort: "500", status: manager.connection.status, server: manager.protocolConfiguration?.serverAddress, killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
        #else
            return VPNConnectionInfo(selectedProtocol: iKEv2, selectedPort: "500", status: manager.connection.status, server: manager.protocolConfiguration?.serverAddress, killSwitch: false, onDemand: manager.isOnDemandEnabled)
        #endif
    }

    func getVPNConnectionInfo(manager: NEVPNManager?) -> VPNConnectionInfo? {
        guard let manager = manager,
              let conf = manager as? NETunnelProviderManager else { return nil }
        if let wgConfig = conf.tunnelConfiguration,
           let hostAndPort = wgConfig.peers.first?.endpoint?.stringRepresentation.splitToArray(separator: ":") {
            #if os(iOS)
                return VPNConnectionInfo(selectedProtocol: wireGuard, selectedPort: hostAndPort[1], status: manager.connection.status, server: hostAndPort[0], killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
            #else
                return VPNConnectionInfo(selectedProtocol: wireGuard, selectedPort: hostAndPort[1], status: manager.connection.status, server: hostAndPort[0], killSwitch: false, onDemand: manager.isOnDemandEnabled)
            #endif
        }
        guard let neProtocol = conf.protocolConfiguration as? NETunnelProviderProtocol,
              let ovpn = neProtocol.providerConfiguration?["ovpn"] as? Data
        else { return nil }
        return getVPNConnectionInfo(ovpn: ovpn, manager: manager)
    }

    private func getVPNConnectionInfo(ovpn: Data, manager: NEVPNManager) -> VPNConnectionInfo? {
        var proto: String?
        var port: String?
        var server: String?
        let rows = String(data: ovpn, encoding: .utf8)?.splitToArray(separator: "\n")
        // check if OpenVPN connection is using local proxy.
        let proxyRow = rows?.first { line in line.starts(with: "local-proxy") }
        if let proxyColumns = proxyRow?.splitToArray(separator: " "), proxyColumns.count > 4, let proxyType = Int(proxyColumns[4]) {
            if proxyType == 1 {
                proto = wsTunnel
            }
            if proxyType == 2 {
                proto = stealth
            }
            port = proxyColumns[3]
            server = proxyColumns[2]
        } else {
            // Direct UDP and TCP OpenVPN connection.
            let protoRow = rows?.first { line in line.starts(with: "proto") }
            if let protoColumns = protoRow?.splitToArray(separator: " "), protoColumns.count > 1 {
                proto = protoColumns[1].uppercased()
            }
            let remoteRow = rows?.first { line in line.starts(with: "remote") }
            if let remoteColumns = remoteRow?.splitToArray(separator: " "), remoteColumns.count > 2 {
                port = remoteColumns[2].uppercased()
                server = remoteColumns[1]
            }
        }
        if let proto = proto, let port = port {
            #if os(iOS)
                return VPNConnectionInfo(selectedProtocol: proto, selectedPort: port, status: manager.connection.status, server: server, killSwitch: manager.protocolConfiguration?.includeAllNetworks ?? false, onDemand: manager.isOnDemandEnabled)
            #else
                return VPNConnectionInfo(selectedProtocol: proto, selectedPort: port, status: manager.connection.status, server: server, killSwitch: false, onDemand: manager.isOnDemandEnabled)
            #endif
        } else {
            return nil
        }
    }
}
