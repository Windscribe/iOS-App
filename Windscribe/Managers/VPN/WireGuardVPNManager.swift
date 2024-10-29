//
//  WireGuardVPNManager.swift
//  Windscribe
//
//  Created by Yalcin on 2020-06-30.
//  Copyright © 2020 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Security
import RealmSwift
import WireGuardKit
import Swinject
import RxSwift

class WireGuardVPNManager {

    static let shared = WireGuardVPNManager()
    var providerManager: NETunnelProviderManager!
    var lastDnsHostname = ""
    var lastServerAddress = ""
    var lastStaticIPCredentials: StaticIPCredentials?
    var lastObjectType: Object.Type?
    let wgCredentials = Assembler.resolve(WgCredentials.self)
    lazy var preferences = Assembler.resolve(Preferences.self)
    lazy var fileDatabase = Assembler.resolve(FileDatabase.self)
    lazy var logger = Assembler.resolve(FileLogger.self)
    private var killSwitch: Bool = DefaultValues.killSwitch
    private var allowLane: Bool = DefaultValues.allowLaneMode
    let disposeBag = DisposeBag()

    func setup(completion: @escaping () -> Void) {
        loadData()
        NETunnelProviderManager.loadAllFromPreferences { [weak self] (managers, error) in
            if error == nil {
                self?.providerManager = managers?.first {
                    $0.protocolConfiguration?.username == TextsAsset.wireGuard
                } ?? NETunnelProviderManager()
                self?.providerManager.loadFromPreferences { _ in
                    completion()
                }
            } else {
                self?.logger.logE(WireGuardVPNManager.self, "Error occured when setting up Provider Manager \(String(describing: error?.localizedDescription))")
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

    private func getConfiguration(completion: @escaping (_ tunnelConfiguration: TunnelConfiguration?) -> Void) {
        var configFilePath = "config.conf"
        if let customConfig = VPNManager.shared.selectedNode?.customConfig,
            let customConfigId = customConfig.id {
           configFilePath = "\(customConfigId).conf"
        }
        guard let configData = fileDatabase.readFile(path: configFilePath) else { return }
       guard let stringData = String(data: configData, encoding: String.Encoding.utf8) else { return }
       var tunnelConfiguration: TunnelConfiguration?
       do {
          tunnelConfiguration =  try TunnelConfiguration(fromWgQuickConfig: stringData, called: configFilePath)
          completion(tunnelConfiguration)
       } catch let error {
            logger.logE(WireGuardVPNManager.self, "WireGuard tunnel Error: \(error)")
            completion(nil)
        }
    }

    private func configure(completion: @escaping (_ result: Bool,
                                          _ error: String?) -> Void ) {
        providerManager?.loadFromPreferences { [weak self] error in
            if error == nil,
               let self = self {
                self.getConfiguration { (tunnelConfiguration) in
                    guard let tunnelConfiguration = tunnelConfiguration else { return }
                    self.providerManager.setTunnelConfiguration(tunnelConfiguration, username: TextsAsset.wireGuard, description: Constants.appName)
#if os(iOS)
                    // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
                    if #available(iOS 15.1, *) {
                        self.providerManager.protocolConfiguration?.includeAllNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.killSwitch : true
                        self.providerManager.protocolConfiguration?.excludeLocalNetworks =
                        VPNManager.shared.checkLocalIPIsRFC() ? self.allowLane : false
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
                    self.providerManager.saveToPreferences(completionHandler: { (error) in
                        if error == nil {
                            self.providerManager.loadFromPreferences(completionHandler: { _ in
                                self.logger.logD(WireGuardVPNManager.self, "WireGuard VPN configuration successful.")
                                completion(true, nil)
                            })
                        } else {
                            completion(false, "Error when loading vpn prefences.")
                            self.logger.logE(WireGuardVPNManager.self, "Error when loading vpn prefences. \(String(describing: error?.localizedDescription))")

                        }
                    })
                }
            } else {
                completion(false, "Error when loading vpn prefences.")
                self?.logger.logE(WireGuardVPNManager.self, "Error when loading vpn prefences. \(String(describing: error?.localizedDescription))")
            }
        }
    }

    private func connect() {
//        VPNManager.shared.activeVPNManager = VPNManagerType.wg
//        if WireGuardVPNManager.shared.providerManager?.connection.status == .connected || WireGuardVPNManager.shared.providerManager?.connection.status == .connecting {
//            VPNManager.shared.restartOnDisconnect = true
//            WireGuardVPNManager.shared.restartConnection()
//        } else {
//            IKEv2VPNManager.shared.removeProfile(completion: { (result, error) in
//                OpenVPNManager.shared.removeProfile { (result, error) in
//                     if result {
//                         self.providerManager?.isOnDemandEnabled = DefaultValues.firewallMode
//                        self.providerManager?.isEnabled = true
//                        self.providerManager?.saveToPreferences { (error) in
//                            self.providerManager?.loadFromPreferences(completionHandler: { (error) in
//                                do {
//                                    if let activationId = self.wgCredentials.address?.SHA1() as? NSObject {
//                                        let params: [String: NSObject] = ["activationAttemptId": activationId]
//                                        try self.providerManager?.connection.startVPNTunnel(options: params)
//                                    } else {
//                                        try self.providerManager?.connection.startVPNTunnel()
//                                    }
//                                    self.logger.logD(WireGuardVPNManager.self, "WireGuard tunnel started.")
//
//                                } catch {
//                                    self.logger.logE(WireGuardVPNManager.self, "Error occured when establishing WireGuard connection: \(error.localizedDescription)")
//
//                                }
//                            })
//                        }
//                    } else {
//                        self.logger.logE(WireGuardVPNManager.self, "Error when removing IKEv2 VPN profile. \(error ?? "")")
//                    }
//                }
//            })
//        }
    }

    private func disconnect(restartOnDisconnect: Bool = false, force: Bool = true) {
        if self.providerManager.connection.status == .disconnected && !force { return }
        self.providerManager?.loadFromPreferences(completionHandler: { [weak self] (error) in
            guard let self = self else { return }
            if error == nil,
                self.isConfigured() {
                self.providerManager?.isOnDemandEnabled = VPNManager.shared.connectIntent
#if os(iOS)
                if #available(iOS 15.1, *) {
                    self.providerManager?.protocolConfiguration?.includeAllNetworks = self.killSwitch
                }
#endif
                self.providerManager?.saveToPreferences { _ in
                    self.providerManager?.loadFromPreferences(completionHandler: { _ in
                        self.providerManager?.connection.stopVPNTunnel()
                    })
                }
            }
        })
    }

    private func restartConnection() {
        self.logger.logD(WireGuardVPNManager.self, "Restarting WireGuard connection.")
        disconnect(restartOnDisconnect: true)
    }

    private func configureWithSavedConfig(completion: @escaping (_ result: Bool,
                                                         _ error: String?) -> Void) {
        guard let selectedNode = VPNManager.shared.selectedNode,
              let ip3 = selectedNode.ip3 else { return }
        self.logger.logD(WireGuardVPNManager.self, "Configuring VPN profile with saved configuration. \(String(describing: ip3))")

        if providerManager?.connection.status != .connecting {
            configure { result, error in
                completion(result, error)
            }
        }
    }

    private func configureWithCustomConfig(completion: @escaping (_ result: Bool, _ error: String?) -> Void) {
        guard let selectedNode = VPNManager.shared.selectedNode else { return }
        self.logger.logD(WireGuardVPNManager.self, "Configuring VPN profile with custom configuration. \(String(describing: selectedNode.serverAddress))")
        if self.providerManager?.connection.status != .connecting {
            configure { (result, error) in
                completion(result, error)
            }
        }
    }

    private func removeProfile(completion: @escaping (_ result: Bool, _ error: String?) -> Void) {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
            if self?.isConfigured() ?? false {
                self?.disconnect()
                self?.providerManager?.removeFromPreferences { _ in
                   self?.providerManager?.loadFromPreferences(completionHandler: { _ in
                        self?.setup {
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
        return providerManager?.protocolConfiguration?.username == TextsAsset.wireGuard
    }

    func isConnected() -> Bool {
        return providerManager?.connection.status == .connected
    }

    func isConnecting() -> Bool {
        return providerManager?.connection.status == .connecting
    }

     func setOnDemandMode() {
         setOnDemandMode(DefaultValues.firewallMode)
     }

    func setKillSwitchMode() {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
#if os(iOS)
            if #available(iOS 15.1, *) {
                self?.providerManager?.protocolConfiguration?.includeAllNetworks = self?.killSwitch ?? DefaultValues.killSwitch
            }
#endif
            self?.providerManager?.saveToPreferences { _ in
                self?.providerManager?.loadFromPreferences(completionHandler: { _ in })
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
            self?.providerManager?.saveToPreferences { _ in
                self?.providerManager?.loadFromPreferences(completionHandler: { _ in })
            }
        })
    }

     func setOnDemandMode(_ status: Bool) {
        providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
            self?.providerManager?.isOnDemandEnabled = status
            self?.providerManager?.saveToPreferences { _ in
                self?.providerManager?.loadFromPreferences(completionHandler: { _ in })
            }
        })
     }

     func updateOnDemandRules() {
         providerManager?.loadFromPreferences(completionHandler: { [weak self] _ in
             self?.providerManager.onDemandRules?.removeAll()
             self?.providerManager.onDemandRules = VPNManager.shared.getOnDemandRules()
             self?.providerManager?.saveToPreferences { _ in
                 self?.providerManager?.loadFromPreferences(completionHandler: { _ in })
             }
         })
     }
}
