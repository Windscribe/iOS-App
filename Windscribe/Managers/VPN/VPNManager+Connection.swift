//
//  VPNManager+Connection.swift
//  Windscribe
//
//  Created by Thomas on 16/11/2021.
//  Copyright © 2021 Windscribe. All rights reserved.
//

import Foundation
import RealmSwift
import NetworkExtension
#if canImport(WidgetKit)
import WidgetKit
#endif
import RxSwift

extension VPNManager {
    func selectAnotherNode() {
        if let selectedNode = VPNManager.shared.selectedNode {
            if let randomNode = getRandomNodeInSameGroup(groupId: selectedNode.groupId,
                                                                                   excludeHostname: selectedNode.hostname),
               let newHostname = randomNode.hostname,
               let newIP2 = randomNode.ip2 {
                VPNManager.shared.selectedNode = SelectedNode(countryCode: selectedNode.countryCode,
                                                              dnsHostname: selectedNode.dnsHostname,
                                                              hostname: newHostname,
                                                              serverAddress: newIP2,
                                                              nickName: selectedNode.nickName,
                                                              cityName: selectedNode.cityName,
                                                              groupId: selectedNode.groupId)
            }
        }
    }

    func getRandomNodeInSameGroup(groupId: Int, excludeHostname: String) -> NodeModel? {
        guard let group = localDB.getServers()?.flatMap({ $0.groups }).filter({ $0.id == groupId }).first else { return nil }
        let nodes = group.nodes.filter({ $0.hostname != excludeHostname })
        if nodes.count > 0 {
            let randomIndex = Int.random(in: 0...nodes.count-1)
            return nodes[randomIndex].getNodeModel()
        }
        return nil
    }

    func connectToAnotherNode(forceProtocol: String? = nil) {
        selectAnotherNode()
        connectUsingAutomaticMode()
        self.logger.logD(VPNManager.self, "Establishing a new connection with a random node in the same group.")
    }

    /// Saves Connection Params before connecting.
    /// Sets default protocol and port
    /// if connection mode is manual sets selected protocol and port
    /// if wifi network name is available and prefered protcol is turned on use prefered protocol and port.
    func setNewVPNConnection(forceProtocol: String? = nil) {
        var selectedProtocol = forceProtocol ?? iKEv2
        let forcePort = localDB.getPorts(protocolType: selectedProtocol)?[0]
        var selectedPort = forcePort ?? "443"
        if preferences.getConnectionModeSync() == Fields.Values.manual {
            selectedProtocol = preferences.getSelectedProtocolSync()
            selectedPort = preferences.getSelectedPortSync()
        }
        if let connectedWifi = WifiManager.shared.getConnectedNetwork() {
            if connectedWifi.preferredProtocolStatus == true && !VPNManager.shared.isFromProtocolFailover && !VPNManager.shared.isFromProtocolChange {
                selectedProtocol = connectedWifi.preferredProtocol
                selectedPort = connectedWifi.port
            }
        }
        guard let hostname = VPNManager.shared.selectedNode?.hostname,
              let serverAddress = VPNManager.shared.selectedNode?.serverAddress else { return }
        let vpnConnection = VPNConnection(id: VPNManager.shared.uniqueConnectionId,
                                          hostname: hostname,
                                          serverAddress: serverAddress,
                                          protocolType: selectedProtocol,
                                          port: selectedPort)
        localDB.saveLastConnetion(vpnConnection: vpnConnection).disposed(by: disposeBag)
    }

    func connectUsingIKEv2(forceProtocol: String? = nil) {
        if VPNManager.shared.userTappedToDisconnect && !VPNManager.shared.isFromProtocolFailover && !VPNManager.shared.isFromProtocolChange { return }
        self.setNewVPNConnection(forceProtocol: forceProtocol)
        DispatchQueue.global(qos: .background).async {
            IKEv2VPNManager.shared.configureWithSavedCredentials { (_, error) in
                if error == nil {
                    IKEv2VPNManager.shared.connect()
                }
            }
        }
    }

