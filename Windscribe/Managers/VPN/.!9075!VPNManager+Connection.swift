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
import WidgetKit

extension VPNManager {
    func selectAnotherNode() {
        if let selectedNode = VPNManager.shared.selectedNode,
           let dnsHostname = selectedNode.dnsHostname,
           let hostname = selectedNode.hostname,
           let countryCode = selectedNode.countryCode,
           let nickName = selectedNode.nickName,
           let cityName = selectedNode.cityName,
           let groupId = selectedNode.groupId {
            if let randomNode = PersistenceManager.shared.getRandomNodeInSameGroup(groupId: groupId,
                                                                                   excludeHostname: hostname),
               let newHostname = randomNode.hostname,
               let newIP2 = randomNode.ip2 {
                VPNManager.shared.selectedNode = SelectedNode(countryCode: countryCode,
                                                              dnsHostname: dnsHostname,
                                                              hostname: newHostname,
                                                              serverAddress: newIP2,
                                                              nickName: nickName,
                                                              cityName: cityName,
                                                              groupId: groupId)
            }
        }
    }

    func connectToAnotherNode(forceProtocol: String? = nil) {
        selectAnotherNode()
        connectUsingAutomaticMode(forceProtocol: forceProtocol)
        LogManager.shared.log(activity: String(describing: VPNManager.self),
                              text: "Establishing a new connection with a random node in the same group.",
                              type: .debug)
    }

