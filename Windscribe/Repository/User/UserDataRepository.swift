//
//  UserDataRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-29.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject

protocol UserDataRepository {
    func prepareUserData() -> Single<Void>
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
    private let disposeBag = DisposeBag()

    init(serverRepository: ServerRepository, credentialsRepository: CredentialsRepository, portMapRepository: PortMapRepository, latencyRepository: LatencyRepository, staticIpRepository: StaticIpRepository, notificationsRepository: NotificationRepository, logger: FileLogger) {
        self.serverRepository = serverRepository
        self.credentialsRepository = credentialsRepository
        self.portMapRepository = portMapRepository
        self.latencyRepository = latencyRepository
        self.staticIpRepository = staticIpRepository
        self.notificationsRepository = notificationsRepository
        self.logger = logger
    }

    func prepareUserData() -> Single<Void> {
        logger.logD(UserDataRepositoryImpl.self, "Getting server list.")
        return serverRepository.getUpdatedServers().flatMap { servers in
            DispatchQueue.main.async {
                self.latencyRepository.pickBestLocation(servers: servers)
            }
            self.logger.logD(UserDataRepositoryImpl.self, "Getting iKEv2 credentials.")
            return self.credentialsRepository.getUpdatedIKEv2Crendentials().catchAndReturn(nil)
        }.flatMap { _ in
            self.logger.logD(UserDataRepositoryImpl.self, "Getting OpenVPN Server config.")
            return self.credentialsRepository.getUpdatedServerConfig()
        }.flatMap { _ in
            self.logger.logD(UserDataRepositoryImpl.self, "Getting OpenVPN crendentials.")
            return self.credentialsRepository.getUpdatedOpenVPNCrendentials().catchAndReturn(nil)
        }.flatMap { _ in
            self.logger.logD(UserDataRepositoryImpl.self, "Getting PortMap.")
            return self.portMapRepository.getUpdatedPortMap()
        }.flatMap { _ in
            self.logger.logD(UserDataRepositoryImpl.self, "Getting PortMap.")
            return self.staticIpRepository.getStaticServers().catchAndReturn([])
        }.flatMap { _ in
            self.logger.logD(UserDataRepositoryImpl.self, "Getting Notifications.")
            return self.notificationsRepository.getUpdatedNotifications(pcpid: "").catchAndReturn([])
        }.map { _ in
            DispatchQueue.main.async {
                self.latencyRepository.loadLatency()
            }
        }
    }
}
