//
//  VPNManager+Connect.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import NetworkExtension
import Swinject
/// Sample to test everything.
extension VPNManager: VPNConnectionAlertDelegate {
    private func connectTask() {
        Task { @MainActor in
            var id = "\(selectedNode?.groupId ?? 0)"
            connectionAlert.updateProgress(message: "Please select protocol and connect")
            var port = "443"
            if selectedProtocol == TextsAsset.iKEv2 {
                port = "500"
            }
            if selectedNode?.staticIPCredentials != nil {
                let ipId = localDB.getStaticIPs()?.first { $0.connectIP == selectedNode?.staticIpToConnect }?.ipId ?? 0
                id = "static_\(ipId)"
            }
            if let customId = selectedNode?.customConfig?.id {
                id = "custom_\(customId)"
                selectedProtocol = configManager.getProtoFromConfig(locationId: customId) ?? TextsAsset.wireGuard
            }
            cancellable = configManager.connectAsync(locationID: id, proto: selectedProtocol, port: port, vpnSettings: makeUserSettings())
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    self.connectionAlert.dismissAlert()
                    switch completion {
                    case .finished:
                        self.logger.logD("VPNConfiguration", "Connection process completed.")
                    case .failure:
                        self.delegate?.setDisconnected()
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        self.logger.logD("VPNConfiguration", message)
                        self.connectionAlert.updateProgress(message: message)
                    case let .validated(ip):
                        self.delegate?.setConnected(ipAddress: ip)
                    default: ()
                    }
                })
        }
    }

    private func disconnectTask() {
        delegate?.setDisconnecting()
        cancellable = configManager.disconnectAsync()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { completion in
                self.disconnectAlert.dismissAlert()
                self.delegate?.setDisconnected()
                switch completion {
                case .finished:
                    self.logger.logD("VPNConfiguration", "Disconnect process completed.")
                    self.disconnectAlert.dismissAlert()
                case let .failure(error):
                    self.disconnectAlert.dismissAlert()
                    if let e = error as? VPNConfigurationErrors {
                        self.logger.logD("VPNConfiguration", "Failed to disconnect with error: \(e.errorDescription)")
                    }
                }
            }, receiveValue: { state in
                switch state {
                case let .update(message):
                    self.disconnectAlert.updateProgress(message: message)
                case let .vpn(status):
                    if status == NEVPNStatus.connected {
                        self.disconnectAlert.dismissAlert()
                    }
                default: ()
                }
            })
    }

    func disconnectNow() {
        DispatchQueue.main.async {
            self.disconnectAlert.delegate = self
            self.disconnectAlert.configure(for: .disconnect)
            self.disconnectAlert.updateProgress(message: "")
            if let topController = UIApplication.shared.keyWindow?.rootViewController {
                topController.present(self.disconnectAlert, animated: true, completion: nil)
            }
        }
        disconnectTask()
    }

    func connectNow() {
        DispatchQueue.main.async {
            self.connectionAlert.delegate = self
            self.connectionAlert.configure(for: .connect)
            self.connectionAlert.updateProgress(message: "")
            if let topController = UIApplication.shared.keyWindow?.rootViewController {
                topController.present(self.connectionAlert, animated: true, completion: nil)
            }
        }
    }

    func didSelectProtocol(_ protocolName: String) {
        selectedProtocol = protocolName
        connectTask()
    }

    func didTapDisconnect() {
        disconnectNow()
    }
}
