//
//  Configuration+Connect.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-10-31.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Combine
import NetworkExtension
import Swinject

enum State {
    case update(String), vpn(NEVPNStatus), validating, validated(String)
}

extension ConfigurationsManager {
    func connectAsync(locationID: String, proto: String, port: String, vpnSettings: VPNUserSettings) -> AnyPublisher<State, Error> {
        let progressPublisher = PassthroughSubject<State, Error>()
        let maxTimeout: TimeInterval = 30

        Task {
            let wrapperProtocol = [udp, tcp, wsTunnel, stealth].contains(proto) ? TextsAsset.openVPN : proto
            progressPublisher.send(.update("Attempting connection: [Location: \(locationID) \(proto) \(port) \(vpnSettings.description)"))

            do {
                try await disconnectExistingConnections(proto: wrapperProtocol, progressPublisher: progressPublisher)
                var nextManager = try await prepareNextManager(proto: wrapperProtocol, progressPublisher: progressPublisher)
                try await Task.sleep(nanoseconds: 3 * 1_000_000_000)
                progressPublisher.send(.update("Building configuration..."))
                let config = try await buildConfig(location: locationID, proto: proto, port: port, userSettings: vpnSettings)
                progressPublisher.send(.update("Configuration built successfully \(config.description)"))

                progressPublisher.send(.update("Building NEVPNTunnelProtocol."))
                nextManager = try config.buildProtocol(settings: vpnSettings, manager: nextManager)

                progressPublisher.send(.update("Applying user settings..."))
                nextManager = config.applySettings(settings: vpnSettings, manager: nextManager)

                progressPublisher.send(.update("Saving configuration"))
                try await saveThrowing(manager: nextManager)

                progressPublisher.send(.update("Starting VPN connection..."))
                try nextManager.connection.startVPNTunnel()

                // Monitor VPN connection status
                let startTime = Date()
                let timerPublisher = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
                var cancellable: AnyCancellable?

                cancellable = timerPublisher.sink { _ in
                    let elapsedTime = Date().timeIntervalSince(startTime)
                    // Send VPN status
                    progressPublisher.send(.vpn(nextManager.connection.status))

                    if nextManager.connection.status == .connected {
                        progressPublisher.send(.validating)
                        Task {
                            do {
                                let userIp = try await self.testConnectivityWithRetries()
                                progressPublisher.send(.update("Connectivity test successful, IP: \(userIp)"))
                                progressPublisher.send(.validated(userIp))
                                progressPublisher.send(completion: .finished)
                            } catch {
                                progressPublisher.send(completion: .failure(error))
                            }
                        }
                        cancellable?.cancel()
                    } else if elapsedTime >= maxTimeout {
                        progressPublisher.send(.update("Failed to connect: Timed out after \(Int(maxTimeout)) seconds"))
                        Task {
                            try await self.disableProfile(nextManager)
                        }
                        progressPublisher.send(completion: .failure(VPNConfigurationErrors.connectionTimeout))
                        cancellable?.cancel()
                    } else {
                        progressPublisher.send(.update("Attempting to connect... elapsed time: \(Int(elapsedTime)) seconds"))
                    }
                }

            } catch {
                logger.logD(self, "Unable to build VPN configuration error: \(error)")
                progressPublisher.send(completion: .failure(error))
            }
        }

        return progressPublisher.eraseToAnyPublisher()
    }

    private func disconnectExistingConnections(proto: String, progressPublisher: PassthroughSubject<State, Error>) async throws {
        let managers = await getOtherManagers(proto: proto)
        for other in managers {
            try await other.loadFromPreferences()
            let managerName = getManagerName(from: other)
            progressPublisher.send(.update("Existing config: [\(managerName) Enabled: \(other.isEnabled) Status: \(other.connection.status)]"))
            if other.connection.status == .connected || other.connection.status == .connecting {
                progressPublisher.send(.update("Stopping other connection from \(managerName)"))
                other.connection.stopVPNTunnel()
                try? await waitForDisconnection(manager: other)
            }
            try await other.loadFromPreferences()
            other.onDemandRules = []
            try await other.saveToPreferences()
        }
    }

    private func prepareNextManager(proto: String, progressPublisher: PassthroughSubject<State, Error>) async throws -> NEVPNManager {
        progressPublisher.send(.update("Fetching next VPN manager for \(proto)"))
        var nextManager = await getNextManager(proto: proto)
        try await nextManager.loadFromPreferences()
        if nextManager.connection.status == .connected || nextManager.connection.status == .connecting {
            nextManager.connection.stopVPNTunnel()
            try? await waitForDisconnection(manager: nextManager)
            try await nextManager.loadFromPreferences()
        }
        try await disableProfile(nextManager)
        return nextManager
    }

    private func testConnectivityWithRetries() async throws -> String {
        let maxAttempts = 3
        let delayBetweenAttempts: UInt64 = 500_000_000

        for attempt in 1 ... maxAttempts {
            do {
                let userIp = try await testConnectivity()
                return userIp
            } catch {
                if attempt == maxAttempts {
                    throw error
                }
                try await Task.sleep(nanoseconds: delayBetweenAttempts)
            }
        }
        throw VPNConfigurationErrors.connectivityTestFailed
    }

    private func testConnectivity() async throws -> String {
        let api = Assembler.resolve(APIManager.self)
        return try await api.getIp().value.userIp
    }

    func disconnectAsync() -> AnyPublisher<State, Error> {
        let progressPublisher = PassthroughSubject<State, Error>()
        Task {
            progressPublisher.send(.update("Retrieving active VPN manager..."))
            do {
                let managers = (try? await getAllManagers()) ?? []
                for activeManager in managers {
                    progressPublisher.send(.update("Active VPN manager found, starting disconnection process..."))
                    activeManager.protocolConfiguration?.includeAllNetworks = false
                    activeManager.isOnDemandEnabled = false
                    try await activeManager.saveToPreferences()
                    activeManager.connection.stopVPNTunnel()
                    try? await waitForDisconnection(manager: activeManager)
                    progressPublisher.send(.update("VPN disconnection initiated."))
                }
                progressPublisher.send(completion: .finished)
            } catch {
                progressPublisher.send(completion: .failure(error))
            }
        }
        return progressPublisher.eraseToAnyPublisher()
    }

    private func waitForDisconnection(manager: NEVPNManager) async throws {
        let maxWaitTime: TimeInterval = 5
        let startTime = Date()
        while manager.connection.status != .disconnected {
            if Date().timeIntervalSince(startTime) > maxWaitTime {
                break
            }
            try await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    private func disableProfile(_ manager: NEVPNManager) async throws {
        if manager.protocolConfiguration?.includeAllNetworks == true || manager.isEnabled || manager.isOnDemandEnabled {
            manager.isEnabled = false
            manager.isOnDemandEnabled = false
            manager.protocolConfiguration?.includeAllNetworks = false
            try await manager.saveToPreferences()
            try await manager.loadFromPreferences()
        }
    }
}
