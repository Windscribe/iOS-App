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

    @objc func restartWireGuardConnection() {
        if VPNManager.shared.userTappedToDisconnect || VPNManager.shared.isFromProtocolFailover || VPNManager.shared.isFromProtocolChange {
            return
        }
        Task {
            if (try? await self.vpnManagerUtils.configureWireguardWithSavedConfig(selectedNode: selectedNode,
                                                                                  userSettings: makeUserSettings())) ?? false {
                await vpnManagerUtils.connect(with: .wg, killSwitch: killSwitch)
            }
        }
    }

    @objc func restartIKEv2Connection() {
        connectUsingIKEv2()
    }

    @objc func restartOpenVPNConnection() {
        connectUsingOpenVPN()
    }

    @objc func restartCustomOpenVPNConnection() {
        connectUsingCustomConfigOpenVPN()
    }

    @objc func restartCustomWireGuardConnection() {
        connectUsingCustomConfigWireGuard()
    }

    @objc func retryIKEv2Connection() {
        Task { await vpnManagerUtils.connect(with: .iKEV2, killSwitch: killSwitch) }
    }

    @objc func retryOpenVPNConnection() {
        Task { await vpnManagerUtils.connect(with: .openVPN, killSwitch: killSwitch) }
    }

    @objc func retryWireGuardVPNConnection() {
        Task { await vpnManagerUtils.connect(with: .wg, killSwitch: killSwitch) }
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
        
        vpnManagerUtils.invalidateTimer()
        if self.selectedConnectionMode == Fields.Values.auto {
            self.resetProperties()
        }
        if setDisconnect { self.delegate?.setDisconnected() }
        if disableConnectIntent { VPNManager.shared.connectIntent = false }

        Task {
            for manager in vpnManagerUtils.managers {
                if manager.protocolConfiguration?.username != nil {
                    await vpnManagerUtils.disconnect(killSwitch: killSwitch, manager: manager)
                }
            }
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

            Task {
                for manager in vpnManagerUtils.managers {
                    if manager.protocolConfiguration?.username != nil {
                        await vpnManagerUtils.disconnect(killSwitch: killSwitch, manager: manager)
                    }
                }
                completion()
            }
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
        Task {
            await vpnManagerUtils.reset(manager: vpnManagerUtils.wireguardManager())
            comletion()
        }
    }

    func resetOpenVPN(comletion: @escaping () -> Void) {
        Task {
            await vpnManagerUtils.reset(manager: vpnManagerUtils.openVPNdManager())
            comletion()
        }
    }

    func resetIkev2(comletion: @escaping () -> Void) {
        Task {
            await vpnManagerUtils.reset(manager: vpnManagerUtils.iKEV2Manager())
            comletion()
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
        for manager in vpnManagerUtils.managers {
            if manager.connection.status == .connected || manager.connection.status == .connecting {
                Task {
                    await vpnManagerUtils.disconnect(killSwitch: killSwitch, manager: manager)
                }
            }
        }
    }

    @objc func disconnectIfStillConnecting() {
        for manager in vpnManagerUtils.managers {
            if manager.connection.status == .connecting && manager.connection.status != .disconnected {
                disableOrFailOnDisconnect = true
                isOnDemandRetry = false
                Task {
                    await vpnManagerUtils.disconnect(killSwitch: killSwitch, manager: manager)
                    logger.logE( VPNManager.self, "[\(uniqueConnectionId)] Connecting timeout for \(vpnManagerUtils.getManagerName(from: manager)) connection.")
                }
            }
        }
    }

    @objc func removeVPNProfileIfStillDisconnecting() {
        getVPNConnectionInfo { info in
            guard let info = info else {
                return
            }
            if info.killSwitch || info.onDemand {
                self.logger.logI( VPNManager.self, "Kill-Switch/Firewall on unable to remove VPN Profile.")
                return
            }

            for manager in self.vpnManagerUtils.managers {
                if manager.connection.status == .disconnecting {
                    self.isOnDemandRetry = false
                    Task {
                        await self.vpnManagerUtils.disconnect(killSwitch: self.killSwitch, manager: manager)
                        await self.vpnManagerUtils.removeProfile(killSwitch: self.killSwitch, manager: manager)
                        self.logger.logE( VPNManager.self, "Disconnecting timeout. Removing \(self.vpnManagerUtils.getManagerName(from: manager)) VPN profile.")
                    }
                }
            }
        }
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
