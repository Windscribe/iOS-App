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

        latencyRepository.pickBestLocation()
        logger.logD("UserDataRepository", "Getting iKEv2 credentials.")
        try await credentialsRepository.getUpdatedIKEv2Crendentials()

        logger.logI("UserDataRepository", "Getting OpenVPN Server config.")
        try await credentialsRepository.getUpdatedServerConfig()

        logger.logI("UserDataRepository", "Getting OpenVPN crendentials.")
        try await credentialsRepository.getUpdatedOpenVPNCrendentials()

        logger.logI("UserDataRepository", "Getting PortMap.")
        _ = try await portMapRepository.getUpdatedPortMap()

        logger.logI("UserDataRepository", "Getting Static IPs.")
        try await staticIpRepository.updateStaticServers()

        logger.logI("UserDataRepository", "Getting Notifications.")
        _ = try await notificationsRepository.getUpdatedNotifications()

        if !self.emergencyRepository.isConnected() {
            try? await self.latencyRepository.loadLatency()
        }
    }
}
