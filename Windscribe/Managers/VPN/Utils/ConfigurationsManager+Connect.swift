//
//  ConfigurationsManager+Connect.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import Foundation
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
    ///   - proto: Protocol identifier to use for the connection (for example, `VPNProtocolType.wireGuard.identifier`).
    ///   - port: A `String` representing the port number  such as "443"
    ///   - vpnSettings: A `VPNUserSettings` object containing user-specific VPN configuration options such as allowLan
    ///
    /// - Returns: An `AnyPublisher<State, Error>` publisher that emits values of type `State` over time, providing updates
    ///   on the current state of the connection (e.g., connecting, validating, connected). In the event of an error, the
    ///   publisher terminates with an `VPNConnectionErrors`.
    func connectAsync(locationID: String, proto: String, port: String, vpnSettings: VPNUserSettings, connectionType: ConnectionType = .user) -> AnyPublisher<VPNConnectionState, Error> {
        let progressPublisher = PassthroughSubject<VPNConnectionState, Error>()
        let attemptId = vpnSettings.connectionAttemptId
        var nextManager: NEVPNManager?
        var isCancelled = false
        logger.logI("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.start protocol=\(proto) connection_type=\(connectionType)")
        let task = Task { [weak self] in
            guard let self = self else { return }
            do {
                try? await nextManager?.loadFromPreferences()

                progressPublisher.send(.update("Building configuration..."))
                let config = try await tryBuildingConfig(locationID: locationID, proto: proto, port: port, vpnSettings: vpnSettings)

                self.logger.logI("VPNLifecycle", "attempt_id=\(attemptId) stage=config.built result=success protocol=\(proto)")
                self.logger.logI("VPNConfiguration", "Configuration built successfully \(config.description)")
                progressPublisher.send(.update("Configuration built successfully \(config.description)"))

                let correctedProtocolPort = checkForCustomConfig(config: config, proto: proto, port: port)
                let protocolName = correctedProtocolPort.protocolName
                let portName = correctedProtocolPort.portName

                let wrapperProtocol = VPNProtocolType.openVPNIdentifiers.contains(protocolName) ? TextsAsset.openVPN : protocolName
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
                self.logger.logI("VPNLifecycle", "attempt_id=\(attemptId) stage=tunnel.start protocol=\(wrapperProtocol)")
                self.logger.logI("VPNConfiguration", "Starting VPN connection.")
                progressPublisher.send(.update("Starting VPN connection."))
                // Clear bridge API host before the tunnel starts so wsnet's
                // autonomous reconnect doesn't use a stale cached token for
                // the previous host. initBridgeApiIfNeeded sets the real host
                // after the tunnel is up and triggers a fresh token fetch. (#969)
                self.bridgeAPI.setCurrentHost("")
                if wrapperProtocol == VPNProtocolType.wireGuard.identifier,
                   let providerSession = nextManager.connection as? NETunnelProviderSession {
                    // Launch options are the handoff point for correlating host and Network Extension logs.
                    try providerSession.startTunnel(options: ["activationAttemptId": attemptId as NSString])
                } else {
                    try nextManager.connection.startVPNTunnel()
                }

                self.delegate?.setActiveManager(with: VPNManagerType(from: wrapperProtocol))

                // Connection status and timeout logic
                progressPublisher.send(.update("Awaiting connection update."))
                let startTime = Date()
                let timerPublisher = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
                var cancellable: AnyCancellable?
                let maxTimeout = self.getMaxTimeout(proto: wrapperProtocol)
                var disconnectErrorFetchTracker = DisconnectErrorFetchTracker()

                cancellable = timerPublisher.sink { _ in
                    guard !isCancelled else {
                        progressPublisher.send(completion: .failure(CancellationError()))
                        cancellable?.cancel()
                        return
                    }

                    let elapsedTime = Date().timeIntervalSince(startTime)
                    let connectionStatus = nextManager.connection.status
                    let shouldFetchDisconnectError = disconnectErrorFetchTracker.shouldFetch(for: connectionStatus)
                    progressPublisher.send(.vpn(connectionStatus))

                    if connectionStatus == .connected {
                        self.logger.logI("VPNLifecycle", "attempt_id=\(attemptId) stage=tunnel.connected result=success")
                        progressPublisher.send(.update("Testing connectivity."))
                        progressPublisher.send(.validating)
                        cancellable?.cancel()
                        if connectionType == .emergency {
                            self.logger.logI("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.end result=success")
                            progressPublisher.send(completion: .finished)
                            return
                        }
                        Task {
                            do {
                                try await self.pinIPAndTestConnectivity(proto: proto) {
                                    return isCancelled
                                }
                                if isCancelled {
                                    progressPublisher.send(.update("Task cancelled"))
                                }
                                progressPublisher.send(.update("Connectivity test successful"))
                                progressPublisher.send(.validated)
                                self.logger.logI("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.end result=success")
                                progressPublisher.send(completion: .finished)

                                self.preferences.increaseConnectionCount()
                            } catch {
                                self.logger.logE("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.end result=failure error_type=\(String(describing: type(of: error)))")
                                try await self.disableProfile(nextManager)
                                await self.reloadManagers()
                                progressPublisher.send(completion: .failure(error))
                            }
                        }
                    } else if elapsedTime >= maxTimeout {
                        progressPublisher.send(.update("Failed to connect: Timed out after \(Int(maxTimeout)) seconds"))
                        Task {
                            // Capture Network Extension/provider evidence before stop/disable tears it down.
                            let connectionError = await self.getConnectError(
                                manager: nextManager,
                                protocolName: wrapperProtocol,
                                attemptId: attemptId,
                                fallback: .timedOut
                            )
                            nextManager.connection.stopVPNTunnel()
                            do {
                                try await self.disableProfile(nextManager)
                            } catch {
                                self.logger.logE("VPNConfiguration", "Failed to disable profile after connection timeout: \(error).")
                            }
                            self.logger.logE("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.end result=failure error_type=\(String(describing: type(of: connectionError)))")
                            try? await self.waitForDisconnection(manager: nextManager)
                            progressPublisher.send(completion: .failure(connectionError))
                        }
                        cancellable?.cancel()
                    } else {
                        if shouldFetchDisconnectError {
                            Task {
                                do {
                                    try await self.lookForConnectFailure(
                                        manager: nextManager,
                                        protocolName: wrapperProtocol,
                                        attemptId: attemptId
                                    )
                                } catch {
                                    cancellable?.cancel()
                                    self.logger.logE("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.end result=failure error_type=\(String(describing: type(of: error)))")
                                    try await self.disableProfile(nextManager)
                                    progressPublisher.send(completion: .failure(error))
                                }
                            }
                        }
                        let parsedTime = "\(Int(elapsedTime)).\(Int(elapsedTime * 10.0) % 10)"
                        progressPublisher.send(.update("Attempting to connect... elapsed time: \(parsedTime) seconds"))
                    }
                }
            } catch let error {
                self.logger.logE("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.end result=failure error_type=\(String(describing: type(of: error)))")
                self.logger.logE("VPNConfiguration", "Failed connection with error: \(error).")
                progressPublisher.send(completion: .failure(error))
            }
        }
        return progressPublisher
            .handleEvents(receiveCancel: {
                self.logger.logI("VPNLifecycle", "attempt_id=\(attemptId) stage=attempt.end result=cancelled")
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
            return ProtocolPort(protocolName: config.proto, portName: proto == VPNProtocolType.iKEv2.identifier ? "443" : port)
        } else if config is WireguardVPNConfiguration {
            return ProtocolPort(protocolName: VPNProtocolType.wireGuard.identifier, portName: proto == VPNProtocolType.iKEv2.identifier ? "443" : port)
        }
        return ProtocolPort(protocolName: proto, portName: port)
    }

    private func tryBuildingConfig(locationID: String,
                                   proto: String,
                                   port: String,
                                   vpnSettings: VPNUserSettings) async throws -> VPNConfiguration {
        do {
            let config: VPNConfiguration? = try await withCheckedThrowingContinuation { continuation in
                let state = ConfigBuildTimeoutState(continuation: continuation)
                let buildTask = Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        let config = try await self.buildConfig(location: locationID,
                                                                proto: proto,
                                                                port: port,
                                                                userSettings: vpnSettings)
                        state.resume(.success(config))
                    } catch {
                        state.resume(.failure(error))
                    }
                }
                state.setTask(buildTask)

                DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                    state.resume(.failure(VPNConfigurationErrors.connectionTimeout))
                }
            }
            guard let config else { throw VPNConfigurationErrors.connectionTimeout }
            return config
        } catch {
            throw classifyConfigurationError(
                error,
                protocolName: proto,
                attemptId: vpnSettings.connectionAttemptId
            )
        }
    }

    func getGeneralConnectError() async -> VPNConfigurationErrors? {
        connectErrorLookupLock.lock()
        guard !isCheckingConnectError else {
            connectErrorLookupLock.unlock()
            logger.logI("VPNConfiguration", "Skipping concurrent last disconnect error lookup.")
            return nil
        }
        isCheckingConnectError = true
        connectErrorLookupLock.unlock()

        defer {
            connectErrorLookupLock.lock()
            isCheckingConnectError = false
            connectErrorLookupLock.unlock()
        }

        guard let activeManagerKey = preferences.getActiveManagerKey() else { return nil }
        await loadTunnelManagers()
        let managerType = VPNManagerType(from: activeManagerKey)
        guard let activeManager = getManager(for: managerType) else { return nil }
        let failure = await getConnectError(
            manager: activeManager,
            protocolName: managerType.username,
            attemptId: nil,
            fallback: .unknown
        )
        guard case let .classified(classified) = failure,
              classified.reason == .accountSessionInvalid || classified.reason == .accountLimitation else {
            return nil
        }
        return failure
    }

    private func getConnectError(manager: NEVPNManager,
                                 protocolName: String,
                                 attemptId: String?,
                                 fallback: ConnectionFailureReason,
                                 providerError: PacketTunnelProviderError? = nil) async -> VPNConfigurationErrors {
        var rawError: Error?
        if #available(iOS 16.0, tvOS 17.0, *) {
            do {
                try await manager.connection.fetchLastDisconnectError()
            } catch {
                rawError = error
            }
        }

        let providerFailure = providerError ?? {
            guard protocolName == VPNProtocolType.wireGuard.identifier,
                  let attemptId else { return nil }
            return PacketTunnelProviderError.consume(matching: attemptId)
        }()
        let failure = VPNFailureClassifier.classify(
            protocolName: protocolName,
            stage: fallback == .timedOut ? .timeout : .tunnel,
            error: rawError,
            providerError: providerFailure,
            disconnectReason: preferences.getDisconnectReason(),
            fallback: fallback
        )
        log(failure: failure, attemptId: attemptId)
        return .classified(failure)
    }

    private func lookForConnectFailure(manager: NEVPNManager,
                                       protocolName: String,
                                       attemptId: String) async throws {
        let providerError = protocolName == VPNProtocolType.wireGuard.identifier
            ? PacketTunnelProviderError.consume(matching: attemptId)
            : nil
        if providerError == nil {
            guard #available(iOS 16.0, tvOS 17.0, *) else { return }
        }
        guard providerError != nil || manager.connection.status == .disconnected || manager.connection.status == .invalid else {
            return
        }
        throw await getConnectError(
            manager: manager,
            protocolName: protocolName,
            attemptId: attemptId,
            fallback: .unknown,
            providerError: providerError
        )
    }

    /// Preserves non-WireGuard and handled API errors. Other WireGuard configuration failures
    /// become either a typed timeout or a registration/configuration fallback.
    private func classifyConfigurationError(_ error: Error,
                                            protocolName: String,
                                            attemptId: String) -> Error {
        guard protocolName == VPNProtocolType.wireGuard.identifier else { return error }
        let fallback: ConnectionFailureReason
        if let configurationError = error as? VPNConfigurationErrors,
           configurationError == .connectionTimeout {
            fallback = .timedOut
        } else {
            if let apiError = error as? Errors, apiError == .handled { return error }
            fallback = error is Errors ? .wireGuardRegistration : .wireGuardConfiguration
        }
        let failure = VPNFailureClassifier.classify(
            protocolName: protocolName,
            stage: .configuration,
            error: error,
            fallback: fallback
        )
        log(failure: failure, attemptId: attemptId)
        return VPNConfigurationErrors.classified(failure)
    }

    private func log(failure: VPNConnectionFailure, attemptId: String?) {
        let provider = failure.evidence.providerError?.rawValue ?? "none"
        let domain = failure.evidence.systemError?.domain ?? "none"
        let code = failure.evidence.systemError?.code ?? 0
        logger.logE(
            "VPNFailure",
            "attempt_id=\(attemptId ?? "none") protocol=\(failure.evidence.protocolName) stage=\(failure.evidence.stage.rawValue) reason=\(failure.reason) provider=\(provider) system_domain=\(domain) system_code=\(code)"
        )
    }

    /// Set up bridge API state, test connectivity, then pin IP.
    /// Connectivity test runs first — its retry loop ensures the tunnel is
    /// usable before we attempt pinIp, which avoids racing against wsnet's
    /// cold start after a custom config disconnect (#969).
    private func pinIPAndTestConnectivity(proto: String, checkIsTaskCancelled: () -> Bool) async throws {
        // Set up bridge API state for non-custom-config connections
        initBridgeApiIfNeeded(proto: proto)
        // Test connectivity — confirms tunnel is usable
        let connectivitySuccess = await testConnectivity(checkIsTaskCancelled: checkIsTaskCancelled)
        if !connectivitySuccess {
            throw VPNConfigurationErrors.connectivityTestFailed
        }
        // Pin IP after tunnel is confirmed working
        let ipPinningError = await pinIpIfNeeded()
        if ipPinningError != nil {
            showFailedPinIpTrigger.send()
        }
        Task {
            // it needs to refresh ip after pinning, or it might not show new ip
            try? await ipRepository.getIp()
        }
    }

    /// Initialise bridge API state for server connections so wsnet can
    /// route through the VPN tunnel.  Skipped for custom configs.
    private func initBridgeApiIfNeeded(proto: String) {
        if !preferences.getIgnorePinIP() && !preferences.isCustomConfigSelected() {
            let currentHost = preferences.getLastNodeIP() ?? ""
            if proto == "WireGuard" {
                logger.logI("ConfigurationsManager","Bridge API - WSNEt - set host for wireguard: \(currentHost)")
                bridgeAPI.setCurrentHost(currentHost)
            }
            bridgeAPI.setConnectedState(true)
            self.logger.logI("ConfigurationsManager", "wsnet setIsConnectedToVpnState to true")
            WSNet.instance().setIsConnectedToVpnState(true)
        } else {
            preferences.saveIgnorePinIP(status: false)
        }
    }

    /// Pin IP if there is one selected. Returns error on failure, nil otherwise.
    private func pinIpIfNeeded() async -> Error? {
        guard !preferences.isCustomConfigSelected(),
              let pinnedIp = preferences.getLastSelectedPinnedIp() else {
            return nil
        }
        logger.logI("ConfigurationsManager","Bridge API - WSNEt - Pinning IP: \(pinnedIp)")
        do {
            _ = try await api.pinIp(ip: pinnedIp)
            logger.logI("ConfigurationsManager", "IP pinned successfully")
            return nil
        } catch {
            logger.logE("ConfigurationsManager","Failed to pin IP: \(error)")
            return error
        }
    }

    /// Test connectivity with retries. Returns true if successful, false otherwise.
    private func testConnectivity(checkIsTaskCancelled: () -> Bool) async -> Bool {
        WSNet.instance().setIsConnectedToVpnState(true)
        for attempt in 1 ... maxConnectivityTestAttempts {
            do {
                try await ipRepository.getIp(usePingTest: true)
                logger.logI("ConfigurationsManager", "Connectivity test successful")
                return true
            } catch {
                if checkIsTaskCancelled() {
                    logger.logE("VPNConfiguration", "Connectivity test cancelled")
                    return false
                }
                if attempt == maxConnectivityTestAttempts {
                    self.logger.logE("VPNConfiguration", "Connectivity error: \(error)")
                    return false
                }
                try? await Task.sleep(nanoseconds: delayBetweenConnectivityAttempts)
            }
        }
        return false
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

struct DisconnectErrorFetchTracker {
    private var previousStatus: NEVPNStatus?
    private var didFetchDisconnectError = false

    mutating func shouldFetch(for status: NEVPNStatus) -> Bool {
        defer { previousStatus = status }

        guard !didFetchDisconnectError,
              status == .disconnected,
              let previousStatus,
              previousStatus != .disconnected else {
            return false
        }

        didFetchDisconnectError = true
        return true
    }
}

private final class ConfigBuildTimeoutState: @unchecked Sendable {
    private let continuation: CheckedContinuation<VPNConfiguration?, Error>
    private let lock = NSLock()
    private var didResume = false

    private var task: Task<Void, Never>?

    init(continuation: CheckedContinuation<VPNConfiguration?, Error>) {
        self.continuation = continuation
    }

    func setTask(_ task: Task<Void, Never>) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            task.cancel()
            return
        }
        self.task = task
        lock.unlock()
    }

    func resume(_ result: Result<VPNConfiguration?, Error>) {
        lock.lock()
        guard !didResume else {
            lock.unlock()
            return
        }
        didResume = true
        let task = task
        self.task = nil
        lock.unlock()

        task?.cancel()

        switch result {
        case .success(let config):
            continuation.resume(returning: config)
        case .failure(let error):
            continuation.resume(throwing: error)
        }
    }
}
