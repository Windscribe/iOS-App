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
        container.register(APIUtilService.self) { _ in
            APIUtilServiceImpl()
        }.inObjectScope(.userScope)
        container.register(ConnectivityManager.self) { r in
            ConnectivityManagerImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(APIManager.self) { r in
            APIManagerImpl(api: r.resolve(WSNetServerAPI.self)!, logger: r.resolve(FileLogger.self)!, apiUtil: r.resolve(APIUtilService.self)!)
        }.initCompleted { r, apiManager in
            // Note: Api manager and user repository both have circular dependency on each other.
            (apiManager as? APIManagerImpl)?.userRepository = r.resolve(UserRepository.self)
        }.inObjectScope(.userScope)
        container.register(WireguardAPIManager.self) { r in
            WireguardAPIManagerImpl(api: r.resolve(WSNetServerAPI.self)!, preferences: r.resolve(Preferences.self)!, apiUtil: r.resolve(APIUtilService.self)!)
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
            NotificationRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger, pushNotificationsManager: r.resolve(PushNotificationManager.self)!)
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
            SecuredNetworkRepositoryImpl(preferences: r.resolve(Preferences.self)!, localdatabase: r.resolve(LocalDatabase.self)!, connectivity: r.resolve(ConnectivityManager.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(LatencyRepository.self) { r in
            LatencyRepositoryImpl(pingManager: WSNet.instance().pingManager(),
                                  database: r.resolve(LocalDatabase.self)!,
                                  vpnManager: r.resolve(VPNManager.self)!,
                                  logger: logger,
                                  locationsManager: r.resolve(LocationsManager.self)!,
                                  preferences: r.resolve(Preferences.self)!,
                                  advanceRepository: r.resolve(AdvanceRepository.self)!)
        }.inObjectScope(.container)
        container.register(EmergencyRepository.self) { r in
            EmergencyRepositoryImpl(wsnetEmergencyConnect: WSNet.instance().emergencyConnect(), vpnManager: r.resolve(VPNManager.self)!, fileDatabase: r.resolve(FileDatabase.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: r.resolve(FileLogger.self)!, locationsManager: r.resolve(LocationsManager.self)!, protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.userScope)
        container.register(CustomConfigRepository.self) { r in
            CustomConfigRepositoryImpl(fileDatabase: r.resolve(FileDatabase.self)!, localDatabase: r.resolve(LocalDatabase.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(AdvanceRepository.self) { r in
            AdvanceRepositoryImpl(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(ShakeDataRepository.self) { r in
            ShakeDataRepositoryImpl(apiManager: r.resolve(APIManager.self)!,
                                    sessionManager: r.resolve(SessionManager.self)!)
        }.inObjectScope(.userScope)
        container.register(ConfigurationsManager.self) { r in
            ConfigurationsManager(logger: r.resolve(FileLogger.self)!,
                                  localDatabase: r.resolve(LocalDatabase.self)!,
                                  keychainDb: r.resolve(KeyChainDatabase.self)!,
                                  fileDatabase: r.resolve(FileDatabase.self)!,
                                  advanceRepository: r.resolve(AdvanceRepository.self)!,
                                  wgRepository: r.resolve(WireguardConfigRepository.self)!,
                                  wgCredentials: r.resolve(WgCredentials.self)!,
                                  preferences: r.resolve(Preferences.self)!,
                                  locationsManager: r.resolve(LocationsManager.self)!,
                                  ipRepository: r.resolve(IPRepository.self)!)
        }.inObjectScope(.userScope)

        container.register(LookAndFeelRepositoryType.self) { r in
            LookAndFeelRepository(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Managers

class Managers: Assembly {
    func assemble(container: Container) {
        container.register(InAppPurchaseManager.self) { r in
            InAppPurchaseManagerImpl(apiManager: r.resolve(APIManager.self)!, preferences: r.resolve(Preferences.self)!, logger: r.resolve(FileLogger.self)!, localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.userScope)

        container.register(ModernInAppPurchaseManager.self) { r in
            InAppPurchaseManagerImpl(
                apiManager: r.resolve(APIManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.userScope)

        container.register(HTMLParsing.self) { r in
            HTMLParser(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)

        container.register(DNSSettingsManagerType.self) { r in
            DNSSettingsManager()
        }.inObjectScope(.userScope)

        container.register(SoundManaging.self) { r in
            SoundManager(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(SoundFileManaging.self) { r in
            SoundFileManager(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(BackgroundFileManaging.self) { r in
            BackgroundFileManager(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(CustomSoundPlaybackManaging.self) { r in
            CustomSoundPlaybackManager(
                preferences: r.resolve(Preferences.self)!,
                soundManager: r.resolve(SoundManaging.self)!)
        }.inObjectScope(.userScope)
        container.register(HTMLParsing.self) { r in
            HTMLParser(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(SessionManager.self) { _ in
            SessionManagerImpl()
        }.inObjectScope(.userScope)
#if os(iOS)
        container.register(HapticFeedbackManager.self) { r in
            HapticFeedbackManagerImpl(preferences: r.resolve(Preferences.self)!,
                                      logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
#endif
        container.register(AlertManagerV2.self) { _ in
            AlertManager()
        }.inObjectScope(.userScope)
        container.register(LocationsManager.self) { r in
            LocationsManagerImpl(localDatabase: r.resolve(LocalDatabase.self)!,
                                 preferences: r.resolve(Preferences.self)!,
                                 logger: r.resolve(FileLogger.self)!,
                                 languageManager: r.resolve(LanguageManager.self)!,
                                 serverRepository: r.resolve(ServerRepository.self)!)
        }.inObjectScope(.userScope)
        container.register(VPNManager.self) { r in
            VPNManager(logger: r.resolve(FileLogger.self)!,
                       localDB: r.resolve(LocalDatabase.self)!,
                       serverRepository: r.resolve(ServerRepository.self)!,
                       staticIpRepository: r.resolve(StaticIpRepository.self)!,
                       preferences: r.resolve(Preferences.self)!,
                       connectivity: r.resolve(ConnectivityManager.self)!,
                       configManager: r.resolve(ConfigurationsManager.self)!,
                       alertManager: r.resolve(AlertManagerV2.self)!,
                       locationsManager: r.resolve(LocationsManager.self)!)
        }.inObjectScope(.userScope)
        container.register(ReferAndShareManager.self) { r in
            ReferAndShareManagerImpl(
                preferences: r.resolve(Preferences.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(LocalizationService.self) { r in
            LocalizationServiceImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(LanguageManager.self) { r in
            let prefs = r.resolve(Preferences.self)!
            let localizer = r.resolve(LocalizationService.self)!
            LocalizationBridge.setup(localizer)
            return LanguageManagerImpl(preference: prefs, localizationService: localizer)
        }.inObjectScope(.userScope)
        container.register(PushNotificationManager.self) { r in
            PushNotificationManagerImpl(vpnManager: r.resolve(VPNManager.self)!, session: r.resolve(SessionManager.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(ProtocolManagerType.self) { r in
            ProtocolManager(logger: r.resolve(FileLogger.self)!, connectivity: r.resolve(ConnectivityManager.self)!, preferences: r.resolve(Preferences.self)!, securedNetwork: r.resolve(SecuredNetworkRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!, locationManager: r.resolve(LocationsManager.self)!)
        }.inObjectScope(.userScope)

        container.register(LivecycleManagerType.self) { r in
            LivecycleManager(logger: r.resolve(FileLogger.self)!,
                             sessionManager: r.resolve(SessionManager.self)!,
                             preferences: r.resolve(Preferences.self)!,
                             vpnManager: r.resolve(VPNManager.self)!,
                             connectivity: r.resolve(ConnectivityManager.self)!,
                             credentialsRepo: r.resolve(CredentialsRepository.self)!,
                             notificationRepo: r.resolve(NotificationRepository.self)!,
                             ipRepository: r.resolve(IPRepository.self)!,
                             configManager: r.resolve(ConfigurationsManager.self)!,
                             connectivityManager: r.resolve(ProtocolManagerType.self)!,
                             locationsManager: r.resolve(LocationsManager.self)!)
        }.inObjectScope(.userScope)

        container.register(SSOManaging.self) { r in
            SSOManager(logger: r.resolve(FileLogger.self)!,
                       apiManager: r.resolve(APIManager.self )!)
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
