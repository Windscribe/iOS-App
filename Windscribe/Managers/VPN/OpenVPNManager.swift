//
//  OpenVPNManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-04-24.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Security
import RealmSwift
import Swinject
import RxSwift

class OpenVPNManager {

    static let shared = OpenVPNManager()
    var providerManager: NETunnelProviderManager!
    var lastDnsHostname = ""
    var lastServerAddress = ""
    var lastStaticIPCredentials: StaticIPCredentials?
    var lastObjectType: Object.Type?
    var openVPNLogKey = "OpenVPNLogs"
    lazy var preferences = Assembler.resolve(Preferences.self)
    lazy var logger = Assembler.resolve(FileLogger.self)
    lazy var fileDatabase = Assembler.resolve(FileDatabase.self)
    lazy var localDatabase = Assembler.resolve(LocalDatabase.self)
    private lazy var keychainDb = Assembler.resolve(KeyChainDatabase.self)
    private var killSwitch: Bool = DefaultValues.killSwitch
    private var allowLane: Bool = DefaultValues.allowLaneMode
    let disposeBag = DisposeBag()

    func setup(completion: @escaping () -> Void) {
        loadData()
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            if error == nil {
                self?.providerManager = managers?.first {
                    $0.protocolConfiguration?.username == TextsAsset.openVPN
                } ?? NETunnelProviderManager()
                completion()
            } else {
                self?.logger.logE( OpenVPNManager.self, "Error occured when setting up Provider Manager \(String(describing: error?.localizedDescription))")
                completion()
            }
        }
    }

    private func loadData() {

        preferences.getKillSwitch().subscribe { data in
            self.killSwitch = data ?? DefaultValues.killSwitch
        }.disposed(by: disposeBag)
        preferences.getAllowLane().subscribe { data in
            self.allowLane = data ?? DefaultValues.allowLaneMode
        }.disposed(by: disposeBag)
    }

    func getConfiguration(username: String,
                          password: String,
                          protocolType: String,
                          serverAddress: String,
                          port: String,
                          x509Name: String?,
                          proxyInfo: ProxyInfo?,
                          completion: @escaping (_ result: Bool,
                                                 _ configUsername: String?,
                                                 _ configPassword: String?,
                                                 _ configFilePath: String?,
                                                 _ configData: Data?) -> Void) {
        let openVPNConfigFilePath = FilePaths.openVPN
        if let customConfig = VPNManager.shared.selectedNode?.customConfig,
           let customConfigId = customConfig.id,
           let authRequired = customConfig.authRequired {
            let configFilePath = "\(customConfigId).ovpn"
            guard let configData = fileDatabase.readFile(path: configFilePath) else { return }
            if customConfig.username != "" &&
                customConfig.password != "" {
                let user = customConfig.username!.base64Decoded() == "" ? customConfig.username! : customConfig.username!.base64Decoded()
                let pass = customConfig.password!.base64Decoded() == "" ? customConfig.password! : customConfig.password!.base64Decoded()
                completion(true,
                           user,
                           pass,
                           configFilePath, configData)

            } else {
                completion(!authRequired, nil, nil, configFilePath, configData)
            }
        } else {
            let protoLine = "proto \(protocolType.lowercased())"
            let remoteLine = "remote \(serverAddress) \(port)"
            let x509NameLine = "verify-x509-name \(x509Name!) name"
            let proxyLine = proxyInfo?.text
            self.logger.logD( OpenVPNManager.self, proxyLine?.debugDescription ?? "")
            guard let configData = fileDatabase.readFile(path: openVPNConfigFilePath),
                  let stringData = String(data: configData,
                                          encoding: String.Encoding.utf8) else { return }
            var lines = stringData.components(separatedBy: "\n")
            lines.removeAll { s in
                s.starts(with: "local-proxy")
            }
            var configFound = false
            var x509Found = false
            for (index, line) in lines.enumerated() {
                if line.contains("proto ") {
                    lines[index] = protoLine
                    configFound = true
                }
                if line.contains("remote ") {
                    lines[index] = remoteLine
                    configFound = true
                }
                if line.starts(with: "verify-x509-name") {
                    lines[index] = x509NameLine
                    x509Found = true
                }
            }
            if configFound == false {
                lines.insert(protoLine, at: 2)
                lines.insert(remoteLine, at: 3)
            }

            if x509Found == false {
                lines.insert(x509NameLine, at: 4)
            }

            if let proxyLine = proxyLine {
                lines.append(proxyLine)
            }
            if preferences.isCircumventCensorshipEnabled() {
                lines.append("udp-stuffing")
                lines.append("tcp-split-reset")
            }
            guard let appendedConfigData = lines.joined(separator: "\n").data(using: String.Encoding.utf8) else { return }

            fileDatabase.removeFile(path: FilePaths.openVPN)
            fileDatabase.saveFile(data: appendedConfigData,
                                               path: FilePaths.openVPN)
            completion(true, username, password, openVPNConfigFilePath, appendedConfigData)
        }
    }

    func configure(username: String,
                   password: String,
                   protocolType: String,
                   serverAddress: String,
                   port: String,
                   compressionEnabled: Bool? = false,
                   x509Name: String?,
                   proxyInfo: ProxyInfo? = nil,
                   completion: @escaping (_ result: Bool,
                                          _ error: String?) -> Void ) {
        providerManager?.loadFromPreferences { [weak self] error in
            guard let self = self else { return }
            if error == nil {
                self.getConfiguration(username: username,
                                      password: password,
                                      protocolType: protocolType,
                                      serverAddress: serverAddress,
                                      port: port,
                                      x509Name: x509Name,
                                      proxyInfo: proxyInfo,
                                      completion: { (result, configUsername, configPassword, _, configData) in
                    if result {
                        guard let configData = configData else { return }
                        let tunnelProtocol = NETunnelProviderProtocol()
                        tunnelProtocol.username = TextsAsset.openVPN
                        tunnelProtocol.serverAddress = serverAddress
                        tunnelProtocol.providerBundleIdentifier = "\(Bundle.main.bundleID ?? "").PacketTunnel"
                        if let configUsername = configUsername, let configPassword = configPassword {
                            tunnelProtocol.providerConfiguration = ["ovpn": configData,
                                                                    "username": configUsername,
                                                                    "password": configPassword,
                                                                    "compressionEnabled": compressionEnabled ?? false]
                        } else {
                            tunnelProtocol.providerConfiguration = ["ovpn": configData,
                                                                    "compressionEnabled": compressionEnabled ?? false]
                        }

                        tunnelProtocol.disconnectOnSleep = false

                        self.providerManager.protocolConfiguration = tunnelProtocol

#if os(iOS)

                        // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
                        if #available(iOS 15.1, *) {

                            self.providerManager.protocolConfiguration?.includeAllNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.killSwitch : true
                            self.providerManager.protocolConfiguration?.excludeLocalNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.allowLane : false
                        }
                        // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
                        if #available(iOS 16.0, *) {
                            if !self.allowLane {
                                self.providerManager.protocolConfiguration?.includeAllNetworks = true
                            }
                        }
                        #endif
                        self.providerManager.onDemandRules?.removeAll()
                        self.providerManager.onDemandRules = VPNManager.shared.getOnDemandRules()
                        self.providerManager.isEnabled = true
                        self.providerManager.localizedDescription = Constants.appName
                        self.providerManager.saveToPreferences(completionHandler: { (error) in
                            if error == nil {
                                self.providerManager.loadFromPreferences(completionHandler: { _ in
                                    self.logger.logD( OpenVPNManager.self, "VPN configuration successful. Username: \(username)")
                                    completion(true, nil)
                                })
                            } else {
                                completion(false, "Error when loading vpn prefences.")
                                self.logger.logE( OpenVPNManager.self, "Error when loading vpn prefences. \(String(describing: error?.localizedDescription))")

                            }
                        })
                    }
                })
            } else {
                completion(false, "Error when loading vpn prefences.")
                self.logger.logE( OpenVPNManager.self, "Error when loading vpn prefences. \(String(describing: error?.localizedDescription))")
            }
        }
    }

    func connect() {
        self.logger.logD( OpenVPNManager.self, "Connecting via OpenVPN.")

        VPNManager.shared.activeVPNManager = VPNManagerType.openVPN
        if OpenVPNManager.shared.providerManager?.connection.status == .connected ||
            OpenVPNManager.shared.providerManager?.connection.status == .connecting {
            VPNManager.shared.restartOnDisconnect = true
            OpenVPNManager.shared.restartConnection()
        } else {
            IKEv2VPNManager.shared.removeProfile(completion: { (result, error) in
                WireGuardVPNManager.shared.removeProfile { [weak self] (result, error) in
                    guard let self = self else { return }
                    if result {
                        self.providerManager?.isOnDemandEnabled = DefaultValues.firewallMode
                        self.providerManager?.isEnabled = true
                        self.providerManager?.saveToPreferences { (error) in
                            self.providerManager?.loadFromPreferences(completionHandler: { (error) in
                                do {
                                    try self.providerManager?.connection.startVPNTunnel()
                                    self.logger.logD( OpenVPNManager.self, "OpenVPN tunnel started.")
                                } catch {
                                    self.logger.logE( OpenVPNManager.self, "Error occured when establishing OpenVPN connection: \(error.localizedDescription)")
                                }
                            })
                        }
                    } else {
                        self.logger.logE( OpenVPNManager.self, "Error when removing IKEv2 VPN profile. \(error ?? "")")
                    }
                }
            })
        }
    }

    func disconnect(restartOnDisconnect: Bool = false, force: Bool = true) {
        if self.providerManager.connection.status == .disconnected && !force { return }
        self.providerManager?.loadFromPreferences(completionHandler: { (error) in
            if error == nil, self.isConfigured() {
                self.providerManager?.isOnDemandEnabled = VPNManager.shared.connectIntent
#if os(iOS)

                if #available(iOS 14.0, *) {
                    self.providerManager?.protocolConfiguration?.includeAllNetworks = self.killSwitch
                }
                #endif
                self.providerManager?.saveToPreferences { [weak self] _ in
                    self?.providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
                        self?.providerManager?.connection.stopVPNTunnel()
                    })
                }
            }
        })
    }

    func restartConnection() {
        self.logger.logD( OpenVPNManager.self, "Restarting OpenVPN connection.")
        self.disconnect(restartOnDisconnect: true)
    }

    func toggle() {
        if providerManager?.connection.status == .disconnected {
            connect()
        } else {
            disconnect()
        }
    }

    func setOnDemandMode() {
        self.setOnDemandMode(DefaultValues.firewallMode)
    }

    func setKillSwitchMode() {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
#if os(iOS)

            if #available(iOS 15.1, *) {
                self?.providerManager?.protocolConfiguration?.includeAllNetworks = self?.killSwitch ?? DefaultValues.killSwitch
            }
            #endif
            self?.providerManager?.saveToPreferences { [weak self] _ in
                self?.providerManager?.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    func setAllowLanMode() {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
#if os(iOS)

            if #available(iOS 15.1, *) {
                self?.providerManager?.protocolConfiguration?.excludeLocalNetworks = self?.allowLane ?? DefaultValues.allowLaneMode
            }
            #endif
            self?.providerManager?.saveToPreferences { [weak self] _ in
                self?.providerManager?.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    func setOnDemandMode(_ status: Bool) {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
            self?.providerManager?.isOnDemandEnabled = status
            self?.providerManager?.saveToPreferences { [weak self] _ in
                self?.providerManager?.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    func updateOnDemandRules() {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
            self?.providerManager.onDemandRules?.removeAll()
            self?.providerManager.onDemandRules = VPNManager.shared.getOnDemandRules()
            self?.providerManager?.saveToPreferences { [weak self] _ in
                self?.providerManager?.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    func getVPNStatus() -> String {
        guard let status = providerManager?.connection.status else { return "" }
        switch status {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting"
        case .disconnected:
            return "Disconnected"
        case .disconnecting:
            return "Disconnecting"
        default:
            return "Not Available"
        }
    }

    func configureWithSavedCredentials(completion: @escaping (_ result: Bool,
                                                              _ error: String?) -> Void) {
        guard let selectedNode = VPNManager.shared.selectedNode,
              let x509Name = selectedNode.ovpnX509 else { return }

        var serverAddress = selectedNode.serverAddress
        self.logger.logD( OpenVPNManager.self, "Configuring VPN profile with saved credentials. \(String(describing: serverAddress))")

        var base64username = ""
        var base64password = ""
        var protocolType = ConnectionManager.shared.getNextProtocol().protocolName
        var port = ConnectionManager.shared.getNextProtocol().portName
        logger.logD(self, "\(protocolType) \(port)")

        if VPNManager.shared.selectedNode?.customConfig?.authRequired == false {
            configure(username: base64username,
                      password: base64password,
                      protocolType: protocolType,
                      serverAddress: serverAddress,
                      port: port,
                      x509Name: x509Name,
                      proxyInfo: nil
            ) { (result, error) in
                completion(result, error)
            }
        } else {
            if let staticIPCredentials = VPNManager.shared.selectedNode?.staticIPCredentials,
               let username = staticIPCredentials.username,
               let password = staticIPCredentials.password {
                base64username = username
                base64password = password
            } else {
                if let credentials = localDatabase.getOpenVPNServerCredentials() {
                    base64username = credentials.username.base64Decoded()
                    base64password = credentials.password.base64Decoded()
                }
            }

            if base64username == "" || base64password == "" {
                completion(false, Errors.missingAuthenticationValues.localizedDescription)
                self.logger.logE( OpenVPNManager.self, "Can't establish a VPN connection, missing authentication values.")

            } else {
                // Build proxy info
                var proxyInfo: ProxyInfo?
                if protocolType == stealth  || protocolType == wsTunnel {
                    var proxyProtocol = ProxyType.wstunnel
                    var remoteAddress = selectedNode.ip1
                    if protocolType == stealth {
                        proxyProtocol = .stunnel
                        remoteAddress = selectedNode.ip3
                    }
                    guard let remoteAddress = remoteAddress else {
                        completion(false, "Missing remote address in selected location.")
                        return
                    }
                    proxyInfo = ProxyInfo(remoteServer: remoteAddress, remotePort: port, proxyType: proxyProtocol)
                    if proxyInfo != nil {
                        // Connect OpenVPN to proxy
                        serverAddress = Proxy.localAddress
                        port = Proxy.defaultProxyPort
                        protocolType = Proxy.internalProtocol
                    }
                }

                keychainDb.save(username: base64username, password: base64password)
                self.configure(username: base64username,
                               password: base64password,
                               protocolType: protocolType,
                               serverAddress: serverAddress,
                               port: port,
                               compressionEnabled: true,
                               x509Name: x509Name,
                               proxyInfo: proxyInfo
                ) { (result, error) in
                    completion(result, error)
                }
            }
        }
    }

    func configureWithCustomConfig(completion: @escaping (_ result: Bool,
                                                         _ error: String?) -> Void) {
        guard let selectedNode = VPNManager.shared.selectedNode else { return }
        self.logger.logD( OpenVPNManager.self, "Configuring VPN profile with custom configuration. \(String(describing: selectedNode.serverAddress))")
        if self.providerManager?.connection.status != .connecting {
            guard let customConfig = VPNManager.shared.selectedNode?.customConfig,
                  let protocolType = customConfig.protocolType,
                  let port = customConfig.port else { return }
            if customConfig.authRequired == false {
                self.configure(username: "",
                               password: "",
                               protocolType: protocolType,
                               serverAddress: selectedNode.serverAddress,
                               port: port,
                               x509Name: nil
                ) { (result, error) in
                    completion(result, error)
                }
            } else {
                guard let username = customConfig.username,
                      let password = customConfig.password else { return }
                configure(username: username,
                          password: password,
                          protocolType: protocolType,
                          serverAddress: selectedNode.serverAddress,
                          port: port,
                          x509Name: nil,
                          proxyInfo: nil
                ) { (result, error) in
                    completion(result, error)
                }
            }
        }
    }

    func removeProfile(completion: @escaping (_ result: Bool,
                                              _ error: String?) -> Void) {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
            guard let self = self else { return }
            if self.isConfigured() {
                self.disconnect()
                self.providerManager?.removeFromPreferences { _ in
                    self.providerManager?.loadFromPreferences(completionHandler: { _ in
                        self.setup {
                            completion(true, nil)
                        }
                    })
                }
            } else {
                completion(true, nil)
            }
        })
    }

    func isConfigured() -> Bool {
        return providerManager?.protocolConfiguration?.username == TextsAsset.openVPN
    }

    func isConnected() -> Bool {
        return providerManager?.connection.status == .connected
    }

    func isConnecting() -> Bool {
        return providerManager?.connection.status == .connecting
    }
}
