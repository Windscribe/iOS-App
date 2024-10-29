//
//  VPNManager.swift
//  Windscribe
//
//  Created by Yalcin on 2019-01-10.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Security
import RealmSwift
import Swinject
import RxSwift

class IKEv2VPNManager {

    static let shared = IKEv2VPNManager()
    let neVPNManager = NEVPNManager.shared()
    var lastConnectionStatus: NEVPNStatus?
    var neVPNManagerConnectionObserver: NSObjectProtocol?
    var lastDnsHostname = ""
    var lastHostname = ""
    var lastServerAddress = ""
    var lastStaticIPCredentials: StaticIPCredentials?
    var lastObjectType: Object.Type?
    var noResponseTimer: Timer?
    lazy var preferences = Assembler.resolve(Preferences.self)
    lazy var logger = Assembler.resolve(FileLogger.self)
    lazy var localDatabase = Assembler.resolve(LocalDatabase.self)
    private var killSwitch: Bool = DefaultValues.killSwitch
    private var allowLane: Bool = DefaultValues.allowLaneMode
    private lazy var keychainDb = Assembler.resolve(KeyChainDatabase.self)
    let disposeBag = DisposeBag()

    private func loadData() {
        preferences.getKillSwitch().subscribe { data in
            self.killSwitch = data ?? DefaultValues.killSwitch
        }.disposed(by: disposeBag)
        preferences.getAllowLane().subscribe { data in
            self.allowLane = data ?? DefaultValues.allowLaneMode
        }.disposed(by: disposeBag)
    }

    private func configure(username: String,
                   dnsHostname: String,
                   hostname: String,
                   ip: String,
                   completion: @escaping (_ result: Bool,
                                          _ error: String?) -> Void ) {
        loadData()
        neVPNManager.loadFromPreferences { (error) in
            if error == nil {
                let serverCredentials = self.keychainDb.retrieve(username: username)
                let ikeV2Protocol = NEVPNProtocolIKEv2()
                ikeV2Protocol.disconnectOnSleep = false
                ikeV2Protocol.authenticationMethod = .none
                ikeV2Protocol.useExtendedAuthentication = true
                ikeV2Protocol.enablePFS = true
                // Using direct ip for server does not work in iOS <=13
                let legacyOS = NSString(string: UIDevice.current.systemVersion).doubleValue <= 13
                // Changes for the ikev2 issue on ios 16 and kill switch on
                if #available(iOS 16.0, *) {
                    if self.killSwitch || !self.allowLane {
                        ikeV2Protocol.remoteIdentifier = hostname
                        ikeV2Protocol.localIdentifier = username
                        ikeV2Protocol.serverAddress = hostname
                    } else {
                        ikeV2Protocol.serverAddress = ip
                        ikeV2Protocol.serverCertificateCommonName = hostname
                    }
                } else if legacyOS {
                    ikeV2Protocol.remoteIdentifier = hostname
                    ikeV2Protocol.localIdentifier = username
                    ikeV2Protocol.serverAddress = hostname
                } else {
                    ikeV2Protocol.serverAddress = ip
                    ikeV2Protocol.serverCertificateCommonName = hostname
                }

                ikeV2Protocol.passwordReference = serverCredentials
                ikeV2Protocol.username = username
                ikeV2Protocol.sharedSecretReference = serverCredentials
                #if os(iOS)
                if #available(iOS 13.0, *) {
                    // changing enableFallback to true for https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/362
                    ikeV2Protocol.enableFallback = true
                }
                #endif
                ikeV2Protocol.ikeSecurityAssociationParameters.encryptionAlgorithm =  NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
                ikeV2Protocol.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
                ikeV2Protocol.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
                ikeV2Protocol.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
                ikeV2Protocol.childSecurityAssociationParameters.encryptionAlgorithm =  NEVPNIKEv2EncryptionAlgorithm.algorithmAES256GCM
                ikeV2Protocol.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group21
                ikeV2Protocol.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA256
                ikeV2Protocol.childSecurityAssociationParameters.lifetimeMinutes = 1440

                self.neVPNManager.protocolConfiguration = ikeV2Protocol

#if os(iOS)

                // Changes made for Non Rfc-1918 . includeallnetworks​ =  True and excludeLocalNetworks​ = False
                if #available(iOS 15.1, *) {
                    self.neVPNManager.protocolConfiguration?.includeAllNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.killSwitch  : true
                    self.neVPNManager.protocolConfiguration?.excludeLocalNetworks = VPNManager.shared.checkLocalIPIsRFC() ? self.allowLane  : false
                }
                // iOS 16.0+ excludeLocalNetworks does'nt get enforced without killswitch.
                if #available(iOS 16.0, *) {
                    if !self.allowLane {
                        self.neVPNManager.protocolConfiguration?.includeAllNetworks = true
                    }
                }
