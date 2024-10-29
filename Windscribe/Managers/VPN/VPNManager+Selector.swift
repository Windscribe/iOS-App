//
//  VPNManager+Selector.swift
//  Windscribe
//
//  Created by Thomas on 17/11/2021.
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
    @objc func configureAndConnectVPN() {
        guard let selectedNode = VPNManager.shared.selectedNode else {
            return
        }
        VPNManager.shared.uniqueConnectionId = UUID().uuidString

        if let customConfig = VPNManager.shared.selectedNode?.customConfig {
            logger.logD( VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Custom Config Mode: Establishing VPN connection to  \(selectedNode.hostname) \(selectedNode.serverAddress) using \(customConfig.protocolType ?? "") \(customConfig.port ?? "")")
            if customConfig.protocolType == TextsAsset.wireGuard {
                connectUsingCustomConfigWireGuard()
            } else {
                connectUsingCustomConfigOpenVPN()
            }
        } else {
            ConnectionManager.shared.loadProtocols(shouldReset: true) { [self] _ in
                switch ConnectionManager.shared.getNextProtocol().protocolName {
                case iKEv2:
                    connectUsingIKEv2()
                case wireGuard:
                    connectUsingWireGuard { _ in }
                default:
                    connectUsingOpenVPN()
                }
            }
        }
    }

    @objc func hideAskToRetryPopup() {
        displayingAskToRetryPopup?.dismiss(animated: true, completion: nil)
        connectUsingAutomaticMode()
    }

    @objc func retryWithAutomaticMode(protocolType: String?) {
        retryInProgress = false
        connectUsingAutomaticMode()
    }

    @objc func retryConnection() {
        logger.logD( VPNManager.self, "Retrying connection")
        if VPNManager.shared.userTappedToDisconnect { return }
        if self.isCustomConfigSelected() {
            if selectedNode?.customConfig?.protocolType == TextsAsset.wireGuard { restartCustomWireGuardConnection() } else { restartCustomOpenVPNConnection() }
        } else {
            let proto = ConnectionManager.shared.getNextProtocol()
            switch proto.protocolName {
            case iKEv2:
                self.restartIKEv2Connection()
            case wireGuard:
                self.restartWireGuardConnection()
            default:
                self.restartOpenVPNConnection()
            }
        }
    }

    @objc func restartIKEv2Connection() {
        if VPNManager.shared.userTappedToDisconnect || VPNManager.shared.isFromProtocolFailover || VPNManager.shared.isFromProtocolChange {
            return
        }
        Task {
            if (try? await self.vpnManagerUtils.configureIKEV2WithSavedCredentials(with: selectedNode,
                                                                                   userSettings: makeUserSettings())) ?? false {
                IKEv2VPNManager.shared.connect()
            }
        }
    }

    @objc func restartOpenVPNConnection() {
        if VPNManager.shared.userTappedToDisconnect {
            return
        }
        Task {
            if (try? await self.vpnManagerUtils.configureOpenVPNWithSavedCredentials(with: selectedNode,
                                                                                     userSettings: makeUserSettings())) ?? false {
                OpenVPNManager.shared.connect()
            }
        }
    }

    @objc func restartWireGuardConnection() {
        if VPNManager.shared.userTappedToDisconnect || VPNManager.shared.isFromProtocolFailover || VPNManager.shared.isFromProtocolChange {
            return
        }
        Task {
            if (try? await self.vpnManagerUtils.configureWireguardWithSavedConfig(selectedNode: selectedNode,
                                                                                  userSettings: makeUserSettings())) ?? false {
                WireGuardVPNManager.shared.connect()
            }
        }
    }

    @objc func restartCustomOpenVPNConnection() {
        connectUsingCustomConfigOpenVPN()
    }

    @objc func restartCustomWireGuardConnection() {
        if VPNManager.shared.userTappedToDisconnect { return }
        Task {
            if (try? await self.vpnManagerUtils.configureWireguardWithCustomConfig(selectedNode: selectedNode,
                                                                                  userSettings: makeUserSettings())) ?? false {
                WireGuardVPNManager.shared.connect()
            }
        }
    }

    @objc func retryIKEv2Connection() {
        IKEv2VPNManager.shared.connect()
    }

    @objc func retryOpenVPNConnection() {
        OpenVPNManager.shared.connect()
    }

    @objc func retryWireGuardVPNConnection() {
        WireGuardVPNManager.shared.connect()
    }

    @objc func retryConnectionWithNewServerCredentials() {
        if userTappedToDisconnect || self.isCustomConfigSelected() { return }
        logger.logD(self, "Disconnecting from VPN after first attempt.")
        let protocolType = ConnectionManager.shared.getNextProtocol().protocolName
        let isStatic = self.selectedNode?.staticIPCredentials != nil
        self.retryWithNewCredentials = false
        resetProfiles()
            .andThen(selectAnotherNode())
            .andThen(self.updateCredentials(protocolType: protocolType, isStatic: isStatic))
            .subscribe(on: MainScheduler.instance)
            .subscribe(onCompleted: {
                switch protocolType {
                case iKEv2:
                    self.restartIKEv2Connection()
                case udp, tcp, stealth, wsTunnel:
                    self.restartOpenVPNConnection()
                default:
                    self.connectUsingWireGuard { [weak self] error in
                        if error != nil {
                            self?.disconnectOrFail()
                        }
                    }
                }
            }, onError: { _ in
                self.delegate?.setDisconnected()
                self.disconnectOrFail()
            }).disposed(by: disposeBag)
    }

    private func updateCredentials(protocolType: String, isStatic: Bool) -> Completable {
        Single.just(protocolType).flatMap { (proto: String) -> Single<Bool> in
            if isStatic {
                return self.staticIpRepository.getStaticServers().flatMap { newStaticIPCredentials in
                    self.selectedNode?.staticIPCredentials = newStaticIPCredentials.first?.credentials.first?.getModel()
                    return Single.just(true)
                }
            } else if proto == iKEv2 {
                return self.credentialsRepository.getUpdatedIKEv2Crendentials().flatMap { _ in Single.just(true) }
            } else if proto == udp || proto == tcp || proto == stealth || proto == wsTunnel {
                return self.credentialsRepository.getUpdatedOpenVPNCrendentials().flatMap { _ in Single.just(true) }
            } else {
                return Single.just(true)
            }
        }.asCompletable()
    }

    private func selectAnotherNode() -> Completable {
        return Completable.create { completion in
            guard let selectedNode = self.selectedNode else {
                completion(.error(ManagerErrors.nonodeselected))
                return Disposables.create {}
            }
            guard let randomNode = self.getRandomNodeInSameGroup(groupId: selectedNode.groupId, excludeHostname: selectedNode.hostname) else {
                completion(.error(ManagerErrors.norandomnodefound))
                return Disposables.create {}
            }
            if let newHostname = randomNode.hostname, let newIP2 = randomNode.ip2 {
                self.selectedNode = SelectedNode(countryCode: selectedNode.countryCode,
                                                 dnsHostname: selectedNode.dnsHostname,
                                                 hostname: newHostname,
                                                 serverAddress: newIP2,
                                                 nickName: selectedNode.nickName,
                                                 cityName: selectedNode.cityName,
                                                 groupId: selectedNode.groupId)
                completion(.completed)
            } else {
                completion(.error(ManagerErrors.missingipinnode))
            }
            return Disposables.create {}
        }
    }

    private func resetProfiles() -> Completable {
        return Completable.create { completable in
            self.resetWireguard {
                self.resetOpenVPN {
                    self.resetIkev2 {
                        completable(.completed)
                    }
                }
            }
            return Disposables.create {}
        }
    }

    @objc func disconnectActiveVPNConnection(setDisconnect: Bool = false, disableConnectIntent: Bool = false) {
        logger.logD( VPNManager.self, "[\(uniqueConnectionId)] [\(self.selectedConnectionMode ?? "")] Disconnecting Active VPN connection")

        IKEv2VPNManager.shared.noResponseTimer?.invalidate()
        if self.selectedConnectionMode == Fields.Values.auto {
            self.resetProperties()
        }
        if setDisconnect { self.delegate?.setDisconnected() }
        if disableConnectIntent { VPNManager.shared.connectIntent = false }
        if IKEv2VPNManager.shared.isConfigured() {
            IKEv2VPNManager.shared.disconnect()
        }
        if OpenVPNManager.shared.isConfigured() {
            OpenVPNManager.shared.disconnect()
        }
        if WireGuardVPNManager.shared.isConfigured() {
            WireGuardVPNManager.shared.disconnect()
        }
    }

    func disconnectIfRequired(completion: @escaping () -> Void) {
        if self.selectedConnectionMode == Fields.Values.auto {
            self.resetProperties()
        }
        if isConnected() || isConnecting() {
            logger.logD( VPNManager.self, "Reconnecting...")
            self.keepConnectingState = true
            self.delegate?.setConnecting()
            if IKEv2VPNManager.shared.isConfigured() {
                IKEv2VPNManager.shared.disconnect()
            }
            if OpenVPNManager.shared.isConfigured() {
                OpenVPNManager.shared.disconnect()
            }
            if WireGuardVPNManager.shared.isConfigured() {
                WireGuardVPNManager.shared.disconnect()
            }
            completion()
        } else {
            logger.logD( VPNManager.self, "Connecting...")
            completion()
        }
    }

    @objc func disconnectAllVPNConnections(setDisconnect: Bool = false, force: Bool = false) {
        resetProfiles {
            if setDisconnect {
                self.delegate?.setDisconnected()
            }
        }
    }

    func resetWireguard(comletion: @escaping () -> Void) {
        WireGuardVPNManager.shared.setup {
            if WireGuardVPNManager.shared.providerManager?.protocolConfiguration?.username == TextsAsset.wireGuard {
                WireGuardVPNManager.shared.providerManager?.isOnDemandEnabled = false
                WireGuardVPNManager.shared.providerManager?.isEnabled = false
#if os(iOS)

                if #available(iOS 14.0, *) {
                    WireGuardVPNManager.shared.providerManager?.protocolConfiguration?.includeAllNetworks = false
                }
#endif
                WireGuardVPNManager.shared.providerManager?.saveToPreferences { error in
                    if error == nil {
                        WireGuardVPNManager.shared.providerManager?.loadFromPreferences { error in
                            if error != nil {
                                delay(2, completion: comletion)
                                return
                            }
                            if WireGuardVPNManager.shared.isConnected() || WireGuardVPNManager.shared.isConnecting() {
                                WireGuardVPNManager.shared.providerManager?.connection.stopVPNTunnel()
                                delay(2, completion: comletion)
                            } else {
                                comletion()
                            }
                        }
                    } else {
                        comletion()
                    }
                }
            } else {
                comletion()
            }
        }
    }

    func resetOpenVPN(comletion: @escaping () -> Void) {
        OpenVPNManager.shared.setup {
            if OpenVPNManager.shared.providerManager?.protocolConfiguration?.username == TextsAsset.openVPN {
                OpenVPNManager.shared.providerManager?.isOnDemandEnabled = false
                OpenVPNManager.shared.providerManager?.isEnabled = false
#if os(iOS)

                if #available(iOS 14.0, *) {
                    OpenVPNManager.shared.providerManager?.protocolConfiguration?.includeAllNetworks = false
                }
#endif
                OpenVPNManager.shared.providerManager?.saveToPreferences { error in
                    if error == nil {
                        OpenVPNManager.shared.providerManager?.loadFromPreferences { _ in
                            if OpenVPNManager.shared.isConnected() || OpenVPNManager.shared.isConnecting() {
                                OpenVPNManager.shared.providerManager?.connection.stopVPNTunnel()
                                delay(1, completion: comletion)
                            } else {
                                comletion()
                            }
                        }
                    } else {
                        comletion()
                    }
                }
            } else {
                comletion()
            }
        }
    }

    func resetIkev2(comletion: @escaping () -> Void) {
        IKEv2VPNManager.shared.neVPNManager.loadFromPreferences {  error in
            if error == nil {
                IKEv2VPNManager.shared.neVPNManager.isOnDemandEnabled = false
                IKEv2VPNManager.shared.neVPNManager.isEnabled = false
#if os(iOS)
                if #available(iOS 14.0, *) {
                    IKEv2VPNManager.shared.neVPNManager.protocolConfiguration?.includeAllNetworks = false
                }
#endif
                IKEv2VPNManager.shared.neVPNManager.saveToPreferences { error in
                    if error == nil {
                        IKEv2VPNManager.shared.neVPNManager.loadFromPreferences { _ in
                            if IKEv2VPNManager.shared.isConnecting() || IKEv2VPNManager.shared.isConnected() {
                                IKEv2VPNManager.shared.neVPNManager.connection.stopVPNTunnel()
                                delay(1, completion: comletion)
                            } else {
                                comletion()
                            }
                        }
                    } else {
                        comletion()
                    }
                }
            } else {
                comletion()
            }
        }
    }

    func resetProfiles(comletion: @escaping () -> Void) {
        resetWireguard {
            self.resetOpenVPN {
                self.resetIkev2 {
                    comletion()
                }
            }
        }
    }

    @objc func disconnectAndDisable() {
        self.disableOrFailOnDisconnect = true
        if IKEv2VPNManager.shared.neVPNManager.connection.status == .connected ||
            IKEv2VPNManager.shared.neVPNManager.connection.status == .connecting {
            IKEv2VPNManager.shared.disconnect()
        }
        if OpenVPNManager.shared.providerManager?.connection.status == .connected || OpenVPNManager.shared.providerManager?.connection.status == .connecting {
            OpenVPNManager.shared.disconnect()
        }
        if WireGuardVPNManager.shared.providerManager?.connection.status == .connected || WireGuardVPNManager.shared.providerManager?.connection.status == .connecting {
            WireGuardVPNManager.shared.disconnect()
        }
    }

    @objc func disconnectIfStillConnecting() {
        if IKEv2VPNManager.shared.neVPNManager.connection.status == .connecting &&
            IKEv2VPNManager.shared.neVPNManager.connection.status != .disconnected {
            self.disableOrFailOnDisconnect = true
            VPNManager.shared.isOnDemandRetry = false
            IKEv2VPNManager.shared.disconnect()
            logger.logE( VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Connecting timeout for IKEv2 connection.")
        }
        if OpenVPNManager.shared.providerManager?.connection.status == .connecting && OpenVPNManager.shared.providerManager?.connection.status != .disconnected {
            self.disableOrFailOnDisconnect = true
            VPNManager.shared.isOnDemandRetry = false
            OpenVPNManager.shared.disconnect()
            logger.logE( VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Connecting timeout for OpenVPN connection.")

        }
        if WireGuardVPNManager.shared.providerManager?.connection.status == .connecting && WireGuardVPNManager.shared.providerManager?.connection.status != .disconnected {
            self.disableOrFailOnDisconnect = true
            VPNManager.shared.isOnDemandRetry = false
            WireGuardVPNManager.shared.disconnect()
            logger.logE( VPNManager.self, "[\(VPNManager.shared.uniqueConnectionId)] Connecting timeout for WireGuard connection.")
        }
    }

    @objc func removeVPNProfileIfStillDisconnecting() {
        getVPNConnectionInfo(completion: { info in
            guard let info = info else {
                return
            }
            if info.killSwitch || info.onDemand {
                self.logger.logI( VPNManager.self, "Kill-Switch/Firewall on unable to remove VPN Profile.")
                return
            }
            if IKEv2VPNManager.shared.neVPNManager.connection.status == .disconnecting {
                VPNManager.shared.isOnDemandRetry = false
                IKEv2VPNManager.shared.removeProfile { _,_ in }
                self.logger.logE( VPNManager.self, "Disconnecting timeout. Removing IKEv2 VPN profile.")
            }
            if OpenVPNManager.shared.providerManager?.connection.status == .disconnecting {
                VPNManager.shared.isOnDemandRetry = false
                OpenVPNManager.shared.removeProfile { _,_ in }
                self.logger.logE( VPNManager.self, "Disconnecting timeout. Removing OpenVPN VPN profile.")
            }
            if WireGuardVPNManager.shared.providerManager?.connection.status == .disconnecting {
                VPNManager.shared.isOnDemandRetry = false
                WireGuardVPNManager.shared.removeProfile { _,_ in }
                self.logger.logE( VPNManager.self, "Disconnecting timeout. Removing WireGuard VPN profile.")
            }

        })
    }

    @objc func runConnectivityTestWithNoRetry() {
        runConnectivityTest(retry: false,
                            connectToAnotherNode: false)
    }

    @objc func runConnectivityTestWithRetry() {
        runConnectivityTest(retry: true,
                            connectToAnotherNode: false)
    }

    @objc func increaseFailCountsOrRetry() {

    }

    // function to check if local ip belongs to RFC 1918 ips
    func checkLocalIPIsRFC() -> Bool {
        if let localIPAddress = NWInterface.InterfaceType.wifi.ipv4 {
            if localIPAddress.isRFC1918IPAddress {
                self.logger.logD( VPNManager.self, "It's an RFC1918 address. \(localIPAddress)")
                return true
            } else {
                self.logger.logD( VPNManager.self, "Non Rfc-1918 address found  \(localIPAddress)")
                return false
            }
        } else {
            self.logger.logD( VPNManager.self, "Failed to retrieve local IP address.")
            return true
        }
    }
}
