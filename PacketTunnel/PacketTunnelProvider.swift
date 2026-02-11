//
//  PacketTunnelProvider.swift
//  PacketTunnel
//
//  Created by Yalcin on 2019-04-22.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import NetworkExtension
import OpenVPNAdapter
import Swinject
import os
#if canImport(WidgetKit)
    import WidgetKit
#endif

class PacketTunnelProvider: NEPacketTunnelProvider, TunnelCredentialsManaging {
    // MARK: Dependencies

    private lazy var container: Container = {
        let container = Container()
        container.injectCore()
        return container
    }()

    private lazy var logger: FileLogger = container.resolve(FileLogger.self)!

    private lazy var preferences: Preferences = container.resolve(Preferences.self)!

    private lazy var dnsSettingsManager: DNSSettingsManagerType = container.resolve(DNSSettingsManagerType.self)!

    private lazy var apiUtil: APIUtilService = container.resolve(APIUtilService.self)!

    private lazy var api: WSNetServerAPI = container.resolve(WSNetServerAPI.self)!

    private let consoleLogger = Logger(subsystem: "Windscribe-tunnel", category: "com.windscribe.vpn")

    // MARK: Properties

    private var startHandler: ((Error?) -> Void)?
    private var stopHandler: (() -> Void)?
    private var vpnReachability = OpenVPNReachability()
    private var configuration: OpenVPNConfiguration!
    private var UDPSession: NWUDPSession!
    private var TCPConnection: NWTCPConnection!
    private var controlPlane: ControlPlane?
    private lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()

    override func startTunnel(options _: [String: NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        // Check if tunnel was force disconnected (e.g., due to session invalidation)
        // This mirrors WireGuard's credential check but uses a flag since OpenVPN
        // credentials are embedded in tunnel config and can't be deleted
        if preferences.getDisconnectReason() != DisconnectReason.unknown {
            consoleLogger.debug("Tunnel start blocked - force disconnect flag is set")
            logger.logI("PacketTunnelProvider", "Blocked tunnel start - force disconnect active", flushImmediately: true)
            let error = NSError(domain: "com.windscribe", code: 50, userInfo: [
                NSLocalizedDescriptionKey: "Session is invalid"
            ])
            completionHandler(error)
        }

        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
        else {
            fatalError()
        }
        consoleLogger.debug("Starting tunnel.")
        logger.logI("PacketTunnelProvider", "Started OpenVPNAdapter.", flushImmediately: true)
        let properties: OpenVPNConfigurationEvaluation!
        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else { return }
        let configuration = OpenVPNConfiguration()
        configuration.tunPersist = true
        configuration.disableClientCert = true
        configuration.fileContent = ovpnFileContent
        do {
            properties = try vpnAdapter.apply(configuration: configuration)
        } catch {
            logger.logE("PacketTunnelProvider", "Failed to apply configuration to OpenVPNAdapter: \(error.localizedDescription)", flushImmediately: true)
            completionHandler(error)
            return
        }

        if !properties.autologin {
            if let username: String = providerConfiguration["username"] as? String, let password: String = providerConfiguration["password"] as? String {
                let credentials = OpenVPNCredentials()
                credentials.username = username
                credentials.password = password
                do {
                    logger.logI("PacketTunnelProvider", "Added credentials to OpenVPNAdapter.", flushImmediately: true)
                    try vpnAdapter.provide(credentials: credentials)
                } catch {
                    logger.logE("PacketTunnelProvider", "Failed to provide credentials: \(error.localizedDescription)", flushImmediately: true)
                    completionHandler(error)
                    return
                }
            }
        }
        logger.logI("PacketTunnelProvider", "OpenVPN Adapter started successfully.", flushImmediately: true)
        vpnReachability.startTracking { [weak self] status in
            guard status != .notReachable else { return }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
        }

        if startProxy(ovpnData: ovpnFileContent) {
            // Wait for proxy to start listening for incoming connections..
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5) { [weak self] in
                guard let self = self else { return }
                self.startHandler = completionHandler
                self.vpnAdapter.connect(using: self.packetFlow)
            }
        } else {
            startHandler = completionHandler
            logger.logI("PacketTunnelProvider", "Connecting to OpenVPNAdapter.", flushImmediately: true)
            vpnAdapter.connect(using: packetFlow)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        logger.logI("PacketTunnelProvider", "Stopping OpenVPNAdapter with \(reason)")
        stopHandler = completionHandler
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        logger.logI("PacketTunnelProvider", "Reason for disconnect \(reason.rawValue)", flushImmediately: true)
        vpnAdapter.disconnect()
        completionHandler()
    }

    /// Initialises and starts proxy if required
    /// Proxy blocks thread untill unregisterd.
    /// - Parameters OVPN fIle content.
    /// - Returns if proxy started successfully..
    private func startProxy(ovpnData: Data) -> Bool {
        if let line = String(decoding: ovpnData, as: UTF8.self).split(separator: "\n").first(where: { $0.starts(with: "local-proxy") }) {
            guard let proxyInfo = ProxyInfo(text: String(line)) else {
                return false
            }
            guard let path = proxyLogFilePath() else { return false }
            DispatchQueue.global(qos: .background).async {
                let logFilePathCString = (path as NSString).utf8String
                let listenAddressCString = (Proxy.localEndpoint as NSString).utf8String
                let remoteAddressCString = (proxyInfo.remoteEndpoint as NSString).utf8String
                let goLogFilePath = _GoString_(p: logFilePathCString, n: Int(strlen(logFilePathCString!)))
                let goListenAddress = _GoString_(p: listenAddressCString, n: Int(strlen(listenAddressCString!)))
                let goRemoteAddress = _GoString_(p: remoteAddressCString, n: Int(strlen(remoteAddressCString!)))
                Initialise(0, goLogFilePath)
                var censorship = GoUint8(0)
                if self.preferences.isCircumventCensorshipEnabled() {
                    censorship = GoUint8(1)
                }
                StartProxy(goListenAddress, goRemoteAddress, GoInt(proxyInfo.proxyType.rawValue), GoInt(Proxy.mtu), censorship)
            }
            return true
        }
        return false
    }

    /// Creates empty log file for proxy.
    /// - Returns optional log file path.
    /// - Note max file size 5KB
    private func proxyLogFilePath() -> String? {
        let dir = logger.logDirectory?.path ?? ""
        let path = "\(dir)/proxy.log"
        if !FileManager.default.fileExists(atPath: path) {
            FileManager.default.createFile(atPath: path, contents: nil)
        }
        do {
            if let fileSize = try FileManager.default.attributesOfItem(atPath: path)[FileAttributeKey.size] as? Int {
                if fileSize > 1024 * 5 {
                    FileManager.default.createFile(atPath: path, contents: nil)
                }
            }
        } catch {
            logger.logE("PacketTunnelProvider", "Failed to check/clear proxy log file: \(error)", flushImmediately: true)
        }
        return path
    }

    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }

