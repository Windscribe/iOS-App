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
extension VPNManager: VPNConnectionAlertDelegate {
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

    func getLocationNode() -> LastConnectedNode? {
        return localDB.getLastConnectedNode()
    }

    func getLocationId() -> String {
        return preferences.getLastSelectedLocation()
    }

    /// Prepares connection preferences by selecting the protocol and connection ID based on user-selected settings or a default configuration.
    ///
    /// - Returns: A tuple containing the connection `id` and `ProtocolPort` with protocol and port details.
    private func prepareConnectionPreferences() -> (String, ProtocolPort) {
        var id = "\(preferences.getLastSelectedLocation())"
        connectionAlert.updateProgress(message: "Please select protocol and connect")

        // TODO: VPNManager: check for staticIPCredentials and customConfig
//        if selectedNode?.staticIPCredentials != nil {
//            let ipId = localDB.getStaticIPs()?.first { $0.connectIP == selectedNode?.staticIpToConnect }?.ipId ?? 0
//            id = "static_\(ipId)"
//        }
//        if let customId = selectedNode?.customConfig?.id {
//            id = "custom_\(customId)"
//            if let proto = configManager.getProtoFromConfig(locationId: customId) {
//                let port = localDB.getPorts(protocolType: proto)?.first ?? "443"
//                selectedProtocol = ProtocolPort(proto, port)
//            }
//        }
        return (id, selectedProtocol)
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

    /// Displays an error alert to the user in case of a VPN connection error and logs the error.
    ///
    /// - Parameter error: A `VPNConfigurationErrors` instance representing the encountered error.
    private func showError(error: VPNConfigurationErrors) {
        let alert = VPNConnectionAlert()
        alert.configure(for: .error("\(error)"))
        showPopup(popup: alert)
        logger.logD("VPNConfiguration", "Connection process failed: \(error)")
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
            }.catch { error in
                self.logger.logD("VPNConfiguration", "\(error)")
                // Handle wg api errors.
                if let e = error as? Errors {
                    switch e {
                    case let .apiError(apiError) where apiError.errorCode == wgLimitExceeded:
                        return self.showDeleteWgKeyPopup(for: error, message: apiError.errorMessage ?? "")
                            .flatMap {
                                var settings = self.makeUserSettings()
                                settings.deleteOldestKey = true
                                return self.configManager.connectAsync(locationID: id, proto: proto, port: port, vpnSettings: settings)
                            }.eraseToAnyPublisher()
                    default: ()
                    }
                }
                // Show options for other protocols.
                return self.showProtocolSelectionPopup(for: error)
                    .flatMap { userSelection in
                        self.connectWithUserSelection(id: id, userSelection: userSelection)
                    }
                    .eraseToAnyPublisher()
            }.eraseToAnyPublisher()
    }

    /// Initiates a connection using a protocol selected by the user.
    ///
    /// - Parameters:
    ///   - id: The location ID for the VPN connection.
    ///   - userSelection: The protocol and port selected by the user.
    /// - Returns: An `AnyPublisher` that emits `State` updates or an `Error` if the connection fails.
    private func connectWithUserSelection(id: String, userSelection: ProtocolPort) -> AnyPublisher<State, Error> {
        return configManager.connectAsync(locationID: id, proto: userSelection.protocolName, port: userSelection.portName, vpnSettings: makeUserSettings())
            .catch { error in
                self.showProtocolSelectionPopup(for: error)
                    .flatMap { newSelection in
                        self.connectWithUserSelection(id: id, userSelection: newSelection)
                    }
                    .eraseToAnyPublisher()
            }
            .eraseToAnyPublisher()
    }

    /// Shows a protocol selection popup for the user to choose an alternate protocol upon connection failure.
    ///
    /// - Parameter error: The error that triggered the protocol selection popup.
    /// - Returns: A `Future` containing the selected `ProtocolPort` or an `Error` if selection fails.
    private func showProtocolSelectionPopup(for error: Error) -> Future<ProtocolPort, Error> {
        return Future { promise in
            DispatchQueue.main.async {
                self.logger.logD("VPNConfiguration", "Showing user protocols selection.")
                self.connectionAlert.dismissAlert()
                self.presentProtocolSelectionPopup(
                    error: error,
                    onSelection: { customError in
                        self.changeProtocol.onSelection = nil
                        if let customError = customError {
                            self.logger.logD("VPNConfiguration", "User cancelled selection.")
                            promise(.failure(customError))
                        } else {
                            let newSelection = self.connectionManager.getNextProtocol()
                            self.logger.logD("VPNConfiguration", "User selected: \(newSelection)")
                            promise(.success(newSelection))
                        }
                    }
                )
            }
        }
    }

    /// Shows a confirmation popup to ask if user wish to delete last wg key.
    ///
    /// - Parameter error: The error that triggered the delete key alert.
    /// - Returns: A `Future` containing success or an `Error` if user cancel.
    private func showDeleteWgKeyPopup(for error: Error, message: String) -> Future<Void, Error> {
        return Future { promise in
            Task {
                self.logger.logD("VPNConfiguration", "Showing delete oldest key popup.")
                await self.connectionAlert.dismissAlert()
                let accept = try await self.alertManager.askUser(message: message).value
                if accept {
                    promise(.success(()))
                } else {
                    promise(.failure(error))
                }
            }
        }
    }

    /// Presents the protocol selection popup to the user and registers a callback for their selection.
    ///
    /// - Parameters:
    ///   - error: The error that prompted the protocol selection.
    ///   - onSelection: A closure called with the user's selection or error.
    private func presentProtocolSelectionPopup(error: Error, onSelection: @escaping (Error?) -> Void) {
        changeProtocol = Assembler.resolve(ProtocolSwitchViewController.self)
        changeProtocol.type = .failure
        connectionManager.onProtocolFail { allProtocolFailed in
            if allProtocolFailed {
                onSelection(VPNConfigurationErrors.allProtocolFailed)
                return
            }
            self.changeProtocol.onSelection = onSelection
            if let e = error as? VPNConfigurationErrors {
                self.changeProtocol.error = e
            }
            self.showPopup(popup: self.changeProtocol)
        }
    }

    /// Displays a modal popup alert for the specified view controller.
    ///
    /// - Parameter popup: The `UIViewController` to present as a modal popup.
    private func showPopup(popup: UIViewController) {
        if let topController = UIApplication.shared.keyWindow?.rootViewController {
            topController.present(popup, animated: true, completion: nil)
        }
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

    func showDisconnectPopup() {
        DispatchQueue.main.async {
            self.disconnectAlert.delegate = self
            self.disconnectAlert.configure(for: .disconnect)
            self.disconnectAlert.updateProgress(message: "")
            self.showPopup(popup: self.disconnectAlert)
        }
        disconnectTask()
    }

    func showConnectPopup() {
        DispatchQueue.main.async {
            self.connectionAlert.delegate = self
            self.connectionAlert.configure(for: .connect)
            self.connectionAlert.updateProgress(message: "")
            self.showPopup(popup: self.connectionAlert)
        }
    }

    func didSelectProtocol(protocolPort: ProtocolPort) {
        connectionManager.onUserSelectProtocol(proto: protocolPort)
        connectionManager.loadProtocols(shouldReset: false) { _ in
            self.selectedProtocol = protocolPort
            self.connectTask()
        }
    }

    func didTapDisconnect() {
        if configurationState == .disabling {
            return
        }
        showDisconnectPopup()
    }

    func tapToCancel() {
        logger.logD("VPNConfiguration", "Tapped to cancel conenction task.")
        connectionTaskPublisher?.cancel()
        disconnectAlert.dismissAlert()
    }
}
