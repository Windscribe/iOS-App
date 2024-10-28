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
        var selectedProtocol = forceProtocol ?? wireGuard
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
        api.getSession(nil).observe(on: MainScheduler.instance).subscribe(onSuccess: { session in
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
        Task {
            try await vpnManagerUtils.configureWireguard(with: selectedNode,
                                                         userSettings: makeUserSettings())
        }
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
        guard let currentLocation = getCurrentLocation() else {
            self.logger.logD(self, "Unable to find \(selectedNode.cityName). Switching to Sister location.")
            if let sisterLocation = getSisterLocation() {
                logger.logD(self, "Switching to \(sisterLocation.1.city ?? "").")
                switchLocation(from: sisterLocation)
            } else {
                self.logger.logD(self, "Unable to find sister location. Switching to Best location.")
                switchLocation(from: nil)
            }
            return
        }
        if !sessionManager.canAccesstoProLocation() && currentLocation.1.premiumOnly ?? false {
            switchLocation(from: nil)
        }
    }

    private func getCurrentLocation() -> (ServerModel, GroupModel)? {
        guard let selectedNode = selectedNode else { return nil }
        let hostname = selectedNode.hostname
        return localDB.getServerAndGroup(bestNodeHostname: hostname)
    }

    private func getSisterLocation() -> (ServerModel, GroupModel)? {
        guard let servers = localDB.getServers() else { return nil }
        var serverResult: ServerModel?
        var groupResult: GroupModel?
        for server in servers.map({$0.getServerModel()}) {
            for group in server?.groups ?? [] where group.id == selectedNode?.groupId {
                serverResult = server
                groupResult = server?.groups?.filter {$0.isNodesAvailable()}.randomElement()
            }
        }
        guard let serverResultSafe = serverResult, let groupResultSafe = groupResult else { return nil }
        return (serverResultSafe, groupResultSafe)
    }

    private func switchLocation(from serverGroup: (ServerModel, GroupModel)?) {
        if let serverGroup = serverGroup {
            guard let bestNode = serverGroup.1.bestNode,
                  let countryCode = serverGroup.0.countryCode,
                  let dnsHostname = serverGroup.0.dnsHostname,
                  let hostname = bestNode.hostname,
                  let serverAddress = bestNode.ip2,
                  let nickName = serverGroup.1.nick,
                  let cityName = serverGroup.1.city,
                  let groupId = serverGroup.1.id else { return }
            selectedNode = SelectedNode(countryCode: countryCode,
                                                   dnsHostname: dnsHostname,
                                                   hostname: hostname,
                                                   serverAddress: serverAddress,
                                                   nickName: nickName,
                                                   cityName: cityName,
                                                   groupId: groupId)
            self.connect()
        } else {
            localDB.getBestLocation().take(1).subscribe(on: MainScheduler.instance).subscribe(onNext: { bestLocation in
                guard let bestLocation = bestLocation else { return }
                self.selectedNode = SelectedNode(countryCode: bestLocation.countryCode,
                                            dnsHostname: bestLocation.dnsHostname,
                                            hostname: bestLocation.hostname,
                                            serverAddress: bestLocation.ipAddress,
                                            nickName: bestLocation.nickName,
                                            cityName: bestLocation.cityName,
                                            groupId: bestLocation.groupId)
                self.connect()
            }).disposed(by: disposeBag)
        }
    }

    private func connect() {
        if VPNManager.shared.isConnected() {
            self.connectIntent = false
            resetProfiles {
                self.connectIntent = true
                self.userTappedToDisconnect = false
                self.restartOnDisconnect = false
                self.isOnDemandRetry = false
                self.logger.logD(self, "Connecting to new location.")
                self.configureAndConnectVPN()
                self.switchingLocation = false
            }
        } else {
            switchingLocation = false
        }
    }
}
