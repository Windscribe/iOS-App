//
//  AppModulesViewModels.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-11-13.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import RxSwift
import Swinject

// MARK: ViewModels

class ViewModels: Assembly {
    func assemble(container: Container) {
        container.register((any LoginViewModel).self) { r in
            LoginViewModelImpl(
                apiCallManager: r.resolve(APIManager.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                emergencyConnectRepository: r.resolve(EmergencyRepository.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                latencyRepository: r.resolve(LatencyRepository.self)!,
                connectivity: r.resolve(ConnectivityManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any SignUpViewModel).self) { r in
            SignUpViewModelImpl(
                apiCallManager: r.resolve(APIManager.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                preferences: r.resolve(Preferences.self)!,
                connectivity: r.resolve(ConnectivityManager.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                latencyRepository: r.resolve(LatencyRepository.self)!,
                emergencyConnectRepository: r.resolve(EmergencyRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!,
                sessionManager: r.resolve(SessionManager.self)!)
        }.inObjectScope(.transient)

        container.register((any WelcomeViewModel).self) { r in
            WelcomeViewModelImpl(
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                keyChainDatabase: r.resolve(KeyChainDatabase.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                ssoManager: r.resolve(SSOManaging.self)!,
                logger: r.resolve(FileLogger.self)!,
                sessionManager: r.resolve(SessionManager.self)!
            )
        }.inObjectScope(.transient)

        container.register(PlanUpgradeViewModel.self) { r in
            DefaultUpgradePlanViewModel(
                alertManager: r.resolve(AlertManagerV2.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                apiManager: r.resolve(APIManager.self)!,
                upgradeRouter: r.resolve(UpgradeRouter.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                inAppPurchaseManager: r.resolve(InAppPurchaseManager.self)!,
                pushNotificationManager: r.resolve(PushNotificationManager.self)!,
                mobilePlanRepository: r.resolve(MobilePlanRepository.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.transient)

        container.register((any EmergencyConnectViewModel).self) { r in
            EmergencyConnectViewModelImpl(
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                emergencyRepository: r.resolve(EmergencyRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any EnterEmailViewModel).self) { r in
            EnterEmailViewModelImpl(
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                alertManager: r.resolve(AlertManagerV2.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any ConfirmEmailViewModel).self) { r in
            ConfirmEmailViewModelImpl(
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any GhostAccountViewModel).self) { r in
            GhostAccountViewModelImpl(
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any PreferencesMainCategoryViewModel).self) { r in
            PreferencesMainCategoryViewModelImpl(
                sessionManager: r.resolve(SessionManager.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                alertManager: r.resolve(AlertManagerV2.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                languageManager: r.resolve(LanguageManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!)
        }.inObjectScope(.transient)

        container.register((any AccountSettingsViewModel).self) { r in
            AccountSettingsViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                preferences: r.resolve(Preferences.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                languageManager: r.resolve(LanguageManager.self)!,
                logger: r.resolve(FileLogger.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!)
        }.inObjectScope(.transient)

        container.register((any ConnectionSettingsViewModel).self) { r in
            ConnectionSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                router: r.resolve(ConnectionsNavigationRouter.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                dnsSettingsManager: r.resolve(DNSSettingsManagerType.self)!
            )
        }.inObjectScope(.transient)

        container.register((any RobertSettingsViewModel).self) { r in
            RobertSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                apiManager: r.resolve(APIManager.self)!,
                localDB: r.resolve(LocalDatabase.self)!
            )
        }.inObjectScope(.transient)

        container.register((any ReferForDataSettingsViewModel).self) { r in
            ReferForDataSettingsViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                referFriendManager: r.resolve(ReferAndShareManager.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any LookAndFeelSettingsViewModel).self) { r in
            LookAndFeelSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                backgroundFileManager: r.resolve(BackgroundFileManaging.self)!,
                soundFileManager: r.resolve(SoundFileManaging.self)!,
                serverRepository: r.resolve(ServerRepository.self)!
            )
        }.inObjectScope(.transient)

        container.register((any HelpSettingsViewModel).self) { r in
            HelpSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                connectivity: r.resolve(ConnectivityManager.self)!)
        }.inObjectScope(.transient)

        container.register((any SendTicketViewModel).self) { r in
            SendTicketViewModelImpl(
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.transient)

        container.register((any AdvancedParametersViewModel).self) { r in
            AdvancedParametersViewModelImpl(
                preferences: r.resolve(Preferences.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any DebugLogViewModel).self) { r in
            DebugLogViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any AboutSettingsViewModel).self) { r in
            AboutSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any ScreenTestViewModel).self) { r in
            ScreenTestViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!)
        }.inObjectScope(.transient)

        container.register((any LocationPermissionInfoViewModel).self) { r in
            LocationPermissionInfoViewModelImpl(
                manager: r.resolve(LocationPermissionManaging.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any PushNotificationViewModel).self) { r in
            PushNotificationViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                pushNotificationsManager: r.resolve(PushNotificationManager.self)!)
        }.inObjectScope(.transient)

        container.register((any RestrictiveNetworkViewModel).self) { r in
            RestrictiveNetworkViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                pushNotificationsManager: r.resolve(PushNotificationManager.self)!)
        }.inObjectScope(.transient)

        container.register((any EnterCredentialsViewModel).self) { r in
            EnterCredentialsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.transient)

        container.register((any MaintananceLocationViewModel).self) { r in
            MaintananceLocationViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.transient)

        container.register((any AccountStatusViewModel).self) { r in
            AccountStatusViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!
            )
        }.inObjectScope(.transient)

        container.register((any ProtocolSwitchViewModel).self) { r in
            ProtocolSwitchViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                wifiNetworkRepository: r.resolve(WifiNetworkRepository.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.transient)

        container.register((any ProtocolConnectionResultViewModel).self) { r in
            ProtocolConnectionResultViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                preferences: r.resolve(Preferences.self)!,
                wifiNetworkRepository: r.resolve(WifiNetworkRepository.self)!
            )
        }.inObjectScope(.transient)

        container.register((any ProtocolConnectionDebugViewModel).self) { r in
            ProtocolConnectionDebugViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.transient)

        container.register((any NewsFeedViewModelProtocol).self) { r in
            NewsFeedViewModel(
                localDatabase: r.resolve(LocalDatabase.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!,
                router: r.resolve(AccountRouter.self)!,
                htmlParser: r.resolve(HTMLParsing.self)!,
                notificationRepository: r.resolve(NotificationRepository.self)!)
        }.inObjectScope(.transient)

        container.register(PrivacyStateManaging.self) { r in
            PrivacyStateManager(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.container)

        container.register((any PrivacyInfoViewModel).self) { r in
            PrivacyInfoViewModelImpl(
                preferences: r.resolve(Preferences.self)!,
                networkRepository: r.resolve(WifiNetworkRepository.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                privacyStateManager: r.resolve(PrivacyStateManaging.self)!)
        }.inObjectScope(.transient)
        container.register(MainViewModel.self) { r in
            MainViewModelImpl(localDatabase: r.resolve(LocalDatabase.self)!,
                              vpnManager: r.resolve(VPNManager.self)!,
                              logger: r.resolve(FileLogger.self)!,
                              serverRepository: r.resolve(ServerRepository.self)!,
                              portMapRepo: r.resolve(PortMapRepository.self)!,
                              staticIpRepository: r.resolve(StaticIpRepository.self)!,
                              preferences: r.resolve(Preferences.self)!,
                              latencyRepo: r.resolve(LatencyRepository.self)!,
                              lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                              pushNotificationsManager: r.resolve(PushNotificationManager.self)!,
                              notificationsRepo: r.resolve(NotificationRepository.self)!,
                              credentialsRepository: r.resolve(CredentialsRepository.self)!,
                              connectivity: r.resolve(ConnectivityManager.self)!,
                              livecycleManager: r.resolve(LivecycleManagerType.self)!,
                              locationsManager: r.resolve(LocationsManager.self)!,
                              protocolManager: r.resolve(ProtocolManagerType.self)!,
                              hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                              userSessionRepository: r.resolve(UserSessionRepository.self)!,
                              wifiNetworkRepository: r.resolve(WifiNetworkRepository.self)!,
                              sessionManager: r.resolve(SessionManager.self)!)
        }.inObjectScope(.transient)
        container.register(SearchLocationsViewModelType.self) { r in
            SearchLocationsViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                                     languageManager: r.resolve(LanguageManager.self)!)
        }.inObjectScope(.transient)
        container.register(LocationPermissionManaging.self) { r in
            LocationPermissionManager(connectivityManager: r.resolve(ProtocolManagerType.self)!, logger: r.resolve(FileLogger.self)!, connectivity: r.resolve(ConnectivityManager.self)!, wifiManager: WifiManager.shared)
        }.inObjectScope(.container)

        container.register(ConnectionViewModelType.self) { r in
            ConnectionViewModel(logger: r.resolve(FileLogger.self)!,
                                apiManager: r.resolve(APIManager.self)!,
                                vpnManager: r.resolve(VPNManager.self)!,
                                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                locationsManager: r.resolve(LocationsManager.self)!,
                                protocolManager: r.resolve(ProtocolManagerType.self)!,
                                preferences: r.resolve(Preferences.self)!,
                                connectivity: r.resolve(ConnectivityManager.self)!,
                                wifiManager: WifiManager.shared,
                                wifiNetworkRepository: r.resolve(WifiNetworkRepository.self)!,
                                credentialsRepository: r.resolve(CredentialsRepository.self)!,
                                ipRepository: r.resolve(IPRepository.self)!,
                                localDB: r.resolve(LocalDatabase.self)!,
                                customSoundPlaybackManager: r.resolve(CustomSoundPlaybackManaging.self)!,
                                privacyStateManager: r.resolve(PrivacyStateManaging.self)!,
                                bridgeApiRepository: r.resolve(BridgeApiRepository.self)!,
                                userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.transient)
        container.register(ListSelectionViewModelType.self) { r in
            ListSelectionViewModel(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
            )
        }.inObjectScope(.transient)

        container.register(CustomConfigPickerViewModelType.self) { r in
            CustomConfigPickerViewModel(logger: r.resolve(FileLogger.self)!,
                                        alertManager: r.resolve(AlertManagerV2.self)!,
                                        customConfigRepository: r.resolve(CustomConfigRepository.self)!,
                                        vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                        localDataBase: r.resolve(LocalDatabase.self)!,
                                        connectivity: r.resolve(ConnectivityManager.self)!,
                                        locationsManager: r.resolve(LocationsManager.self)!,
                                        protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(FavouriteListViewModelType.self) { r in
            FavouriteListViewModel(logger: r.resolve(FileLogger.self)!,
                                   vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                   connectivity: r.resolve(ConnectivityManager.self)!,
                                   userSessionRepository: r.resolve(UserSessionRepository.self)!,
                                   locationsManager: r.resolve(LocationsManager.self)!,
                                   protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(ServerListViewModelType.self) { r in
            ServerListViewModel(logger: r.resolve(FileLogger.self)!,
                                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                connectivity: r.resolve(ConnectivityManager.self)!,
                                localDataBase: r.resolve(LocalDatabase.self)!,
                                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                                locationsManager: r.resolve(LocationsManager.self)!,
                                protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(StaticIPListViewModelType.self) { r in
            StaticIPListViewModel(logger: r.resolve(FileLogger.self)!,
                                  vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                  connectivity: r.resolve(ConnectivityManager.self)!,
                                  locationsManager: r.resolve(LocationsManager.self)!,
                                  protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)

        container.register(LatencyViewModel.self) { r in
            LatencyViewModelImpl(latencyRepo: r.resolve(LatencyRepository.self)!,
                                 serverRepository: r.resolve(ServerRepository.self)!,
                                 staticIpRepository: r.resolve(StaticIpRepository.self)!)
        }.inObjectScope(.transient)

        container.register(FlagsBackgroundViewModelType.self) { r in
            FlagsBackgroundViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                                     locationsManager: r.resolve(LocationsManager.self)!,
                                     vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                     backgroundFileManager: r.resolve(BackgroundFileManaging.self)!)
        }.inObjectScope(.transient)

        container.register(LocationNameViewModel.self) { r in
            LocationNameViewModelImpl(languageManager: r.resolve(LanguageManager.self)!,
                                     locationsManager: r.resolve(LocationsManager.self)!)
        }.inObjectScope(.transient)

        container.register(ConnectButtonViewModelType.self) { r in
            ConnectButtonViewModel(vpnStateRepository: r.resolve(VPNStateRepository.self)!)
        }.inObjectScope(.transient)

        container.register(ConnectionStateInfoViewModelType.self) { r in
            ConnectionStateInfoViewModel(vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                         locationsManager: r.resolve(LocationsManager.self)!,
                                         preferences: r.resolve(Preferences.self)!,
                                         protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)

        container.register(IPInfoViewModelType.self) { r in
            IPInfoViewModel(logger: r.resolve(FileLogger.self)!,
                            ipRepository: r.resolve(IPRepository.self)!,
                            preferences: r.resolve(Preferences.self)!,
                            locationManager: r.resolve(LocationsManager.self)!,
                            localDatabase: r.resolve(LocalDatabase.self)!,
                            apiManager: r.resolve(APIManager.self)!,
                            userSessionRepository: r.resolve(UserSessionRepository.self)!,
                            bridgeApiRepository: r.resolve(BridgeApiRepository.self)!,
                            serverRepository: r.resolve(ServerRepository.self)!,
                            hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!)
        }.inObjectScope(.transient)

        container.register(WifiInfoViewModelType.self) { r in
            WifiInfoViewModel(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.transient)

        container.register(ServerInfoViewModelType.self) { r in
            ServerInfoViewModel(languageManager: r.resolve(LanguageManager.self)!,
                                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                                serverRepository: r.resolve(ServerRepository.self)!)
        }.inObjectScope(.transient)

        container.register(ListHeaderViewModelType.self) { r in
            ListHeaderViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                                languageManager: r.resolve(LanguageManager.self)!)
        }.inObjectScope(.transient)

        container.register(FreeAccountFooterViewModelType.self) { r in
            FreeAccountFooterViewModel(userSessionRepository: r.resolve(UserSessionRepository.self)!)
        }.inObjectScope(.transient)

        container.register((any BridgeApiFailedViewModel).self) { r in
            BridgeApiFailedViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                preferences: r.resolve(Preferences.self)!
            )
        }.inObjectScope(.transient)
    }
}
