//
//  ConfigurationsManager+Connect.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import NetworkExtension
import Swinject

enum VPNConnectionState {
    case update(String), vpn(NEVPNStatus), validating, validated
}

extension ConfigurationsManager {
    /// Initiates an asynchronous VPN connection/reconnect process with the specified configuration parameters.
    ///
    /// This function attempts disconnect existing connect and to connect to a VPN server with the provided `locationID`, `proto`, and `port`,
    /// using custom VPN settings encapsulated within `VPNUserSettings`. The connection process is represented
    /// as a publisher that emits connection states (`State`) over time, allowing for progress updates, success, or failure.
    ///
    /// - Parameters:
    ///   - locationID: A `String` representing the unique identifier of the VPN server location to connect to. This could
    ///     be a specific server ID, a static IP ID, or a custom configuration ID, depending on the user's selection.
    ///   - proto: A `String` specifying the protocol to use for the connection (e.g., "TextAsset.WireGuard", "TextAsset.IKEv2",  udp", "tcp", "wstunnel", "stealth"").
    ///   - port: A `String` representing the port number  such as "443"
    ///   - vpnSettings: A `VPNUserSettings` object containing user-specific VPN configuration options such as allowLan
    ///
    /// - Returns: An `AnyPublisher<State, Error>` publisher that emits values of type `State` over time, providing updates
    ///   on the current state of the connection (e.g., connecting, validating, connected). In the event of an error, the
    ///   publisher terminates with an `VPNConnectionErrors`.
    func connectAsync(locationID: String, proto: String, port: String, vpnSettings: VPNUserSettings, connectionType: ConnectionType = .user) -> AnyPublisher<VPNConnectionState, Error> {
        let progressPublisher = PassthroughSubject<VPNConnectionState, Error>()
        var nextManager: NEVPNManager?
        var isCancelled = false
        let task = Task { [weak self] in
            guard let self = self else { return }
            do {
                try? await nextManager?.loadFromPreferences()

                progressPublisher.send(.update("Building configuration..."))
                guard let config = try await tryBuildingConfig(locationID: locationID, proto: proto, port: port, vpnSettings: vpnSettings) else {
                    throw VPNConfigurationErrors.connectionTimeout
                }

                self.logger.logI("VPNConfiguration", "Configuration built successfully \(config.description)")
                progressPublisher.send(.update("Configuration built successfully \(config.description)"))

                let correctedProtocolPort = checkForCustomConfig(config: config, proto: proto, port: port)
                let protocolName = correctedProtocolPort.protocolName
                let portName = correctedProtocolPort.portName

                let wrapperProtocol = [udp, tcp, wsTunnel, stealth].contains(protocolName) ? TextsAsset.openVPN : protocolName
                self.logger.logI("VPNConfiguration", "Attempting connection: [Location: \(locationID) \(protocolName) \(portName) \(vpnSettings.description)")
                progressPublisher.send(.update("Attempting connection: [Location: \(locationID) \(protocolName) \(portName) \(vpnSettings.description)"))
                guard !Task.isCancelled else { return }
                self.logger.logI("VPNConfiguration", "disconnectExistingConnections")
                try await self.disconnectExistingConnections(proto: wrapperProtocol, progressPublisher: progressPublisher)

                guard !Task.isCancelled else { return }
                self.logger.logI("VPNConfiguration", "prepareNextManager")
                nextManager = try await self.prepareNextManager(proto: wrapperProtocol, progressPublisher: progressPublisher)

                try await Task.sleep(nanoseconds: 1_000_000_000)
                self.logger.logI("VPNConfiguration", "Building configuration.")
                progressPublisher.send(.update("Building configuration."))

                guard !Task.isCancelled else { return }

                self.logger.logI("VPNConfiguration", "Building NEVPNTunnelProtocol.")
                progressPublisher.send(.update("Building NEVPNTunnelProtocol."))
                guard let nextManager = nextManager else { return }
                try config.buildProtocol(settings: vpnSettings, manager: nextManager)

                self.logger.logI("VPNConfiguration", "Applying user settings.")
                progressPublisher.send(.update("Applying user settings."))
                config.applySettings(settings: vpnSettings, manager: nextManager)

                self.logger.logI("VPNConfiguration", "Saving configuration.")
                progressPublisher.send(.update("Saving configuration."))
                try await self.saveToPreferences(manager: nextManager)
                cacheTunnelManager(manager: nextManager)
                self.logger.logI("VPNConfiguration", "Starting VPN connection.")
                progressPublisher.send(.update("Starting VPN connection."))
                try nextManager.connection.startVPNTunnel()

                self.delegate?.setActiveManager(with: VPNManagerType(from: wrapperProtocol))

                // Connection status and timeout logic
                progressPublisher.send(.update("Awaiting connection update."))
                let startTime = Date()
                let timerPublisher = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
                var cancellable: AnyCancellable?
                let maxTimeout = self.getMaxTimeout(proto: wrapperProtocol)

                cancellable = timerPublisher.sink { _ in
                    guard !isCancelled else {
                        progressPublisher.send(completion: .failure(CancellationError()))
                        cancellable?.cancel()
                        return
                    }

                    let elapsedTime = Date().timeIntervalSince(startTime)
                    progressPublisher.send(.vpn(nextManager.connection.status))

                    if nextManager.connection.status == .connected {
                        progressPublisher.send(.update("Testing connectivity."))
                        progressPublisher.send(.validating)
                        cancellable?.cancel()
                        if connectionType == .emergency {
                            progressPublisher.send(completion: .finished)
                            return
                        }
                        Task {
                            do {
                                try await self.testConnectivityWithRetries(nextManager: nextManager,
                                                                           forLocationId: locationID,
                                                                           proto: proto) {
                                    return isCancelled
                                }
                                if isCancelled {
                                    progressPublisher.send(.update("Task cancelled"))
                                }
                                progressPublisher.send(.update("Connectivity test successful"))
                                progressPublisher.send(.validated)
                                progressPublisher.send(completion: .finished)

                                self.preferences.increaseConnectionCount()
                            } catch {
                                try await self.disableProfile(nextManager)
                                await self.reloadManagers()
                                progressPublisher.send(completion: .failure(error))
                            }
                        }
                    } else if elapsedTime >= maxTimeout {
                        progressPublisher.send(.update("Failed to connect: Timed out after \(Int(maxTimeout)) seconds"))
                        Task {
                            do {
                                try await self.getConnectError(manager: nextManager)
                                try await self.disableProfile(nextManager)
                            } catch {
                                progressPublisher.send(completion: .failure(error))
                            }
                        }
                        cancellable?.cancel()
                    } else {
                        Task {
                            do {
                                try await self.lookForAuthFailure(manager: nextManager)
                            } catch {
                                cancellable?.cancel()
                                try await self.disableProfile(nextManager)
                                progressPublisher.send(completion: .failure(error))
                            }
                            let parsedTime = "\(Int(elapsedTime)).\(Int(elapsedTime * 10.0) % 10)"
                            progressPublisher.send(.update("Attempting to connect... elapsed time: \(parsedTime) seconds"))
                        }
                    }
                }
            } catch let error {
                self.logger.logE("VPNConfiguration", "Failed connection with error: \(error).")
                progressPublisher.send(completion: .failure(error))
            }
        }
        return progressPublisher
            .handleEvents(receiveCancel: {
                self.logger.logI("VPNConfiguration", "Cancelling connection task.")
                task.cancel()
                isCancelled = true
                Task {
                    try await self.disableProfile(self.getNextManager(proto: proto))
                }
            })
            .eraseToAnyPublisher()
    }

