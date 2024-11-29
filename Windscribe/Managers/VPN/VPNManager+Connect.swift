//
//  VPNManager+Connect.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import NetworkExtension
import RxSwift
import Swinject

/// Extension of `VPNManager` responsible for managing the connection process, updating preferences, and handling connection errors and retries.
extension VPNManager {
    /// Initiates a disconnect action from the ViewModel, updating the connection state throughout the process.
    /// - Returns: An `AnyPublisher` that publishes updates on the disconnection `State` or an error if the disconnection fails.
    ///
    /// Usage:
    /// Call this function to start the disconnection process. See more: DisconnectTask
    func disconnectFromViewModel() -> AnyPublisher<State, Error> {
        return configManager.disconnectAsync()
            .handleEvents(receiveSubscription: { _ in
                self.configurationState = .disabling
            }, receiveCompletion: { _ in
                self.configurationState = .initial
            }, receiveCancel: {
                self.configurationState = .initial
            }).eraseToAnyPublisher()
    }

    /// Initiates a connection from the ViewModel using the provided location ID and protocol port configuration.
    /// - Parameters:
    ///   - locationId: The ID of the location prepared for connection.
    ///   - proto: The `ProtocolPort` specifying the protocol and port to be used for the connection.
    /// - Returns: An `AnyPublisher` that publishes updates on the connection `State` or an error if the connection fails.
    ///
    /// Usage: Check connectTask function for more Info.
    /// 1. Prepare the `locationId` and `proto`.
    /// 2. Validate the current state and ensure the conditions are met to start a connection.
    /// 3. Call this function to initiate the connection process.
    /// 4. See connectTask func for more info
    func connectFromViewModel(locationId: String, proto: ProtocolPort) -> AnyPublisher<State, Error> {
        self.logger.logD("VPNConfiguration", "Connecting from ViewModel")
        return configManager.validateAccessToLocation(locationID: locationId).flatMap { () in
            let status = self.connectivity.getNetwork().status
            if [NetworkStatus.disconnected].contains(status) {
                return Fail<State, Error>(error: VPNConfigurationErrors.networkIsOffline).eraseToAnyPublisher()
            }
            return self.connectWithInitialRetry(id: locationId, proto: proto.protocolName, port: proto.portName)
        }.handleEvents(receiveSubscription: { _ in
            self.logger.logD("VPNConfiguration", "configurationState set to configuring")
            self.configurationState = .configuring
        }, receiveCompletion: { _ in
            self.logger.logD("VPNConfiguration", "configurationState set to initial")
            self.configurationState = .initial
        }, receiveCancel: {
            self.logger.logD("VPNConfiguration", "configurationState set to initial from cancel")
            self.configurationState = .initial
        }).eraseToAnyPublisher()
    }

    func getProtocolPort() async -> ProtocolPort {
        if let info = try? vpnInfo.value() {
            return ProtocolPort( info.selectedProtocol, info.selectedPort)
        } else {
            return connectionManager.getNextProtocol()
        }
    }

    /// Initiates the VPN connection process, handling connection states and errors, and updating the user through progress alerts.
    ///
    /// This method uses the `connectWithInitialRetry` function to manage retry logic in case of connection errors.
    private func connectTask() {
//        if configurationState == .configuring {
//            logger.logD("VPNConfiguration", "Connection in progress.")
//            DispatchQueue.main.async {
//                self.connectionAlert.dismissAlert()
//                self.disconnectAlert.delegate = self
//                self.disconnectAlert.configure(for: .cancel)
//                self.disconnectAlert.updateProgress(message: "")
//                self.showPopup(popup: self.disconnectAlert)
//            }
//            return
//        }
//        connectionTask?.cancel()
//        connectionTaskPublisher?.cancel()
//        connectionTask = Task(priority: TaskPriority.userInitiated) { @MainActor in
//            let data = prepareConnectionPreferences()
//            connectionTaskPublisher = connectFromViewModel(locationId: data.0, proto: data.1)
//                .receive(on: DispatchQueue.main)
//                .sink(receiveCompletion: { completion in
//                    self.connectionAlert.dismissAlert()
//                    switch completion {
//                    case .finished:
//                        self.logger.logD("VPNConfiguration", "Connection process completed.")
//                    case let .failure(e):
//                        if let e = e as? VPNConfigurationErrors {
//                            self.showError(error: e)
//                        }
//                    }
//                    self.connectionTaskPublisher?.cancel()
//                    self.connectionTask?.cancel()
//                }, receiveValue: { state in
//                    switch state {
//                    case let .update(message):
//                        self.logger.logD("VPNConfiguration", message)
//                        self.connectionAlert.updateProgress(message: message)
//                    case let .validated(ip):
//                        self.logger.logD("VPNConfiguration", message)
//                    case let .vpn(status):
//
//                    default:
//                        break
//                    }
//                })
//        }
    }