    /// Saves Connection Params before connecting.
    /// Sets default protocol and port
    /// if connection mode is manual sets selected protocol and port
    /// if wifi network name is available and prefered protcol is turned on use prefered protocol and port.
    func setNewVPNConnection() {
        var selectedProtocol = iKEv2
        var selectedPort = "500"
        let preferences = PersistenceManager.shared.retrieve(type: UserPreferences.self)?.first
        if let preferences = preferences {
            if preferences.connectionMode == Fields.Values.manual {
                selectedProtocol = preferences.protocolType
                selectedPort = preferences.port
            }
        }
        if let connectedWifi = WifiManager.shared.connectedWifi {
            if connectedWifi.preferredProtocolStatus == true {
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
        PersistenceManager.shared.saveAndUpdate(object: vpnConnection)
    }

    func connectUsingIKEv2(forceProtocol: String? = nil) {
        if VPNManager.shared.userTappedToDisconnect { return }
        self.setNewVPNConnection()
        IKEv2VPNManager.shared.configureWithSavedCredentials { [weak self] (_, error) in
            if error == nil {
                self?.connect(forceProtocol: forceProtocol)
            }
        }
    }

    func connectUsingOpenVPN(forceProtocol: String? = nil) {
        if VPNManager.shared.userTappedToDisconnect { return }
        self.setNewVPNConnection()
        OpenVPNManager.shared.configureWithSavedCredentials { [weak self] (_, error) in
            if error == nil {
                self?.connect(forceProtocol: forceProtocol)
            }
        }
    }

    func connectUsingCustomConfigOpenVPN() {
        if VPNManager.shared.userTappedToDisconnect { return }
        OpenVPNManager.shared.configureWithCustomConfig { [weak self] (_, error) in
            if error == nil {
                self?.connect()
            }
        }
    }

    func connectUsingWireGuard() {
        if VPNManager.shared.userTappedToDisconnect {
            return
        }
        VPNManager.shared.retryWithNewCredentials = false
        if #available(iOS 12.0, *) {
            WireguardNetworkManager.shared.getSession { [weak self] result, error, _ in
                if result != nil {
                    if result?.status == 1 {
                        self?.setNewVPNConnection()
                        self?.connectUsingDynamicWireGuard()
                    } else {
                        WgCredentials.shared.delete()
                        WireGuardVPNManager.shared.disconnect()
                    }
                } else {
                    DispatchQueue.main.async {
                        VPNManager.shared.delegate?.setDisconnected()
                        AlertManager.shared.showSimpleAlert(title: "Error", message: error ?? "Unable to connect. Check your network connection.", buttonText: "Ok")
                    }
                }
            }
        }
    }

    private func getSelectedPort() -> String? {
        guard let connectedWifi = WifiManager.shared.connectedWifi else {
            LogManager.shared.log(
                activity: String(describing: WireGuardConfigManager.self),
                text: "Error when trying to get connected wifi",
                type: .error
            )
            return nil
        }
        var port = connectedWifi.port
        if connectedWifi.preferredProtocolStatus && VPNManager.shared.selectedNode?.customConfig == nil {
            port = connectedWifi.preferredPort
        } else if UserPreferencesManager.shared.selectedConnectionMode == Fields.Values.manual {
            port = UserPreferencesManager.shared.selectedPort ?? "443"
        }
        return port
    }

    @available(iOS 12.0, *)
    private func connectUsingDynamicWireGuard() {
        guard let hostname = VPNManager.shared.selectedNode?.hostname,
              let endpoint = VPNManager.shared.selectedNode?.ip3,
              let port = getSelectedPort(),
              let serverPublicKey = VPNManager.shared.selectedNode?.wgPublicKey else {
                  LogManager.shared.log(
                    activity: String(describing: VPNManager.self),
                    text: "Missing WireGuard Info - Public Key: \(VPNManager.shared.selectedNode?.wgPublicKey ?? "nil") - WG IP \(VPNManager.shared.selectedNode?.ip3 ?? "nil")",
                    type: .error
                  )
                  VPNManager.shared.selectAnotherNode()
                  NetworkManager.shared.getServers(completion: {_,_ in })
                  return
              }

        WgCredentials.shared.setNodeToConnect(serverEndPoint: endpoint, serverHostName: hostname, serverPublicKey: serverPublicKey, port: port)
        WireGuardConfigManager.shared.requestWgCredentials { [weak self] success , code ,errorMessage  in
            BaseLogger.instace.log(text: "Wireguard::: \(success) \(code) \(errorMessage)")
            if success {
                WireGuardVPNManager.shared.configureWithSavedConfig { [weak self] (_, error) in
                    if error == nil {
                        SharedSecretDeafults.shared.setBool(false, forKey: SharedKeys.isCustomConfigSelected)
                        self?.connect()
                    } else {
                        LogManager.shared.log(activity: String(describing: VPNManager.self),
                                              text: "Error when trying to configure WireGuard VPN profile \(error ?? "")",
                                              type: .error)
                    }
                }
            } else {
                if errorMessage != nil {
                    DispatchQueue.main.async {
                        self?.handleWgConnectionError(errorMessage: errorMessage)
                    }
                }
            }
        }
    }

    @available(iOS 12.0, *)
    func handleWgConnectionError(errorMessage: String?) {
        if let errorMessage = errorMessage {
            LogManager.shared.log(activity: String(describing: VPNManager.self),
                                  text: "Error when trying to configure WireGuard VPN profile \(errorMessage)", type: .error)
            let okAction = UIAlertAction(title: TextsAsset.okay,style: .destructive) { _ in}
            AlertManager.shared.showAlert(title: "",
                                          message: errorMessage,
                                          buttonText: TextsAsset.cancel, actions: [okAction])
        }
    }

    func connectUsingCustomConfigWireGuard() {
        if VPNManager.shared.userTappedToDisconnect { return }
        WireGuardVPNManager.shared.configureWithCustomConfig { [weak self] (_, error) in
            if error == nil {
                SharedSecretDeafults.shared.setBool(true, forKey: SharedKeys.isCustomConfigSelected)
                self?.connect()
            }
        }
    }

    func connect(forceProtocol: String? = nil) {
        guard ReachabilityManager.shared.internetConnectionAvailable() ||
                VPNManager.shared.userTappedToDisconnect == true else { return }
        if self.isCustomConfigSelected() {
            if  VPNManager.shared.selectedNode?.customConfig?.protocolType == TextsAsset.wireGuard { WireGuardVPNManager.shared.connect() } else { OpenVPNManager.shared.connect() }
        } else {
            var protocolType = WifiManager.shared.connectedWifi?.protocolType
            if WifiManager.shared.connectedWifi?.preferredProtocolStatus ?? false {
                protocolType = WifiManager.shared.connectedWifi?.preferredProtocol
            } else if UserPreferencesManager.shared.selectedConnectionMode == Fields.Values.manual {
                protocolType = UserPreferencesManager.shared.selectedProtocol
            }
            if forceProtocol != nil {
                protocolType = forceProtocol
            }
            switch protocolType {
            case iKEv2:
                IKEv2VPNManager.shared.connect()
            case udp, tcp, stealth, wsTunnel:
                OpenVPNManager.shared.connect()
            case wireGuard:
                WireGuardVPNManager.shared.connect()
            default:
                return
            }
        }
    }

    func connectUsingPreferredProtocol() {
        guard let selectedNode = VPNManager.shared.selectedNode,
              let hostname = selectedNode.hostname else { return }
        guard let connectedWifiNetwork = WifiManager.shared.connectedWifi else { return }
        LogManager.shared.log(activity: String(describing: VPNManager.self),
                              text: "[\(VPNManager.shared.uniqueConnectionId)] Preferred Protocol: Establishing VPN connection to  \(hostname) using \(connectedWifiNetwork.preferredProtocol) \(connectedWifiNetwork.preferredPort)",
                              type: .debug)
        switch connectedWifiNetwork.preferredProtocol {
        case iKEv2:
            connectUsingIKEv2()
            return
        case udp, tcp, stealth, wsTunnel:
            connectUsingOpenVPN()
            return
        case wireGuard:
            connectUsingWireGuard()
            return
        default:
            return
        }
    }

    func connectUsingAutomaticMode(forceProtocol: String? = nil) {
        guard let selectedNode = VPNManager.shared.selectedNode, let hostname = selectedNode.hostname else { return }
        self.keepConnectingState = true
        guard let automaticMode = UserPreferencesManager.shared.getAutomaticMode() else { return }
        var nextProtocol = UserPreferencesManager.shared.getNextProtocol()
        if let forceProtocol = forc
