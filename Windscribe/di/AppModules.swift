//
//  AppModules.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-01-30.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import RxSwift
import Swinject

// MARK: - App

class App: Assembly {
    func assemble(container: Swinject.Container) {
        container.register(WgCredentials.self) { r in
            WgCredentials(preferences: r.resolve(Preferences.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(WireguardConfigRepository.self) { r in
            WireguardConfigRepositoryImpl(apiCallManager: r.resolve(WireguardAPIManager.self)!, fileDatabase: r.resolve(FileDatabase.self)!, wgCrendentials: r.resolve(WgCredentials.self)!, alertManager: r.resolve(AlertManagerV2.self), logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Network

class Network: Assembly {
    func assemble(container: Swinject.Container) {
        container.injectCore()
        container.register(Connectivity.self) { r in
            ConnectivityImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(APIManager.self) { r in
            APIManagerImpl(api: r.resolve(WSNetServerAPI.self)!, logger: r.resolve(FileLogger.self)!)
        }.initCompleted { r, apiManager in
            // Note: Api manager and user repository both have circular dependency on each other.
            (apiManager as? APIManagerImpl)?.userRepository = r.resolve(UserRepository.self)
        }.inObjectScope(.userScope)
        container.register(WireguardAPIManager.self) { r in
            WireguardAPIManagerImpl(api: r.resolve(WSNetServerAPI.self)!, preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Repository

class Repository: Assembly {
    func assemble(container: Container) {
        let logger = container.resolve(FileLogger.self)!
        container.register(UserRepository.self) { r in
            UserRepositoryImpl(preferences: r.resolve(Preferences.self)!, apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, wgCredentials: r.resolve(WgCredentials.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(UserDataRepository.self) { r in
            UserDataRepositoryImpl(serverRepository: r.resolve(ServerRepository.self)!, credentialsRepository: r.resolve(CredentialsRepository.self)!, portMapRepository: r.resolve(PortMapRepository.self)!, latencyRepository: r.resolve(LatencyRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!, notificationsRepository: r.resolve(NotificationRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(IPRepository.self) { r in
            IPRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(BillingRepository.self) { r in
            BillingRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(NotificationRepository.self) { r in
            NotificationRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger, pushNotificationsManager: r.resolve(PushNotificationManagerV2.self)!)
        }.inObjectScope(.userScope)
        container.register(StaticIpRepository.self) { r in
            StaticIpRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(ServerRepository.self) { r in
            ServerRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, userRepository: r.resolve(UserRepository.self)!, preferences: r.resolve(Preferences.self)!, advanceRepository: r.resolve(AdvanceRepository.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(CredentialsRepository.self) { r in
            CredentialsRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, fileDatabase: r.resolve(FileDatabase.self)!, vpnManager: r.resolve(VPNManager.self)!, wifiManager: WifiManager.shared, preferences: r.resolve(Preferences.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(PortMapRepository.self) { r in
            PortMapRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(SecuredNetworkRepository.self) { r in
            SecuredNetworkRepositoryImpl(preferences: r.resolve(Preferences.self)!, localdatabase: r.resolve(LocalDatabase.self)!, connectivity: r.resolve(Connectivity.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(LatencyRepository.self) { r in
            LatencyRepositoryImpl(pingManager: WSNet.instance().pingManager(), database: r.resolve(LocalDatabase.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: logger, preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.container)
        container.register(EmergencyRepository.self) { r in
            EmergencyRepositoryImpl(wsnetEmergencyConnect: WSNet.instance().emergencyConnect(), vpnManager: r.resolve(VPNManager.self)!, fileDatabase: r.resolve(FileDatabase.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(CustomConfigRepository.self) { r in
            CustomConfigRepositoryImpl(fileDatabase: r.resolve(FileDatabase.self)!, localDatabase: r.resolve(LocalDatabase.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(AdvanceRepository.self) { r in
            AdvanceRepositoryImpl(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(ShakeDataRepository.self) { r in
            ShakeDataRepositoryImpl(apiManager: r.resolve(APIManager.self)!,
                                    sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.userScope)
        container.register(ConfigurationsManager.self) { r in
            ConfigurationsManager(logger: r.resolve(FileLogger.self)!, localDatabase: r.resolve(LocalDatabase.self)!, keychainDb: r.resolve(KeyChainDatabase.self)!, fileDatabase: r.resolve(FileDatabase.self)!, advanceRepository: r.resolve(AdvanceRepository.self)!, wgRepository: r.resolve(WireguardConfigRepository.self)!, wgCredentials: r.resolve(WgCredentials.self)!, preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Managers

class Managers: Assembly {
    func assemble(container: Container) {
        container.register(InAppPurchaseManager.self) { r in
            InAppPurchaseManagerImpl(apiManager: r.resolve(APIManager.self)!, preferences: r.resolve(Preferences.self)!, logger: r.resolve(FileLogger.self)!, localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.userScope)
        container.register(SessionManagerV2.self) { _ in
            SessionManager()
        }.inObjectScope(.userScope)
        #if os(iOS)
            container.register(HapticFeedbackGeneratorV2.self) { r in
                HapticFeedbackGenerator(preference: r.resolve(Preferences.self)!)
            }.inObjectScope(.userScope)
        #endif
        container.register(AlertManagerV2.self) { _ in
            AlertManager()
        }.inObjectScope(.userScope)
        container.register(LocationsManagerType.self) { r in
            LocationsManager(localDatabase: r.resolve(LocalDatabase.self)!, preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(VPNManager.self) { r in
            VPNManager(wgCrendentials: r.resolve(WgCredentials.self)!,
                       wgRepository: r.resolve(WireguardConfigRepository.self)!,
                       api: r.resolve(APIManager.self)!,
                       logger: r.resolve(FileLogger.self)!,
                       localDB: r.resolve(LocalDatabase.self)!,
                       serverRepository: r.resolve(ServerRepository.self)!,
                       staticIpRepository: r.resolve(StaticIpRepository.self)!,
                       preferences: r.resolve(Preferences.self)!,
                       connectivity: r.resolve(Connectivity.self)!,
                       configManager: r.resolve(ConfigurationsManager.self)!,
                       connectionManager: r.resolve(ConnectionManagerV2.self)!,
                       alertManager: r.resolve(AlertManagerV2.self)!)
        }.inObjectScope(.userScope)
        container.register(ReferAndShareManagerV2.self) { r in
            ReferAndShareManager(preferences: r.resolve(Preferences.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(ThemeManager.self) { r in
            ThemeManagerImpl(preference: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(LanguageManagerV2.self) { r in
            LanguageManager(preference: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(PushNotificationManagerV2.self) { r in
            PushNotificationManagerV2Impl(vpnManager: r.resolve(VPNManager.self)!, session: r.resolve(SessionManagerV2.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(ConnectionManagerV2.self) { r in
            ConnectionManager(logger: r.resolve(FileLogger.self)!, connectivity: r.resolve(Connectivity.self)!, preferences: r.resolve(Preferences.self)!, securedNetwork: r.resolve(SecuredNetworkRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.userScope)
        container.register(ConnectionStateManagerType.self) { r in
            ConnectionStateManager(apiManager: r.resolve(APIManager.self)!, vpnManager: r.resolve(VPNManager.self)!,
                                   securedNetwork: r.resolve(SecuredNetworkRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!,
                                   latencyRepository: r.resolve(LatencyRepository.self)!,
                                   logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)

        container.register(LivecycleManagerType.self) { r in
            LivecycleManager(logger: r.resolve(FileLogger.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, preferences: r.resolve(Preferences.self)!, vpnManager: r.resolve(VPNManager.self)!, connectivity: r.resolve(Connectivity.self)!, credentialsRepo: r.resolve(CredentialsRepository.self)!, notificationRepo: r.resolve(NotificationRepository.self)!, ipRepository: r.resolve(IPRepository.self)!, configManager: r.resolve(ConfigurationsManager.self)!, conenctivityManager: r.resolve(ConnectionManagerV2.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Database

class Database: Assembly {
    // Remove this singleton in future
    func assemble(container: Container) {
        container.register(LocalDatabase.self) { r in
            LocalDatabaseImpl(logger: r.resolve(FileLogger.self)!, preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(KeyChainDatabase.self) { r in
            KeyChainDatabaseImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
    }
}