    /// Attempts to connect to the VPN, with retry logic for handling authentication failures and connectivity issues.
    ///
    /// - Parameters:
    ///   - id: The location ID for the VPN connection.
    ///   - proto: The protocol to be used for the connection (e.g., OpenVPN, IKEv2).
    ///   - port: The port number for the protocol.
    /// - Returns: An `AnyPublisher` that emits `State` updates or an `Error` if the connection fails after retries.
    private func connectWithInitialRetry(id: String, proto: String, port: String) -> AnyPublisher<State, Error> {
        configManager.connectAsync(locationID: id, proto: proto, port: port, vpnSettings: makeUserSettings())
            .catch { error in
                self.logger.logD("VPNConfiguration", "Fail to connect with error: \(error).")
                if let error = error as? VPNConfigurationErrors {
                    switch error {
                    case .authFailure:
                        return self.updateConnectionData(locationID: id, connectionError: error)
                            .flatMap { updatedLocation in
                                self.configManager.connectAsync(locationID: updatedLocation ?? id, proto: proto, port: port, vpnSettings: self.makeUserSettings())
                            }.eraseToAnyPublisher()
                    // Retry protocol once with new node.
                    case .connectionTimeout, .connectivityTestFailed:
                        self.logger.logD("VPNConfiguration", "Fail to connect with current node. Trying with next node.")
                        return self.configManager.connectAsync(locationID: id, proto: proto, port: port, vpnSettings: self.makeUserSettings())
                    default: ()
                    }
                }
                return Fail(error: error).eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }

    /// Attempts to update VPN connection data, including server data and credentials, in case of an authentication failure.
    /// This method fetches updated session information, credentials, and server details, and validates the specified location.
    /// If successful, it returns the updated location ID; otherwise, it returns a connection error.
    ///
    /// - Parameters:
    ///   - locationID: The ID of the location to be validated and updated if necessary.
    ///   - connectionError: An error that represents the connection failure, returned if updating or validation fails.
    /// - Returns: A `Future` containing the updated location ID as a `String?` if successful, or an `Error` if the process fails.
    ///
    /// - Note:
    ///   It checks for network availability before attempting to update server and credential data, with a maximum wait time of 3 seconds.
    private func updateConnectionData(locationID: String, connectionError: Error) -> Future<String?, Error> {
        logger.logD("VPNConfiguration", "Auth failure: attempting to update server data + credentials.")
        return Future { promise in
            Task {
                do {
                    try await self.connectivity.awaitNetwork(maxTime: 3)
                    _ = try await self.sessionManager.getUppdatedSession().value
                    _ = try await self.credentialsRepository.getUpdatedOpenVPNCrendentials().value
                    _ = try await self.credentialsRepository.getUpdatedIKEv2Crendentials().value
                    _ = try await self.serverRepository.getUpdatedServers().value
                    do {
                        if let updatedLocation = try await self.configManager.validateLocation(lastLocation: locationID) {
                            promise(.success(updatedLocation))
                        } else {
                            promise(.failure(connectionError))
                        }
                    } catch {
                        self.logger.logD("VPNConfiguration", "Failure update location: \(error)")
                        promise(.failure(connectionError))
                    }
                } catch {
                    self.logger.logD("VPNConfiguration", "Failure to update user data: \(error)")
                    promise(.failure(connectionError))
                }
            }
        }
    }

    /// Initiates the VPN disconnection process, updating the user on progress and handling completion and errors.
    private func disconnectTask() {
//        delegate?.setDisconnecting()
//        connectionTaskPublisher = disconnectFromViewModel()
//            .receive(on: DispatchQueue.main)
//            .sink(receiveCompletion: { completion in
//                self.disconnectAlert.dismissAlert()
//                self.delegate?.setDisconnected()
//                switch completion {
//                case .finished:
//                    self.logger.logD("VPNConfiguration", "Disconnect process completed.")
//                    self.disconnectAlert.dismissAlert()
//                case let .failure(error):
//                    self.disconnectAlert.dismissAlert()
//                    if let e = error as? VPNConfigurationErrors {
//                        self.logger.logD("VPNConfiguration", "Failed to disconnect with error: \(e.description)")
//                    }
//                }
//            }, receiveValue: { state in
//                switch state {
//                case let .update(message):
//                    self.disconnectAlert.updateProgress(message: message)
//                case let .vpn(status):
//                    if status == NEVPNStatus.connected {
//                        self.disconnectAlert.dismissAlert()
//                    }
//                default: ()
//                }
//            })
    }
}
