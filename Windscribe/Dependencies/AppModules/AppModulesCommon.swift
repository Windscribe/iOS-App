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
            WgCredentials(
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!,
                keychainManager: r.resolve(KeychainManager.self)!
            )
        }.inObjectScope(.userScope)
        container.register(WireguardIPManager.self) { r in
            WireguardIPManagerImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(WireguardConfigRepository.self) { r in
            WireguardConfigRepositoryImpl(
                apiCallManager: r.resolve(WireguardAPIManager.self)!,
                fileDatabase: r.resolve(FileDatabase.self)!,
                wgCrendentials: r.resolve(WgCredentials.self)!,
                alertManager: r.resolve(AlertManager.self),
                logger: r.resolve(FileLogger.self)!,
                ipManager: r.resolve(WireguardIPManager.self)!,
                preferences: r.resolve(Preferences.self)!
            )
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
            ConnectivityManagerImpl(logger: r.resolve(FileLogger.self)!,
                                    bridgeAPI: r.resolve(WSNetBridgeAPIType.self)!)
        }.inObjectScope(.userScope)
        container.register((any DeviceAttesting).self) { _ in
            DCDeviceAttestation()
        }.inObjectScope(.container)
        container.register(APIManager.self) { r in
            APIManagerImpl(api: r.resolve(WSNetServerAPIType.self)!,
                           bridgeApi: r.resolve(WSNetBridgeAPIType.self)!,
                           logger: r.resolve(FileLogger.self)!,
                           apiUtil: r.resolve(APIUtilService.self)!,
                           preferences: r.resolve(Preferences.self)!,
                           deviceAttesting: r.resolve((any DeviceAttesting).self)!)
        }.initCompleted { r, apiManager in
            // Note: Api manager and user repository both have circular dependency on each other.
            (apiManager as? APIManagerImpl)?.userSessionRepository = r.resolve(UserSessionRepository.self)
        }.inObjectScope(.userScope)
        container.register(WireguardAPIManager.self) { r in
            WireguardAPIManagerImpl(api: r.resolve(WSNetServerAPIType.self)!, preferences: r.resolve(Preferences.self)!, apiUtil: r.resolve(APIUtilService.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Repository

class Repository: Assembly {
    func assemble(container: Container) {
        let logger = container.resolve(FileLogger.self)!
        container.register(SessionKeychainStore.self) { r in
            SessionKeychainStoreImpl(
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.userScope)

        container.register(UserSessionRepository.self) { r in
            UserSessionRepositoryImpl(preferences: r.resolve(Preferences.self)!,
                                      localDatabase: r.resolve(LocalDatabase.self)!,
                                      sessionStore: r.resolve(SessionKeychainStore.self)!,
                                      locationListRepository: r.resolve(LocationListRepository.self)!,
                                      antiCensorshipRepository: r.resolve(AntiCensorshipRepository.self)!)
        }.inObjectScope(.userScope)

        container.register(BridgeApiRepository.self) { r in
            BridgeApiRepositoryImpl(bridgeAPI: r.resolve(WSNetBridgeAPIType.self)!,
                                    locationManager: r.resolve(LocationsManager.self)!,
                                    userSessionRepository: r.resolve(UserSessionRepository.self)!,
                                    vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                    logger: r.resolve(FileLogger.self)!,
                                    protocolManager: r.resolve(ProtocolManagerType.self)!,
                                    preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)

        container.register(UserDataRepository.self) { r in
            UserDataRepositoryImpl(credentialsRepository: r.resolve(CredentialsRepository.self)!,
                                   portMapRepository: r.resolve(PortMapRepository.self)!,
                                   latencyRepository: r.resolve(LatencyRepository.self)!,
                                   staticIpRepository: r.resolve(StaticIpRepository.self)!,
                                   notificationsRepository: r.resolve(NotificationRepository.self)!,
                                   emergencyRepository: r.resolve(EmergencyRepository.self)!,
                                   logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(IPRepository.self) { r in
            IPRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, preferences: r.resolve(Preferences.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(MobilePlanRepository.self) { r in
            MobilePlanRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: logger)
        }.inObjectScope(.userScope)
        container.register(NotificationRepository.self) { r in
            NotificationRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger, pushNotificationsManager: r.resolve(PushNotificationManager.self)!)
        }.inObjectScope(.userScope)
        container.register(CheckUpdateRepository.self) { r in
            CheckUpdateRepositoryImpl(apiManager: r.resolve(APIManager.self)!,
                                      preferences: r.resolve(Preferences.self)!,
                                      logger: logger)
        }.inObjectScope(.userScope)
        container.register(StaticIpRepository.self) { r in
            StaticIpRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(WifiManager.self) { _ in
            WifiManagerImpl()
        }.inObjectScope(.container)
        container.register(CredentialsRepository.self) { r in
            CredentialsRepositoryImpl(apiManager: r.resolve(APIManager.self)!,
                                      localDatabase: r.resolve(LocalDatabase.self)!,
                                      fileDatabase: r.resolve(FileDatabase.self)!,
                                      vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                      wifiManager: r.resolve(WifiManager.self)!,
                                      preferences: r.resolve(Preferences.self)!,
                                      userSessionRepository: r.resolve(UserSessionRepository.self)!,
                                      logger: logger)
        }.inObjectScope(.userScope)
        container.register(PortMapRepository.self) { r in
            PortMapRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(WifiNetworkRepository.self) { r in
            WifiNetworkRepositoryImpl(preferences: r.resolve(Preferences.self)!,
                                         localDatabase: r.resolve(LocalDatabase.self)!,
                                         connectivity: r.resolve(ConnectivityManager.self)!,
                                         logger: logger)
        }.inObjectScope(.userScope)
        container.register(LatencyRepository.self) { r in
            LatencyRepositoryImpl(pingManager: r.resolve(LocalPingManager.self)!,
                                  database: r.resolve(LocalDatabase.self)!,
                                  vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                  logger: logger,
                                  locationsManager: r.resolve(LocationsManager.self)!,
                                  preferences: r.resolve(Preferences.self)!,
                                  advanceRepository: r.resolve(AdvanceRepository.self)!,
                                  userSessionRepository: r.resolve(UserSessionRepository.self)!,
                                  staticIpRepository: r.resolve(StaticIpRepository.self)!,
                                  locationListRepository: r.resolve(LocationListRepository.self)!)
        }.inObjectScope(.container)

        container.register(EmergencyRepository.self) { r in
            EmergencyRepositoryImpl(wsnetEmergencyConnect: WSNet.instance().emergencyConnect(),
                                    vpnManager: r.resolve(VPNManager.self)!,
                                    vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                    fileDatabase: r.resolve(FileDatabase.self)!,
                                    logger: r.resolve(FileLogger.self)!,
                                    locationsManager: r.resolve(LocationsManager.self)!,
                                    protocolManager: r.resolve(ProtocolManagerType.self)!,
                                    customConfigRepository: r.resolve(CustomConfigRepository.self)!)
        }.inObjectScope(.userScope)
        container.register(CustomConfigRepository.self) { r in
            CustomConfigRepositoryImpl(fileDatabase: r.resolve(FileDatabase.self)!,
                                       localDatabase: r.resolve(LocalDatabase.self)!,
                                       logger: r.resolve(FileLogger.self)!,
                                       portMapRepository: r.resolve(PortMapRepository.self)!,
                                       preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(AdvanceRepository.self) { r in
            AdvanceRepositoryImpl(preferences: r.resolve(Preferences.self)!,
                                  vpnStateRepository: r.resolve(VPNStateRepository.self)!)
        }.inObjectScope(.userScope)
        container.register(ShakeDataRepository.self) { r in
            ShakeDataRepositoryImpl(apiManager: r.resolve(APIManager.self)!,
                                    userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.userScope)
        container.register(ConfigurationsManager.self) { r in
            ConfigurationsManager(logger: r.resolve(FileLogger.self)!,
                                  keychainDb: r.resolve(KeyChainDatabase.self)!,
                                  fileDatabase: r.resolve(FileDatabase.self)!,
                                  advanceRepository: r.resolve(AdvanceRepository.self)!,
                                  wgRepository: r.resolve(WireguardConfigRepository.self)!,
                                  wgCredentials: r.resolve(WgCredentials.self)!,
                                  preferences: r.resolve(Preferences.self)!,
                                  locationsManager: r.resolve(LocationsManager.self)!,
                                  ipRepository: r.resolve(IPRepository.self)!,
                                  userSessionRepository: r.resolve(UserSessionRepository.self)!,
                                  locationListRepository: r.resolve(LocationListRepository.self)!,
                                  bridgeAPI: r.resolve(WSNetBridgeAPIType.self)!,
                                  bridgeApiRepository: r.resolve(BridgeApiRepository.self)!,
                                  credentialsRepository: r.resolve(CredentialsRepository.self)!,
                                  staticIpRepository: r.resolve(StaticIpRepository.self)!,
                                  customConfigRepository: r.resolve(CustomConfigRepository.self)!,
                                  antiCensorshipRepository: r.resolve(AntiCensorshipRepository.self)!)
        }.inObjectScope(.userScope)

        container.register(LookAndFeelRepositoryType.self) { r in
            LookAndFeelRepository(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)

        container.register(RobertyFiltersRepository.self) { r in
            RobertyFiltersRepositoryImpl(logger: r.resolve(FileLogger.self)!,
                                         apiManager: r.resolve(APIManager.self)!,
                                         localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.userScope)

        container.register(MigrationRepository.self) { r in
            MigrationRepositoryImpl(
                preferences: r.resolve(Preferences.self)!,
                keychainManager: r.resolve(KeychainManager.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.userScope)

        container.register(AntiCensorshipRepository.self) { r in
            AntiCensorshipRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                logger: r.resolve(FileLogger.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                preferences: r.resolve(Preferences.self)!,
            )
        }.inObjectScope(.userScope)

        container.register(LocationListRepository.self) { r in
            LocationListRepositoryImpl(apiManager: r.resolve(APIManager.self)!,
                                       localDatabase: r.resolve(LocalDatabase.self)!,
                                       logger: r.resolve(FileLogger.self)!,
                                       antiCensorshipRepository:  r.resolve(AntiCensorshipRepository.self)!,
                                       preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Managers

class Managers: Assembly {
    func assemble(container: Container) {
        container.register(WindowProvider.self) { _ in
            WindowProviderImpl()
        }.inObjectScope(.container)

        container.register(SceneLifecycleHandler.self) { r in
            SceneLifecycleHandlerImpl(
                logger: r.resolve(FileLogger.self)!,
                preferences: r.resolve(Preferences.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                lifecycleManager: r.resolve(LifecycleManagerType.self)!,
                pushNotificationManager: r.resolve(PushNotificationManager.self)!)
        }.inObjectScope(.container)

        container.register(InAppPurchaseManager.self) { r in
            InAppPurchaseManagerImpl(apiManager: r.resolve(APIManager.self)!,
                                     preferences: r.resolve(Preferences.self)!,
                                     logger: r.resolve(FileLogger.self)!,
                                     mobilePlanRepository: r.resolve(MobilePlanRepository.self)!,
                                     sessionManager: r.resolve(SessionManager.self)!)
        }.inObjectScope(.userScope)

        container.register(ModernInAppPurchaseManager.self) { r in
            InAppPurchaseManagerImpl(
                apiManager: r.resolve(APIManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!,
                mobilePlanRepository: r.resolve(MobilePlanRepository.self)!,
                sessionManager: r.resolve(SessionManager.self)!)
        }.inObjectScope(.userScope)

        container.register(HTMLParsing.self) { r in
            HTMLParser(logger: r.resolve(FileLogger.self)!)
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
        container.register(SessionManager.self) { r in
            SessionManagerImpl(wgCredentials: r.resolve(WgCredentials.self)!,
                               logger: r.resolve(FileLogger.self)!,
                               apiManager: r.resolve(APIManager.self)!,
                               credentialsRepo: r.resolve(CredentialsRepository.self)!,
                               staticIPRepo: r.resolve(StaticIpRepository.self)!,
                               portmapRepo: r.resolve(PortMapRepository.self)!,
                               preferences: r.resolve(Preferences.self)!,
                               latencyRepo: r.resolve(LatencyRepository.self)!,
                               userSessionRepository: r.resolve(UserSessionRepository.self)!,
                               locationsManager: r.resolve(LocationsManager.self)!,
                               vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                               vpnManager: r.resolve(VPNManager.self)!,
                               ssoManager: r.resolve(SSOManaging.self)!,
                               antiCensorshipRepository: r.resolve(AntiCensorshipRepository.self)!,
                               locationListRepository: r.resolve(LocationListRepository.self)!,
                               windowProvider: r.resolve(WindowProvider.self)!)
        }.inObjectScope(.userScope)
        container.register(HapticFeedbackManager.self) { r in
            HapticFeedbackManagerImpl(
                preferences: r.resolve(Preferences.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.userScope)
        container.register(AlertManager.self) { _ in
            AlertManagerImpl()
        }.inObjectScope(.userScope)
        container.register(LocationsManager.self) { r in
            LocationsManagerImpl(customConfigRepository: r.resolve(CustomConfigRepository.self)!,
                                 preferences: r.resolve(Preferences.self)!,
                                 logger: r.resolve(FileLogger.self)!,
                                 languageManager: r.resolve(LanguageManager.self)!,
                                 userSessionRepository: r.resolve(UserSessionRepository.self)!,
                                 locationListRepository: r.resolve(LocationListRepository.self)!,
                                 staticIpRepository: r.resolve(StaticIpRepository.self)!)
        }.inObjectScope(.userScope)
        container.register(VPNStateRepository.self) { r in
            VPNStateRepositoryImpl(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(VPNManager.self) { r in
            VPNManagerImpl(logger: r.resolve(FileLogger.self)!,
                           staticIpRepository: r.resolve(StaticIpRepository.self)!,
                           preferences: r.resolve(Preferences.self)!,
                           connectivity: r.resolve(ConnectivityManager.self)!,
                           configManager: r.resolve(ConfigurationsManager.self)!,
                           alertManager: r.resolve(AlertManager.self)!,
                           locationsManager: r.resolve(LocationsManager.self)!,
                           vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                           wifiNetworkRepository: r.resolve(WifiNetworkRepository.self)!,
                           bridgeAPI: r.resolve(WSNetBridgeAPIType.self)!,
                           userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.userScope)
        container.register(ReferAndShareManager.self) { r in
            ReferAndShareManagerImpl(
                preferences: r.resolve(Preferences.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
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
            PushNotificationManagerImpl(vpnManager: r.resolve(VPNManager.self)!,
                                        sessionManager: r.resolve(SessionManager.self)!,
                                        logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(ProtocolManagerType.self) { r in
            ProtocolManager(logger: r.resolve(FileLogger.self)!,
                            connectivity: r.resolve(ConnectivityManager.self)!,
                            preferences: r.resolve(Preferences.self)!,
                            securedNetwork: r.resolve(WifiNetworkRepository.self)!,
                            customConfigRepository: r.resolve(CustomConfigRepository.self)!,
                            locationManager: r.resolve(LocationsManager.self)!,
                            portMapRepository: r.resolve(PortMapRepository.self)!,
                            vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                            wifiManager: r.resolve(WifiManager.self)!)
        }.inObjectScope(.userScope)

        container.register(LifecycleManagerType.self) { r in
            LifecycleManager(logger: r.resolve(FileLogger.self)!,
                             sessionManager: r.resolve(SessionManager.self)!,
                             preferences: r.resolve(Preferences.self)!,
                             vpnManager: r.resolve(VPNManager.self)!,
                             vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                             connectivity: r.resolve(ConnectivityManager.self)!,
                             credentialsRepo: r.resolve(CredentialsRepository.self)!,
                             notificationRepo: r.resolve(NotificationRepository.self)!,
                             ipRepository: r.resolve(IPRepository.self)!,
                             configManager: r.resolve(ConfigurationsManager.self)!,
                             connectivityManager: r.resolve(ProtocolManagerType.self)!,
                             locationsManager: r.resolve(LocationsManager.self)!,
                             antiCensorshipRepository: r.resolve(AntiCensorshipRepository.self)!,
                             wifiManager: r.resolve(WifiManager.self)!,
                             locationListRepository: r.resolve(LocationListRepository.self)!,
                             windowProvider: r.resolve(WindowProvider.self)!,
                             checkUpdateRepository: r.resolve(CheckUpdateRepository.self)!,
                             userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.userScope)

        container.register(SSOManaging.self) { r in
            SSOManager(logger: r.resolve(FileLogger.self)!,
                       apiManager: r.resolve(APIManager.self)!,
                       userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.userScope)

        container.register(LocalPingManager.self) { r in
            LocalPingManagerImpl(pingManager: r.resolve(WSNetPingManagerType.self)!)
        }.inObjectScope(.container)
    }
}

// MARK: - Database

class Database: Assembly {
    // Remove this singleton in future
    func assemble(container: Container) {
        container.register(LocalDatabase.self) { r in
            let logger = r.resolve(FileLogger.self)!
            let preferences = r.resolve(Preferences.self)!
            let sessionStore = r.resolve(SessionKeychainStore.self)!

            // Always construct the Realm impl — it's the migration source and the
            // session-fallback if GRDB init/migration fails. Run its own schema
            // migration (no-op for users already at v62).
            let realmImpl = LocalDatabaseImpl(logger: logger, preferences: preferences)
            realmImpl.migrate()

            // Port Realm-only legacy data (Session, OpenVPN/IKEv2 creds, custom
            // config creds) into the Keychain before the GRDB swap. GRDB has no
            // schema for these, so once the swap happens MigrationRepository's
            // Realm-read paths return nil and the data is silently lost.
            RealmKeychainPortMigration.run(
                realm: realmImpl,
                preferences: preferences,
                sessionStore: sessionStore,
                logger: logger
            )

            // Try to stand up the GRDB impl + run the one-time Realm→GRDB port.
            do {
                let grdbImpl = try GRDBLocalDatabaseImpl(logger: logger, preferences: preferences)
                let migrator = RealmToGRDBMigrator(
                    realmDB: realmImpl,
                    grdbDB: grdbImpl,
                    preferences: preferences,
                    logger: logger
                )
                if migrator.migrateIfNeeded() {
                    logger.logI("Database", "Using GRDBLocalDatabaseImpl (migration complete).")
                    return grdbImpl
                }
                logger.logE("Database", "Realm→GRDB migration did not verify. Falling back to Realm for this session; retry next launch.")
            } catch {
                logger.logE("Database", "Failed to initialize GRDBLocalDatabaseImpl: \(error). Falling back to Realm.")
            }
            return realmImpl
        }.inObjectScope(.userScope)
        container.register(KeyChainDatabase.self) { r in
            KeyChainDatabaseImpl(logger: r.resolve(FileLogger.self)!, keychainManager: r.resolve(KeychainManager.self)!)
        }.inObjectScope(.userScope)
    }
}