#endif

                self.neVPNManager.onDemandRules?.removeAll()
                self.neVPNManager.onDemandRules = VPNManager.shared.getOnDemandRules()
                self.neVPNManager.isEnabled = true
                self.neVPNManager.localizedDescription = Constants.appName
                self.neVPNManager.saveToPreferences(completionHandler: { (error) in
                    self.neVPNManager.loadFromPreferences { (error) in
                        if error == nil {
                            self.logger.logD(self, "VPN configuration successful. Username: \(username)")
                            completion(true, nil)
                        } else {
                            self.logger.logE(self, "Error when saving vpn preferences\(error.debugDescription).")
                            completion(false, error?.localizedDescription)
                        }
                    }
                })
                self.logger.logD(self, "KillSwitch option set by user is \(self.killSwitch )")
                self.logger.logD(self, "Allow lan option set by user is \(self.allowLane )")

#if os(iOS)

                if #available(iOS 15.1, *) {
                    self.logger.logD(self, "KillSwitch in IKEv2 VPNManager is \( String(describing: self.neVPNManager.protocolConfiguration?.includeAllNetworks))")
                    self.logger.logD(self, "Allow lan in IKEv2 VPNManager is \( String(describing: self.neVPNManager.protocolConfiguration?.excludeLocalNetworks))")
                }