    override func sleep(completionHandler: @escaping () -> Void) {
        completionHandler()
    }

    override func wake() {
        consoleLogger.debug("Device wake up.")
        controlPlane?.checkTunnelHealth()
    }

    // MARK: - TunnelCredentialsManaging

    func deleteCredentials(error: NSError) {
        // OpenVPN credentials are passed per-connection, not stored persistently
        // Log the action for visibility
        consoleLogger.debug("Credentials invalidated for OpenVPN tunnel.")
        logger.logI("PacketTunnelProvider", "OpenVPN credentials invalidated.", flushImmediately: true)
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }
}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    func openVPNAdapter(_: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (Error?) -> Void) {
        if ConnectedDNSType(value: preferences.getConnectedDNS()) == .custom {
            let customDNSValue = preferences.getCustomDNSValue()
            logger.logI("PacketTunnelProvider", "User DNS configuration: \(customDNSValue.description)", flushImmediately: true)
            if let dnsSettings = dnsSettingsManager.makeDNSSettings(from: customDNSValue) {
                networkSettings?.dnsSettings = dnsSettings
            }
        }
        networkSettings?.dnsSettings?.matchDomains = [""]
        setTunnelNetworkSettings(networkSettings, completionHandler: completionHandler)
    }

    func openVPNAdapter(_: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message _: String?) {
        #if os(iOS)
        WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
        #endif

        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }
            guard let startHandler = startHandler else { return }
            startHandler(nil)
            self.startHandler = nil
                // Initialize control plane when tunnel is ready
                if controlPlane == nil {
                    controlPlane = ControlPlane(apiUtil: apiUtil,api: api,preferences: preferences,credentialsManager:self, tunnelProvider: self, consoleLogger: self.consoleLogger)
                }
                consoleLogger.debug("Tunnel connected, checking tunnel health.")
                controlPlane?.checkTunnelHealth()
        case .disconnected:
            guard let stopHandler = stopHandler else { return }
            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }
            stopHandler()
            self.stopHandler = nil
        case .reconnecting:
            reasserting = true
            consoleLogger.debug("Reconnecting, checking tunnel health.")
            controlPlane?.checkTunnelHealth()
        default:
            break
        }
    }

    func openVPNAdapter(_: OpenVPNAdapter, handleError error: Error) {
        guard let fatal = (error as NSError).userInfo[OpenVPNAdapterErrorFatalKey] as? Bool, fatal == true else {
            return
        }
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }

        if let startHandler = startHandler {
            startHandler(error)
            self.startHandler = nil
        } else {
            cancelTunnelWithError(error)
        }
    }
}

extension PacketTunnelProvider: OpenVPNAdapterPacketFlow {
    func readPackets(completionHandler: @escaping ([Data], [NSNumber]) -> Void) {
        packetFlow.readPackets(completionHandler: completionHandler)
    }

    func writePackets(_ packets: [Data], withProtocols protocols: [NSNumber]) -> Bool {
        return packetFlow.writePackets(packets, withProtocols: protocols)
    }
}

extension NEPacketTunnelFlow: @retroactive OpenVPNAdapterPacketFlow {}
