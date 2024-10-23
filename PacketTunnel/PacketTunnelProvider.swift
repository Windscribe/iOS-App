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
#if canImport(WidgetKit)
import WidgetKit
#endif

class PacketTunnelProvider: NEPacketTunnelProvider {

    // MARK: Dependencies
    private lazy var container: Container = {
        let container = Container()
        container.injectCore()
        return container
    }()
    private lazy var logger: FileLogger = {
        return container.resolve(FileLogger.self)!
    }()
    private lazy var preferences: Preferences = {
        return container.resolve(Preferences.self)!
    }()
    // MARK: Properties
    private var startHandler: ((Error?) -> Void)?
    private var stopHandler: (() -> Void)?
    private var vpnReachability = OpenVPNReachability()
    private var configuration: OpenVPNConfiguration!
    private var UDPSession: NWUDPSession!
    private var TCPConnection: NWTCPConnection!
    private lazy var vpnAdapter: OpenVPNAdapter = {
        let adapter = OpenVPNAdapter()
        adapter.delegate = self
        return adapter
    }()

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        guard
            let protocolConfiguration = protocolConfiguration as? NETunnelProviderProtocol,
            let providerConfiguration = protocolConfiguration.providerConfiguration
        else {
            fatalError()
        }
        let  properties:OpenVPNConfigurationEvaluation!
        guard let ovpnFileContent: Data = providerConfiguration["ovpn"] as? Data else { return }
        let configuration = OpenVPNConfiguration()
        configuration.tunPersist = true
        configuration.disableClientCert = true
        configuration.fileContent = ovpnFileContent
        do {
            properties = try vpnAdapter.apply(configuration: configuration)
        } catch {
            completionHandler(error)
            return
        }

        if !properties.autologin {
            if let username: String = providerConfiguration["username"] as? String, let password: String = providerConfiguration["password"] as? String {
                let credentials = OpenVPNCredentials()
                credentials.username = username
                credentials.password = password
                do {
                    try vpnAdapter.provide(credentials: credentials)
                } catch {
                    completionHandler(error)
                    return
                }
            }
        }

        vpnReachability.startTracking { [weak self] status in
            guard status != .notReachable else { return }
            self?.vpnAdapter.reconnect(afterTimeInterval: 5)
        }

        if startProxy(ovpnData: ovpnFileContent) {
            // Wait for proxy to start listening for incoming connections..
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.5){ [weak self] in
                guard let self = self else { return }
                self.startHandler = completionHandler
                self.vpnAdapter.connect(using: self.packetFlow)
            }
        } else {
            startHandler = completionHandler
            vpnAdapter.connect(using: packetFlow)
        }
    }

    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        stopHandler = completionHandler
        if vpnReachability.isTracking {
            vpnReachability.stopTracking()
        }
        if reason == .authenticationCanceled {
            preferences.saveForceDisconnect(value: true)
        }
        logger.logD(self, "Reason for disconnect \(reason.rawValue)")
        vpnAdapter.disconnect()
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
                let remoteAddressCString = ( proxyInfo.remoteEndpoint as NSString).utf8String
                let goLogFilePath = _GoString_(p: logFilePathCString, n: Int(strlen(logFilePathCString!)))
                let goListenAddress = _GoString_(p: listenAddressCString, n: Int(strlen(listenAddressCString!)))
                let goRemoteAddress = _GoString_(p: remoteAddressCString, n: Int(strlen(remoteAddressCString!)))
                Initialise(0, goLogFilePath)
                var censorship = GoUint8(0)
                if self.preferences.isCircumventCensorshipEnabled() {
                    censorship = GoUint8(1)
                }
                StartProxy(goListenAddress, goRemoteAddress,  GoInt(proxyInfo.proxyType.rawValue), GoInt(Proxy.mtu), censorship)
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
        } catch {}
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
    }

}

extension PacketTunnelProvider: OpenVPNAdapterDelegate {
    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, configureTunnelWithNetworkSettings networkSettings: NEPacketTunnelNetworkSettings?, completionHandler: @escaping (Error?) -> Void) {
        if ConnectedDNSType(value: preferences.getConnectedDNS()) == .custom {
            let customDNSValue = preferences.getCustomDNSValue()
            logger.logD(self, "User DNS configuration: \(customDNSValue.description)")
            if let dnsSettings = DNSSettingsManager.makeDNSSettings(from: customDNSValue) {
                networkSettings?.dnsSettings = dnsSettings
            }
        }
        networkSettings?.dnsSettings?.matchDomains = [""]
        setTunnelNetworkSettings(networkSettings, completionHandler: completionHandler)
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleEvent event: OpenVPNAdapterEvent, message: String?) {
    #if os(iOS)

        if #available(iOSApplicationExtension 14.0, *) {
            WidgetCenter.shared.reloadTimelines(ofKind: "HomeWidget")
        }
    #endif
        switch event {
        case .connected:
            if reasserting {
                reasserting = false
            }
            guard let startHandler = startHandler else { return }
            startHandler(nil)
            self.startHandler = nil
        case .disconnected:
            guard let stopHandler = stopHandler else { return }
            if vpnReachability.isTracking {
                vpnReachability.stopTracking()
            }
            stopHandler()
            self.stopHandler = nil
        case .reconnecting:
            reasserting = true
        default:
            break
        }
    }

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleError error: Error) {
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

    func openVPNAdapter(_ openVPNAdapter: OpenVPNAdapter, handleLogMessage logMessage: String) {
       // self.logger.logD(self, "\(logMessage)")
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
extension NEPacketTunnelFlow: OpenVPNAdapterPacketFlow {}