#endif
            }
        }
    }

    /// Sometimes If another ikev2 profile is configured and kill switch is on VPNManager may not respond.
    private func handleVPNManagerNoResponse() {
        if self.killSwitch {
            noResponseTimer = Timer.scheduledTimer(withTimeInterval: 15, repeats: false) { _ in
                VPNManager.shared.disconnectOrFail()
            }
        }
    }

    private func connect() {
//        VPNManager.shared.activeVPNManager = VPNManagerType.iKEV2
//        self.logger.logD(self, "Connecting via IKEv2.")
//        if OpenVPNManager.shared.isConnected() {
//            VPNManager.shared.restartOnDisconnect = true
//            OpenVPNManager.shared.disconnect()
//        } else if WireGuardVPNManager.shared.isConnected() {
//            VPNManager.shared.restartOnDisconnect = true
////            WireGuardVPNManager.shared.disconnect()
//        } else {
//            if IKEv2VPNManager.shared.neVPNManager.connection.status == .connected ||
//                IKEv2VPNManager.shared.neVPNManager.connection.status == .connecting {
//                VPNManager.shared.restartOnDisconnect = true
//                IKEv2VPNManager.shared.restartConnection()
//            } else {
//                OpenVPNManager.shared.removeProfile { [weak self] (result, error) in
//                    //                    WireGuardVPNManager.shared.removeProfile { [weak self] (result, error) in
//                    if result {
//                        self?.neVPNManager.isOnDemandEnabled = DefaultValues.firewallMode
//                        self?.neVPNManager.isEnabled = true
//                        self?.neVPNManager.saveToPreferences { (error) in
//                            self?.neVPNManager.loadFromPreferences(completionHandler: { (error) in
//                                do {
//                                    try self?.neVPNManager.connection.startVPNTunnel()
//                                    self?.handleVPNManagerNoResponse()
//                                    self?.logger.logD(IKEv2VPNManager.self, "IKEv2 VPN tunnel started.")
//
//                                } catch let error {
//                                    self?.logger.logE(IKEv2VPNManager.self, "Error when trying to connect with vpn. \(error.localizedDescription)")
//                                }
//                            })
//                        }
//                    } else {
//                        self?.logger.logE(IKEv2VPNManager.self, "Error when removing OpenVPN VPN profile. \(error ?? "")")
//
//                    }
//                }
////            }
//            }
//        }
    }

    private func disconnect(restartOnDisconnect: Bool = false, force: Bool = false) {
        if neVPNManager.connection.status == .disconnected && !force {
            return
        }
        neVPNManager.loadFromPreferences(completionHandler: { [weak self] (error) in
            if error == nil, self?.neVPNManager.protocolConfiguration?.username != nil {
                self?.neVPNManager.isOnDemandEnabled = VPNManager.shared.connectIntent
#if os(iOS)

                if #available(iOS 15.1, *) {
                    if restartOnDisconnect {
                        self?.neVPNManager.protocolConfiguration?.includeAllNetworks = false
                    } else {
                        self?.neVPNManager.protocolConfiguration?.includeAllNetworks = self?.killSwitch ?? DefaultValues.killSwitch
                    }
                }
                #endif
                self?.neVPNManager.saveToPreferences { [weak self] _ in
                    self?.neVPNManager.loadFromPreferences(completionHandler: { _ in
                        self?.neVPNManager.connection.stopVPNTunnel()
                    })
                }
            }
        })
    }

    private func restartConnection() {
        self.logger.logD(self, "Restarting IKEv2 connection.")

        disconnect(restartOnDisconnect: true)
    }

    func setOnDemandMode() {
        self.setOnDemandMode(DefaultValues.firewallMode)
    }

    func setKillSwitchMode() {
        neVPNManager.loadFromPreferences(completionHandler: { [weak self] _ in
#if os(iOS)

            if #available(iOS 15.1, *) {
                self?.neVPNManager.protocolConfiguration?.includeAllNetworks = self?.killSwitch ?? DefaultValues.killSwitch
            }
            #endif
            self?.neVPNManager.saveToPreferences { [weak self] _ in
                self?.neVPNManager.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    func setAllowLanMode() {
        neVPNManager.loadFromPreferences(completionHandler: { [weak self] _ in
#if os(iOS)

            if #available(iOS 15.1, *) {
                self?.neVPNManager.protocolConfiguration?.excludeLocalNetworks = self?.allowLane ?? DefaultValues.allowLaneMode
            }
            #endif
            self?.neVPNManager.saveToPreferences { [weak self] _ in
                self?.neVPNManager.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    func setOnDemandMode(_ status: Bool) {
        neVPNManager.loadFromPreferences(completionHandler: { [weak self] _ in
            self?.neVPNManager.isOnDemandEnabled = status
            self?.neVPNManager.saveToPreferences { [weak self] _ in
                self?.neVPNManager.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    func updateOnDemandRules() {
        neVPNManager.loadFromPreferences(completionHandler: { [weak self] _ in
            self?.neVPNManager.onDemandRules?.removeAll()
            self?.neVPNManager.onDemandRules = VPNManager.shared.getOnDemandRules()
            self?.neVPNManager.saveToPreferences { [weak self] _ in
                self?.neVPNManager.loadFromPreferences(completionHandler: { _ in
                })
            }
        })
    }

    private func removeProfile(completion: @escaping (_ result: Bool,
                                              _ error: String?) -> Void) {
        neVPNManager.loadFromPreferences(completionHandler: { [weak self] _ in
            if self?.neVPNManager.protocolConfiguration?.username != nil {
                self?.neVPNManager.removeFromPreferences { [weak self] _ in
                    self?.neVPNManager.loadFromPreferences(completionHandler: { _ in
                        completion(true, nil)
                    })
                }
            } else {
                completion(true, nil)
            }
        })
    }

    func isConfigured() -> Bool {
        return neVPNManager.protocolConfiguration?.username != nil
    }

    func isConnected() -> Bool {
        return neVPNManager.connection.status == .connected
    }

    func isConnecting() -> Bool {
        return neVPNManager.connection.status == .connecting
    }

    func toggle() {
        if neVPNManager.connection.status == .disconnected {
            connect()
        } else {
            disconnect()
        }
    }

    func getVPNStatus() -> String {
        switch self.neVPNManager.connection.status {
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

    func configureDummy(completion: @escaping (_ result: Bool,
                                              _ error: String?) -> Void) {
        configure(username: "Windscribe",
                  dnsHostname: "0.0.0.0",
                  hostname: "127.0.0.1", ip: "0.0.0.0") { (result, error) in
            completion(result, error)
        }
    }

    private func configureWithSavedCredentials(completion: @escaping (_ result: Bool,
                                                              _ error: String?) -> Void) {
        guard let selectedNode = VPNManager.shared.selectedNode else {
            self.logger.logE(self, "Failed to configure IKEv2 profile. \(Errors.hostnameNotFound.localizedDescription)")
            completion(false, Errors.hostnameNotFound.localizedDescription)
            return
        }

        let ip = selectedNode.ip1 ?? selectedNode.staticIpToConnect
        guard let ip = ip else {
            self.logger.logE(self, "Ip1 and ip3 are not avaialble to configure this profile.")
            completion(false, "Ip1 and ip3 are not avaialble to configure this profile.")
            return
        }
        self.logger.logD(self, "Configuring VPN profile with saved credentials. \(selectedNode.hostname)")

        var base64username = ""
        var base64password = ""
        if let staticIPCredentials = VPNManager.shared.selectedNode?.staticIPCredentials,
           let username = staticIPCredentials.username,
           let password = staticIPCredentials.password {
            base64username = username
            base64password = password
        } else {
            if let credentials = localDatabase.getIKEv2ServerCredentials() {
                base64username = credentials.username.base64Decoded()
                base64password = credentials.password.base64Decoded()
            }
        }
        if base64username == "" ||
            base64password == "" {
            completion(false, Errors.missingAuthenticationValues.localizedDescription)
            self.logger.logE(self, "Can't establish a VPN connection, missing authentication values.")
        } else {
            keychainDb.save(username: base64username,
                                        password: base64password)
            configure(username: base64username,
                      dnsHostname: selectedNode.dnsHostname,
                      hostname: selectedNode.hostname, ip: ip) { (result, error) in
                completion(result, error)
            }
        }
    }
}