    func connectUsingOpenVPN(forceProtocol: String? = nil) {
        if VPNManager.shared.userTappedToDisconnect && !VPNManager.shared.isFromProtocolFailover && !VPNManager.shared.isFromProtocolChange { return }
        self.setNewVPNConnection(forceProtocol: forceProtocol)
        DispatchQueue.main.async {
            OpenVPNManager.shared.configureWithSavedCredentials { (_, error) in
                if error == nil {
                    OpenVPNManager.shared.connect()
                } else {
                    self.disconnectOrFail()
                    return
                }
            }
        }
    }

    func connectUsingCustomConfigOpenVPN() {
        if VPNManager.shared.userTappedToDisconnect && !VPNManager.shared.isFromProtocolFailover { return }
        DispatchQueue.global(qos: .background).async {
            OpenVPNManager.shared.configureWithCustomConfig { (_, error) in
                if error == nil {
                    OpenVPNManager.shared.connect()
                } else {
                    self.disconnectOrFail()
                    return
                }
            }
        }
    }

    func connectUsingWireGuard(forceProtocol: String? = nil, completion: @escaping (_ error: String?) -> Void) {
        if VPNManager.shared.userTappedToDisconnect && !VPNManager.shared.isFromProtocolFailover && !VPNManager.shared.isFromProtocolChange {
            return
        }
        VPNManager.shared.retryWithNewCredentials = false
        api.getSession().observe(on: MainScheduler.instance).subscribe(onSuccess: { session in
            if session.status == 1 {
                self.setNewVPNConnection(forceProtocol: forceProtocol)
                self.connectUsingDynamicWireGuard()
            } else {
                self.wgCrendentials.delete()
                WireGuardVPNManager.shared.disconnect()
            }
            completion(nil)
        }, onFailure: { error in
            if self.isFromProtocolFailover {
                completion(error.localizedDescription)
            } else {
                DispatchQueue.main.async {
                    VPNManager.shared.delegate?.setDisconnected()
                    AlertManager.shared.showSimpleAlert(title: "Error", message: "Unable to connect. Check your network connection.", buttonText: "Ok")
                }
            }
        }).disposed(by: disposeBag)
    }

