//
//  VPNManager+Connect.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import NetworkExtension
import Swinject
/// Sample to test everything.
extension VPNManager: VPNConnectionAlertDelegate {
    private func connectTask() {
        Task { @MainActor in
           // var id = "\(selectedNode?.groupId ?? 0)"
            var id = "9000"
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
            cancellable = connectWithInitialRetry(id: id, proto: selectedProtocol, port: port)
                .receive(on: DispatchQueue.main)
                .sink(receiveCompletion: { completion in
                    self.connectionAlert.dismissAlert()
                    switch completion {
                    case .finished:
                        self.logger.logD("VPNConfiguration", "Connection process completed.")
                    case .failure(let e):
                            self.logger.logD("VPNConfiguration", "Connection process failed: \(e)")
                        self.delegate?.setDisconnected()
                    }
                }, receiveValue: { state in
                    switch state {
                    case let .update(message):
                        self.logger.logD("VPNConfiguration", message)
                        self.connectionAlert.updateProgress(message: message)
                    case let .validated(ip):
                        self.delegate?.setConnected(ipAddress: ip)
                    default:
                        break
                    }
                })
        }
    }

    private func connectWithInitialRetry(id: String, proto: String, port: String) -> AnyPublisher<State, Error> {
        configManager.connectAsync(locationID: id, proto: proto, port: port, vpnSettings: makeUserSettings())
            .catch { error in
                if let error = error as? VPNConfigurationErrors, error == .connectionTimeout || error == .connectivityTestFailed {
                    self.logger.logD("VPNConfiguration", "Fail to connect with current node. Trying with next node.")
                    return self.configManager.connectAsync(locationID: id, proto: proto, port: port, vpnSettings: self.makeUserSettings())
                }
                return Fail(error: error).eraseToAnyPublisher()
            }.catch { error in
                return self.showProtocolSelectionPopup(for: error)
                    .flatMap { userSelection in
                        return self.connectWithUserSelection(id: id, userSelection: userSelection)
                    }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }

    private func connectWithUserSelection(id: String, userSelection: ProtocolPort) -> AnyPublisher<State, Error> {
        return configManager.connectAsync(locationID: id, proto: userSelection.protocolName, port: userSelection.portName, vpnSettings: makeUserSettings())
            .catch { error in
                return self.showProtocolSelectionPopup(for: error)
                    .flatMap { newSelection in
                        return self.connectWithUserSelection(id: id, userSelection: newSelection)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    private func showProtocolSelectionPopup(for error: Error) -> Future<ProtocolPort, Error> {
        return Future { promise in
            DispatchQueue.main.async {
                self.logger.logD("VPNConfiguration", "Showing user protocols selection.")
                self.connectionAlert.dismissAlert()
                self.presentProtocolSelectionPopup(
                    error: error,
                    onSelection: { result in
                        if result {
                            let newSelection = self.connectionManager.getNextProtocol()
                            self.logger.logD("VPNConfiguration", "User selected: \(newSelection)")
                            promise(.success(newSelection))
                        } else {
                            self.logger.logD("VPNConfiguration", "User cancelled selection.")
                            promise(.failure(error))
                        }
                    }
                )
            }
        }
    }

    private func presentProtocolSelectionPopup(error: Error, onSelection: @escaping (Bool) -> Void) {
        let changeProtocol = Assembler.resolve(ProtocolSwitchViewController.self)
        changeProtocol.onSelection = onSelection
        if let e = error as? VPNConfigurationErrors {
            changeProtocol.error = e.description
        }
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(changeProtocol, animated: true, completion: nil)
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
                        self.logger.logD("VPNConfiguration", "Failed to disconnect with error: \(e.description)")
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
