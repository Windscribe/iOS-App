//
//  UserDataRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-29.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import Combine

protocol UserDataRepository {
    func prepareUserData() async throws
}

class UserDataRepositoryImpl: UserDataRepository {
    private let serverRepository: ServerRepository
    private let credentialsRepository: CredentialsRepository
    private let portMapRepository: PortMapRepository
    private let latencyRepository: LatencyRepository
    private let staticIpRepository: StaticIpRepository
    private let notificationsRepository: NotificationRepository
    private var emergencyRepository: EmergencyRepository {
        return Assembler.resolve(EmergencyRepository.self)
    }

    private let logger: FileLogger

    init(serverRepository: ServerRepository, credentialsRepository: CredentialsRepository, portMapRepository: PortMapRepository, latencyRepository: LatencyRepository, staticIpRepository: StaticIpRepository, notificationsRepository: NotificationRepository, logger: FileLogger) {
        self.serverRepository = serverRepository
        self.credentialsRepository = credentialsRepository
        self.portMapRepository = portMapRepository
        self.latencyRepository = latencyRepository
        self.staticIpRepository = staticIpRepository
        self.notificationsRepository = notificationsRepository
        self.logger = logger
    }

    func prepareUserData() async throws {
        logger.logI("UserDataRepository", "Getting server list.")
        try await serverRepository.updatedServers()

        // Pick initial best location based on timezone
        latencyRepository.pickBestLocation()

        // Quick ping 10 nearby servers to correct best location with real latency data
        if !self.emergencyRepository.isConnected() {
            logger.logI("UserDataRepository", "Quick ping 10 nearby servers for best location correction.")
            try? await latencyRepository.loadQuickLatency()
        }

        // Load all remaining data in parallel - all independent calls
        logger.logI("UserDataRepository", "Loading credentials, PortMap, Static IPs, and Notifications in parallel.")

        // Non-critical calls that may fail for expired/free accounts - wrap in Task to catch errors
        let ikev2Task = Task {
            do {
                try await credentialsRepository.getUpdatedIKEv2Crendentials()
            } catch {
                logger.logE("UserDataRepository", "IKEv2 credentials failed (non-critical, may fail for expired/free accounts): \(error)")
            }
        }

        let openVPNTask = Task {
            do {
                try await credentialsRepository.getUpdatedOpenVPNCrendentials()
            } catch {
                logger.logE("UserDataRepository", "OpenVPN credentials failed (non-critical, may fail for expired/free accounts): \(error)")
            }
        }

        let staticIPTask = Task {
            do {
                try await staticIpRepository.updateStaticServers()
            } catch {
                logger.logE("UserDataRepository", "Static IPs failed (non-critical, may fail for free accounts): \(error)")
            }
        }

        // Critical calls that should always succeed
        async let serverConfig = credentialsRepository.getUpdatedServerConfig()
        async let portMap = portMapRepository.getUpdatedPortMap()
        async let notifications = notificationsRepository.getUpdatedNotifications()

        // Wait for critical calls (all started in parallel above)
        _ = try await (serverConfig, portMap, notifications)

        // Wait for non-critical tasks (errors already caught)
        await ikev2Task.value
        await openVPNTask.value
        await staticIPTask.value

        logger.logI("UserDataRepository", "Data loading complete.")

        // Load latency in background - don't block navigation
        if !self.emergencyRepository.isConnected() {
            Task.detached { [weak self] in
                guard let self = self else { return }
                self.logger.logI("UserDataRepository", "Loading latency in background.")
                try? await self.latencyRepository.loadLatency()
                self.logger.logI("UserDataRepository", "Latency loading complete.")

                // Notify UI to reload table with new ping times
                await MainActor.run {
                    NotificationCenter.default.post(name: Notifications.reloadTableViews, object: nil)
                }
            }
        }
    }
}