    private func connectUsingDynamicWireGuard() {
        guard let hostname = VPNManager.shared.selectedNode?.hostname,
              let endpoint = VPNManager.shared.selectedNode?.ip3,
              let serverPublicKey = VPNManager.shared.selectedNode?.wgPublicKey else {
            self.logger.logE(VPNManager.self, "Missing WireGuard Info - Public Key: \(VPNManager.shared.selectedNode?.wgPublicKey ?? "nil") - WG IP \(VPNManager.shared.selectedNode?.ip3 ?? "nil")")
            VPNManager.shared.selectAnotherNode()
            serverRepository.getUpdatedServers().subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: disposeBag)
            return
        }
        let port = ConnectionManager.shared.getNextProtocol().portName
        wgCrendentials.setNodeToConnect(serverEndPoint: endpoint, serverHostName: hostname, serverPublicKey: serverPublicKey, port: port)
        wgRepository.getCredentials().subscribe(onCompleted: {
            DispatchQueue.global(qos: .background).async {
                WireGuardVPNManager.shared.configureWithSavedConfig { (_, error) in
                    if error == nil {
                        self.preferences.saveConnectingToCustomConfig(value: false)
                        WireGuardVPNManager.shared.connect()
                    } else {
                        self.logger.logE(VPNManager.self, "Error when trying to configure WireGuard VPN profile \(error ?? "")")
                    }
                }
            }
        },onError: { error in
            DispatchQueue.main.async {
                self.handleWgConnectionError(error: error)
            }
        }).disposed(by: disposeBag)
    }

    func handleWgConnectionError(error: Error) {
        if let error = error as? Errors {
            if error != Errors.handled {
                self.logger.logE(VPNManager.self, "Error when trying to configure WireGuard VPN profile \(error.description)")

                AlertManager.shared.showAlert(title: "",
                                              message: error.description,
                                              buttonText: TextsAsset.okay, actions: [])
            }
            delegate?.disconnectVpn()
        }
    }

    func connectUsingCustomConfigWireGuard() {
        if VPNManager.shared.userTappedToDisconnect { return }
        WireGuardVPNManager.shared.configureWithCustomConfig {  (_, error) in
            if error == nil {
                self.preferences.saveConnectingToCustomConfig(value: true)
                WireGuardVPNManager.shared.connect()
            }
        }
    }

    func connectUsingPreferredProtocol() {
        guard let selectedNode = VPNManager.shared.selectedNode else { return }
        guard let connectedWifiNetwork = WifiManager.shared.getConnectedNetwork() else { return }
        self.logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Preferred Protocol: Establishing VPN connection to  \(selectedNode.hostname) using \(connectedWifiNetwork.preferredProtocol) \(connectedWifiNetwork.preferredPort)")
        switch connectedWifiNetwork.preferredProtocol {
        case iKEv2:
            connectUsingIKEv2()
            return
        case udp, tcp, stealth, wsTunnel:
            connectUsingOpenVPN()
            return
        case wireGuard:
            connectUsingWireGuard { error in
                if error != nil {
                    self.logger.logE(VPNManager.self, "Failed to load vpn credentials.")
                    self.disconnectOrFail()
                    return
                }
            }
            return
        default:
            return
        }
    }

    func connectUsingAutomaticMode() {
        guard let selectedNode = selectedNode else { return }
        delegate?.setConnecting()
        self.keepConnectingState = true
        let nextProtocol = ConnectionManager.shared.getNextProtocol().protocolName
        self.logger.logD(VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Engaging Automatic Mode: Establishing VPN connection to  \(selectedNode.hostname) using \(nextProtocol)")
        switch nextProtocol {
        case iKEv2:
            self.connectUsingIKEv2()
        case wireGuard:
            connectUsingWireGuard(forceProtocol: wireGuard) { error in
                if error != nil {
                    self.disconnectOrFail()
                    return
                }
            }
        default:
            connectUsingOpenVPN(forceProtocol: udp)
        }
    }

    func checkLocationValidity() {
        guard let selectedNode = selectedNode else { return }
        let hostname = selectedNode.hostname
        let serverGroup = localDB.getServerAndGroup(bestNodeHostname: hostname)
        guard let serverGroup = serverGroup else { return }
        if !sessionManager.canAccesstoProLocation() && serverGroup.1.premiumOnly ?? false {
            logger.logD(self, "Will try to update to a valid group from the server list.")
            updateToValidLocation(from: serverGroup)
        }
    }

    private func updateToValidLocation(from serverGroup: (ServerModel, GroupModel)) {
        logger.logD(self, "Will try to update to a valid group from the server list.")
        if let group = serverGroup.0.groups?.filter({ serverGroup.1.id != $0.id }).first {
            let server = serverGroup.0
            guard let bestNode = group.bestNode,
                  let bestNodeHostname = bestNode.hostname,
                  let serverName = server.name,
                  let countryCode = server.countryCode,
                  let dnsHostname = server.dnsHostname,
                  let hostname = bestNode.hostname,
                  let serverAddress = bestNode.ip2,
                  let nickName = group.nick,
                  let cityName = group.city,
                  let groupId = group.id else { return }
            logger.logD(self, "Updated to another group in the same server \(serverName) \(bestNodeHostname).")
            selectedNode = SelectedNode(countryCode: countryCode,
                                                   dnsHostname: dnsHostname,
                                                   hostname: hostname,
                                                   serverAddress: serverAddress,
                                                   nickName: nickName,
                                                   cityName: cityName,
                                                   groupId: groupId)
        } else {
            localDB.getBestLocation().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: { bestLocation in
                guard let bestLocation = bestLocation else { return }
                self.logger.logD(self, "Updated to best location as there were no other groups available on the same server.")
                self.selectedNode = SelectedNode(countryCode: bestLocation.countryCode,
                                            dnsHostname: bestLocation.dnsHostname,
                                            hostname: bestLocation.hostname,
                                            serverAddress: bestLocation.ipAddress,
                                            nickName: bestLocation.nickName,
                                            cityName: bestLocation.cityName,
                                            groupId: bestLocation.groupId)
            }).disposed(by: disposeBag)
        }
    }
}