    private func checkForCustomConfig(config: VPNConfiguration, proto: String, port: String) -> ProtocolPort {
        if let config = config as? OpenVPNConfiguration {
            return ProtocolPort(protocolName: config.proto, portName: proto == TextsAsset.iKEv2 ? "443" : port)
        } else if config is WireguardVPNConfiguration {
            return ProtocolPort(protocolName: TextsAsset.wireGuard, portName: proto == TextsAsset.iKEv2 ? "443" : port)
        }
        return ProtocolPort(protocolName: proto, portName: port)
    }

    private func tryBuildingConfig(locationID: String,
                                   proto: String,
                                   port: String,
                                   vpnSettings: VPNUserSettings) async throws -> VPNConfiguration? {

        try await withThrowingTaskGroup(of: VPNConfiguration?.self) { group in
            group.addTask {
                try await self.buildConfig(location: locationID, proto: proto, port: port, userSettings: vpnSettings)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 30_000_000_000)
                return nil
            }
            // Return first completed task and cancel the rest
            guard let config = try await group.next() else { return nil }
            group.cancelAll()
            return config
        }
    }

    private func getConnectError(manager: NEVPNManager) async throws {
        if #available(iOS 16.0, *) {
            do {
                try await manager.connection.fetchLastDisconnectError()
            } catch {
                if let nsError = error as NSError? {
                    self.logger.logE("VPNConfiguration", "Connection error: \(nsError)")
                    if [12, 8, 50].contains(nsError.code) {
                        throw VPNConfigurationErrors.authFailure
                    }
                }

                // Check if error message contains NEHotspotNetwork error - treat as connection timeout
                let errorString = error.localizedDescription
                if errorString.contains("NEHotspotNetwork") || errorString.contains("nehelper sent invalid result") {
                    self.logger.logE("VPNConfiguration", "NEHotspotNetwork error detected - treating as connection timeout")
                    throw VPNConfigurationErrors.connectionTimeout
                }
            }
        }
        throw VPNConfigurationErrors.connectionTimeout
    }

    private func lookForAuthFailure(manager: NEVPNManager) async throws {
        if #available(iOS 16.0, *) {
            do {
                try await manager.connection.fetchLastDisconnectError()
            } catch {
                if let nsError = error as NSError?, [12, 8, 50].contains(nsError.code) {
                    throw VPNConfigurationErrors.authFailure
                }
            }
        }
    }

    /// Test VPN connection for network connectivity.
    private func testConnectivityWithRetries(nextManager: NEVPNManager,
                                             forLocationId: String,
                                             proto: String,
                                             checkIsTaskCancelled: () -> Bool) async throws {
        try await Task.sleep(nanoseconds: delayBetweenConnectivityAttempts)

        let currentHost = preferences.getLastNodeIP() ?? ""

        if proto == "WireGuard" {
            bridgeAPI.setCurrentHost(currentHost)
        } else {
            bridgeAPI.setCurrentHost("")
        }

        bridgeAPI.setIgnoreSslErrors(true)
        bridgeAPI.setConnectedState(true)

        var ipPinningFailed = false
        var shouldCheckPinning = false
        var hasPinnedNodeMismatch = false

        let favourite = localDatabase.getFavouriteList().first { $0.id == forLocationId }
        if let favourite = favourite {
            shouldCheckPinning = favourite.pinnedNodeIp != nil
            hasPinnedNodeMismatch = shouldCheckPinning && favourite.pinnedNodeIp != currentHost

            if let pinnedIp = favourite.pinnedIp {
                logger.logI("ConfigurationsManager","Bridge API - WSNEt -Pinning IP: \(pinnedIp)")
                do {
                    _ = try await api.pinIp(ip: pinnedIp)
                    logger.logI("ConfigurationsManager", "IP pinned successfully")
                } catch {
                    logger.logE("ConfigurationsManager","Failed to pin IP: \(error)")
                    ipPinningFailed = true
                }
            }
        }

        for attempt in 1 ... maxConnectivityTestAttempts {
            do {
                try await ipRepository.getIp().value
                if hasPinnedNodeMismatch || ipPinningFailed {
                    showFailedPinIpTrigger.send()
                }
                return
            } catch {
                if checkIsTaskCancelled() {
                    throw VPNConfigurationErrors.connectivityTestFailed
                }
                if attempt == maxConnectivityTestAttempts {
                    self.logger.logE("VPNConfiguration", "Connectivity error: \(error)")
                    throw VPNConfigurationErrors.connectivityTestFailed
                }
                try await Task.sleep(nanoseconds: delayBetweenConnectivityAttempts)
            }
        }
        throw VPNConfigurationErrors.connectivityTestFailed
    }

    /// Initiates an asynchronous VPN disconnection process for any active VPN managers.
    ///
    /// - Returns: An `AnyPublisher<State, Error>` publisher that emits `State` values over time, allowing for progress
    ///   updates throughout the disconnection process. If an error occurs during disconnection, the publisher terminates
    ///   with an `Error`.
    /// ### Disconnection Process
    /// 1. **Retrieve Active VPN Managers**: Attempts to retrieve all available VPN managers.
    /// 2. **Start Disconnection for Each Active Manager**:
    ///     - Disables `includeAllNetworks` and `isOnDemandEnabled` in the manager's protocol configuration.
    ///     - Saves the changes to preferences and stops the VPN tunnel.
    ///     - Waits until the disconnection process completes for each manager.
    ///
    /// - Parameters:
    ///     - State: Represents disconnection states (e.g., updating status messages).
    ///
    /// - Throws: This function emits errors for disconnection failures, which are passed to the publisher's error handler.
    ///
    func disconnectAsync() -> AnyPublisher<VPNConnectionState, Error> {
        let progressPublisher = PassthroughSubject<VPNConnectionState, Error>()
        Task {
            progressPublisher.send(.update("Retrieving active VPN manager..."))
            do {
                let managers = (try? await getAllManagers()) ?? []
                for activeManager in managers {
                    progressPublisher.send(.update("Active VPN manager found, starting disconnection process..."))
#if os(iOS)
                    activeManager.protocolConfiguration?.includeAllNetworks = false
#endif
                    activeManager.isOnDemandEnabled = false
                    try await saveToPreferences(manager: activeManager)
                    activeManager.connection.stopVPNTunnel()
                    try? await waitForDisconnection(manager: activeManager)
                    progressPublisher.send(.update("VPN disconnection initiated."))
                }
                progressPublisher.send(.update("VPN disconnection finished."))
                progressPublisher.send(completion: .finished)
            } catch {
                progressPublisher.send(.update("VPN disconnection failed with error: \(error.localizedDescription)."))
                progressPublisher.send(completion: .failure(error))
            }
        }
        return progressPublisher.eraseToAnyPublisher()
    }

    /// Disconnect all connected managers except one being used for next protocol.
    /// Remove any on demand rules to avoid reconnect from this protocol after disconnect.
    private func disconnectExistingConnections(proto: String, progressPublisher: PassthroughSubject<VPNConnectionState, Error>) async throws {
        let managers = await getOtherManagers(proto: proto)
        for other in managers {
            try? await other.loadFromPreferences()

            let managerName = getManagerName(from: other)
            progressPublisher.send(.update("Existing config: [\(managerName) Enabled: \(other.isEnabled) Status: \(other.connection.status)]"))
            if other.connection.status == .connected || other.connection.status == .connecting {
                progressPublisher.send(.update("Stopping other connection from \(managerName)"))
                other.connection.stopVPNTunnel()
                try? await waitForDisconnection(manager: other)
            }
            other.isEnabled = false
            other.isOnDemandEnabled = false
            other.onDemandRules = []
            try? await saveToPreferences(manager: other)
        }
    }

    /// Load vpn manager for the protocol, stop any existing connection and disable it.
    private func prepareNextManager(proto: String, progressPublisher: PassthroughSubject<VPNConnectionState, Error>) async throws -> NEVPNManager {
        progressPublisher.send(.update("Fetching next VPN manager for \(proto)"))
        let nextManager = await getNextManager(proto: proto)
        try await nextManager.loadFromPreferences()
        if nextManager.connection.status == .connected || nextManager.connection.status == .connecting {
            nextManager.connection.stopVPNTunnel()
            try? await waitForDisconnection(manager: nextManager)
            try await nextManager.loadFromPreferences()
        }
        try await disableProfile(nextManager)
        return nextManager
    }

    /// Block untill disconnect event is received.
    private func waitForDisconnection(manager: NEVPNManager) async throws {
        let startTime = Date()
        while manager.connection.status != .disconnected {
            if Date().timeIntervalSince(startTime) > disconnectWaitTimeout {
                break
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    /// Disable VPN configuration
    private func disableProfile(_ manager: NEVPNManager) async throws {
        var includesAllNetworks: Bool? = false
#if os(iOS)
        includesAllNetworks = manager.protocolConfiguration?.includeAllNetworks
#endif
        if  includesAllNetworks == true || manager.isEnabled || manager.isOnDemandEnabled {
            try? await manager.loadFromPreferences()

            manager.isEnabled = false
            manager.isOnDemandEnabled = false
#if os(iOS)
            manager.protocolConfiguration?.includeAllNetworks = false
#endif
            try await saveToPreferences(manager: manager)
        }
    }
}
