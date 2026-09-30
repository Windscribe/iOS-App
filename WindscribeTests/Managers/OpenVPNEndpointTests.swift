//
//  OpenVPNEndpointTests.swift
//  WindscribeTests
//
//  Created by Ginder Singh on 2026-09-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Testing
import Foundation
@testable import Windscribe

@Suite("OpenVPN endpoint directives for proxied protocols")
struct OpenVPNEndpointTests {

    private let nodeAddress = "192.0.2.10"
    private let nodePort = "443"

    @Test("Stealth and WStunnel are the proxied OpenVPN protocols")
    func proxiedIdentifiers() {
        #expect(VPNProtocolType.proxiedOpenVPNIdentifiers == ["Stealth", "WStunnel"])
    }

    @Test("Proxied protocols dial the local proxy, not the node",
          arguments: [VPNProtocolType.stealth, VPNProtocolType.wsTunnel])
    func proxiedProtocolsDialLocalProxy(proto: VPNProtocolType) {
        let endpoint = OpenVPNEndpoint.make(proto: proto.identifier,
                                            serverAddress: nodeAddress,
                                            port: nodePort)

        #expect(endpoint.remoteLine == "remote \(Proxy.localAddress) \(Proxy.defaultProxyPort)")
        #expect(endpoint.protoLine == "proto \(Proxy.internalProtocol)")
        #expect(!endpoint.remoteLine.contains(nodeAddress))
    }

    @Test("The port OpenVPN dials matches the listener the extension binds",
          arguments: [VPNProtocolType.stealth, VPNProtocolType.wsTunnel])
    func dialledPortMatchesExtensionListener(proto: VPNProtocolType) {
        let endpoint = OpenVPNEndpoint.make(proto: proto.identifier,
                                            serverAddress: nodeAddress,
                                            port: nodePort)

        let dialledPort = endpoint.remoteLine.split(separator: " ").last.map(String.init)
        let listenerPort = Proxy.localEndpoint.split(separator: ":").last.map(String.init)
        #expect(dialledPort == listenerPort)
    }

    @Test("Direct protocols keep dialling the node",
          arguments: [VPNProtocolType.udp, VPNProtocolType.tcp])
    func directProtocolsDialNode(proto: VPNProtocolType) {
        let endpoint = OpenVPNEndpoint.make(proto: proto.identifier,
                                            serverAddress: nodeAddress,
                                            port: nodePort)

        #expect(endpoint.remoteLine == "remote \(nodeAddress) \(nodePort)")
        #expect(endpoint.protoLine == "proto \(proto.identifier.lowercased())")
    }

    /// Parsed positionally by `PacketTunnelProvider.startProxy`.
    @Test("Stealth hands the node's ip3 to the proxy over TLS")
    func stealthLocalProxyLine() {
        let info = ProxyInfo(remoteServer: "198.51.100.3", remotePort: nodePort, proxyType: .stunnel)
        #expect(info.text == "local-proxy 1194 198.51.100.3 443 2")

        let parsed = ProxyInfo(text: info.text)
        #expect(parsed?.proxyType == .stunnel)
        #expect(parsed?.remoteEndpoint == "https://198.51.100.3:443")
    }

    @Test("WStunnel hands the node's ip1 to the proxy over a WebSocket")
    func wstunnelLocalProxyLine() {
        let info = ProxyInfo(remoteServer: "198.51.100.1", remotePort: nodePort, proxyType: .wstunnel)
        #expect(info.text == "local-proxy 1194 198.51.100.1 443 1")

        let parsed = ProxyInfo(text: info.text)
        #expect(parsed?.proxyType == .wstunnel)
        #expect(parsed?.remoteEndpoint == "wss://198.51.100.1:443\(Proxy.wstunnelPath)")
    }
}
