//
//  AppModulesPhone.swift
//  Windscribe
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import RxSwift
import Swinject

// MARK: - ViewModels

class ViewModels: Assembly {
    func assemble(container: Container) {
        container.register((any LoginViewModel).self) { r in
            LoginViewModelImpl(
                apiCallManager: r.resolve(APIManager.self)!,
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
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
                logger: r.resolve(FileLogger.self)!)
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
                logger: r.resolve(FileLogger.self)!
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
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
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
                sessionRepository: r.resolve(SessionRepository.self)!,
                alertManager: r.resolve(AlertManagerV2.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any ConfirmEmailViewModel).self) { r in
            ConfirmEmailViewModelImpl(
                sessionRepository: r.resolve(SessionRepository.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any GhostAccountViewModel).self) { r in
            GhostAccountViewModelImpl(
                sessionRepository: r.resolve(SessionRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any PreferencesMainCategoryViewModel).self) { r in
            PreferencesMainCategoryViewModelImpl(
                sessionManager: r.resolve(SessionManager.self)!,
                sessionRepository: r.resolve(SessionRepository.self)!,
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
                sessionRepository: r.resolve(SessionRepository.self)!,
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
                sessionRepository: r.resolve(SessionRepository.self)!,
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
                sessionRepository: r.resolve(SessionRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                connectivity: r.resolve(ConnectivityManager.self)!)
        }.inObjectScope(.transient)

        container.register((any SendTicketViewModel).self) { r in
            SendTicketViewModelImpl(
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                sessionRepository: r.resolve(SessionRepository.self)!)
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
                sessionRepository: r.resolve(SessionRepository.self)!
            )
        }.inObjectScope(.transient)

        container.register((any ProtocolSwitchViewModel).self) { r in
            ProtocolSwitchViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.transient)

        container.register((any ProtocolConnectionResultViewModel).self) { r in
            ProtocolConnectionResultViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                securedNetwork: r.resolve(SecuredNetworkRepository.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                sessionRepository: r.resolve(SessionRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!
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
                networkRepository: r.resolve(SecuredNetworkRepository.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                privacyStateManager: r.resolve(PrivacyStateManaging.self)!)
        }.inObjectScope(.transient)
        container.register(MainViewModelType.self) { r in
            MainViewModel(localDatabase: r.resolve(LocalDatabase.self)!,
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
                          sessionRepository: r.resolve(SessionRepository.self)!)
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
                                securedNetwork: r.resolve(SecuredNetworkRepository.self)!,
                                credentialsRepository: r.resolve(CredentialsRepository.self)!,
                                ipRepository: r.resolve(IPRepository.self)!,
                                localDB: r.resolve(LocalDatabase.self)!,
                                customSoundPlaybackManager: r.resolve(CustomSoundPlaybackManaging.self)!,
                                privacyStateManager: r.resolve(PrivacyStateManaging.self)!)
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
                                   sessionRepository: r.resolve(SessionRepository.self)!,
                                   locationsManager: r.resolve(LocationsManager.self)!,
                                   protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(ServerListViewModelType.self) { r in
            ServerListViewModel(logger: r.resolve(FileLogger.self)!,
                                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                                connectivity: r.resolve(ConnectivityManager.self)!,
                                localDataBase: r.resolve(LocalDatabase.self)!,
                                sessionRepository: r.resolve(SessionRepository.self)!,
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
                            bridgeApiRepository: r.resolve(BridgeApiRepository.self)!)
        }.inObjectScope(.transient)

        container.register(WifiInfoViewModelType.self) { r in
            WifiInfoViewModel(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.transient)

        container.register(ServerInfoViewModelType.self) { r in
            ServerInfoViewModel(localDatabase: r.resolve(LocalDatabase.self)!,
                                languageManager: r.resolve(LanguageManager.self)!,
                                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register(ListHeaderViewModelType.self) { r in
            ListHeaderViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                                languageManager: r.resolve(LanguageManager.self)!)
        }.inObjectScope(.transient)

        container.register(FreeAccountFooterViewModelType.self) { r in
            FreeAccountFooterViewModel(localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.transient)

        container.register((any BridgeApiFailedViewModel).self) { r in
            BridgeApiFailedViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
            )
        }.inObjectScope(.transient)
    }
}

// MARK: - ViewControllerModule

class ViewControllerModule: Assembly {
    func assemble(container: Swinject.Container) {
        container.register(WelcomeView.self) { r in
            WelcomeView(viewModel: WelcomeViewModelImpl(
                userSessionRepository: r.resolve(UserSessionRepository.self)!,
                keyChainDatabase: r.resolve(KeyChainDatabase.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                ssoManager: r.resolve(SSOManaging.self)!,
                logger: r.resolve(FileLogger.self)!
            ), router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(LoginView.self) { r in
            LoginView(viewModel: LoginViewModelImpl(
                    apiCallManager: r.resolve(APIManager.self)!,
                    userSessionRepository: r.resolve(UserSessionRepository.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    emergencyConnectRepository: r.resolve(EmergencyRepository.self)!,
                    userDataRepository: r.resolve(UserDataRepository.self)!,
                    vpnManager: r.resolve(VPNManager.self)!,
                    protocolManager: r.resolve(ProtocolManagerType.self)!,
                    latencyRepository: r.resolve(LatencyRepository.self)!,
                    connectivity: r.resolve(ConnectivityManager.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    logger: r.resolve(FileLogger.self)!
                ), router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(SignUpView.self) { r in
            SignUpView(viewModel: SignUpViewModelImpl(
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
                logger: r.resolve(FileLogger.self)!
            ), router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(EmergencyConnectView.self) { r in
            EmergencyConnectView(viewModel: EmergencyConnectViewModelImpl(
                vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                emergencyRepository: r.resolve(EmergencyRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!
            ))
        }.inObjectScope(.transient)

        container.register(GhostAccountView.self) { r in
            GhostAccountView(
                viewModel: GhostAccountViewModelImpl(
                    sessionRepository: r.resolve(SessionRepository.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    logger: r.resolve(FileLogger.self)!),
                router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(EnterEmailView.self) { r in
            EnterEmailView(viewModel: EnterEmailViewModelImpl(
                sessionRepository: r.resolve(SessionRepository.self)!,
                alertManager: r.resolve(AlertManagerV2.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
            ))
        }.inObjectScope(.transient)

        container.register(ConfirmEmailView.self) { r in
            ConfirmEmailView(
                viewModel: ConfirmEmailViewModelImpl(
                    sessionRepository: r.resolve(SessionRepository.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    logger: r.resolve(FileLogger.self)!
                ), router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(PreferencesMainCategoryView.self) { r in
            PreferencesMainCategoryView(
                viewModel: PreferencesMainCategoryViewModelImpl(
                    sessionManager: r.resolve(SessionManager.self)!,
                    sessionRepository: r.resolve(SessionRepository.self)!,
                    alertManager: r.resolve(AlertManagerV2.self)!,
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    languageManager: r.resolve(LanguageManager.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!
                ), router: r.resolve(PreferencesNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(GeneralSettingsView.self) { r in
            GeneralSettingsView(viewModel: GeneralSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                languageManager: r.resolve(LanguageManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                pushNotificationManager: r.resolve(PushNotificationManager.self)!
            ))
        }.inObjectScope(.transient)

        container.register(AccountSettingsView.self) { r in
            AccountSettingsView(
                viewModel: AccountSettingsViewModelImpl(
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    sessionManager: r.resolve(SessionManager.self)!,
                    sessionRepository: r.resolve(SessionRepository.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    languageManager: r.resolve(LanguageManager.self)!,
                    logger: r.resolve(FileLogger.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!)
            )
        }.inObjectScope(.transient)

        container.register(ConnectionSettingsView.self) { r in
           ConnectionSettingsView(
                viewModel: ConnectionSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    router: r.resolve(ConnectionsNavigationRouter.self)!,
                    protocolManager: r.resolve(ProtocolManagerType.self)!,
                    dnsSettingsManager: r.resolve(DNSSettingsManagerType.self)!
                )
           )
        }.inObjectScope(.transient)

        container.register(NetworkSecurityView.self) { r in
            NetworkSecurityView(
                viewModel: NetworkOptionsSecurityViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    connectivity: r.resolve(ConnectivityManager.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    router: r.resolve(ConnectionsNavigationRouter.self)!
                )
            )
        }.inObjectScope(.transient)

        container.register(NetworkSettingsView.self) { r in
            NetworkSettingsView(
                viewModel: NetworkSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                    connectivity: r.resolve(ConnectivityManager.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    vpnManager: r.resolve(VPNManager.self)!,
                    vpnStateRepository: r.resolve(VPNStateRepository.self)!,
                    protocolManager: r.resolve(ProtocolManagerType.self)!
                )
            )
        }.inObjectScope(.transient)

        container.register(RobertSettingsView.self) { r in
            RobertSettingsView(
                viewModel: RobertSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    localDB: r.resolve(LocalDatabase.self)!
                )
            )
        }.inObjectScope(.transient)

        container.register(ReferForDataSettingsView.self) { r in
            ReferForDataSettingsView(
                viewModel: ReferForDataSettingsViewModelImpl(
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    sessionRepository: r.resolve(SessionRepository.self)!,
                    referFriendManager: r.resolve(ReferAndShareManager.self)!,
                    logger: r.resolve(FileLogger.self)!))
        }.inObjectScope(.transient)

        container.register(LookAndFeelSettingsView.self) { r in
            LookAndFeelSettingsView(
                viewModel: LookAndFeelSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    backgroundFileManager: r.resolve(BackgroundFileManaging.self)!,
                    soundFileManager: r.resolve(SoundFileManaging.self)!,
                    serverRepository: r.resolve(ServerRepository.self)!
                )
            )
        }.inObjectScope(.transient)

        container.register(HelpSettingsView.self) { r in
            HelpSettingsView(
                viewModel: HelpSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!,
                    sessionRepository: r.resolve(SessionRepository.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    connectivity: r.resolve(ConnectivityManager.self)!),
                router: r.resolve(HelpNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(SendTicketView.self) { r in
            SendTicketView(
                viewModel: SendTicketViewModelImpl(
                    apiManager: r.resolve(APIManager.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    sessionRepository: r.resolve(SessionRepository.self)!)
           )
        }.inObjectScope(.transient)

        container.register(AdvancedParametersView.self) { r in
            AdvancedParametersView(
                viewModel: AdvancedParametersViewModelImpl(
                    preferences: r.resolve(Preferences.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
                )
        }.inObjectScope(.transient)

        container.register(DebugLogView.self) { r in
            DebugLogView(
                viewModel: DebugLogViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
                )
        }.inObjectScope(.transient)

        container.register(AboutSettingsView.self) { r in
            AboutSettingsView(
                viewModel: AboutSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!))
        }.inObjectScope(.transient)

        container.register(ScreenTestView.self) { r in
            ScreenTestView(
                viewModel: ScreenTestViewModelImpl(
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    hapticFeedbackManager: r.resolve(HapticFeedbackManager.self)!),
                router: r.resolve(ScreenTestNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(ShakeForDataMainView.self) { r in
            ShakeForDataMainView(
                viewModel: ShakeForDataMainViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
                ),
                router: r.resolve(ShakeForDataNavigationRouter.self)!
            )
        }.inObjectScope(.transient)

        container.register(ShakeForDataLeaderboardView.self) { r in
            ShakeForDataLeaderboardView(
                viewModel: ShakeForDataLeaderboardModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    repository: r.resolve(ShakeDataRepository.self)!
                )
            )
        }.inObjectScope(.transient)

        container.register(ShakeForDataGameView.self) { r in
            ShakeForDataGameView(
                viewModel: ShakeForDataGameViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    repository: r.resolve(ShakeDataRepository.self)!
                ),
                router: r.resolve(ShakeForDataNavigationRouter.self)!
            )
        }.inObjectScope(.transient)

        container.register(ShakeForDataResultsView.self) { r in
            ShakeForDataResultsView(
                viewModel: ShakeForDataResultsViewModelImpl(
                    preferences: r.resolve(Preferences.self)!,
                    logger: r.resolve(FileLogger.self)!,
                    repository: r.resolve(ShakeDataRepository.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
                ),
                router: r.resolve(ShakeForDataNavigationRouter.self)!
            )
        }.inObjectScope(.transient)

        container.register(MainViewController.self) { _ in
            MainViewController()
        }.initCompleted { r, vc in
            vc.router = r.resolve(HomeRouter.self)
            vc.accountRouter = r.resolve(AccountRouter.self)
            vc.popupRouter = r.resolve(PopupRouter.self)
            vc.customConfigRepository = r.resolve(CustomConfigRepository.self)
            vc.viewModel = r.resolve(MainViewModelType.self)
            vc.soundManager = r.resolve(SoundManaging.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.locationPermissionManager = r.resolve(LocationPermissionManaging.self)
            vc.staticIPListViewModel = r.resolve(StaticIPListViewModelType.self)
            vc.vpnConnectionViewModel = r.resolve(ConnectionViewModelType.self)
            vc.customConfigPickerViewModel = r.resolve(CustomConfigPickerViewModelType.self)
            vc.favNodesListViewModel = r.resolve(FavouriteListViewModelType.self)
            vc.serverListViewModel = r.resolve(ServerListViewModelType.self)
            vc.latencyViewModel = r.resolve(LatencyViewModel.self)
            vc.referAndShareManager = r.resolve(ReferAndShareManager.self)
        }.inObjectScope(.transient)

        container.register(PlanUpgradeViewController.self) { _ in
            PlanUpgradeViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(PlanUpgradeViewModel.self)
        }.inObjectScope(.transient)

        container.register(AccountStatusView.self) { r in
            AccountStatusView(viewModel: r.resolve((any AccountStatusViewModel).self)!)
        }.inObjectScope(.transient)

        container.register(NewsFeedView.self) { r in
            NewsFeedView(viewModel: NewsFeedViewModel(
                localDatabase: r.resolve(LocalDatabase.self)!,
                sessionManager: r.resolve(SessionManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!,
                router: r.resolve(AccountRouter.self)!,
                htmlParser: r.resolve(HTMLParsing.self)!,
                notificationRepository: r.resolve(NotificationRepository.self)!)
            )
        }.inObjectScope(.transient)

        container.register(ListSelectionView.self) { _ in
            ListSelectionView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ListSelectionViewModelType.self)
        }.inObjectScope(.transient)

        container.register(LocationPermissionInfoView.self) { r in
            LocationPermissionInfoView(viewModel: LocationPermissionInfoViewModelImpl(
                manager: r.resolve(LocationPermissionManaging.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
            )
        }.inObjectScope(.transient)

        container.register(PrivacyInfoView.self) { r in
            PrivacyInfoView(viewModel: PrivacyInfoViewModelImpl(
                preferences: r.resolve(Preferences.self)!,
                networkRepository: r.resolve(SecuredNetworkRepository.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                privacyStateManager: r.resolve(PrivacyStateManaging.self)!)
            )
        }.inObjectScope(.transient)

        container.register(EnterCredentialsView.self) { r in
            EnterCredentialsView(viewModel: EnterCredentialsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!)
            )
        }.inObjectScope(.transient)

        container.register(PushNotificationView.self) { r in
            PushNotificationView(viewModel: PushNotificationViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                pushNotificationsManager: r.resolve(PushNotificationManager.self)!)
            )
        }.inObjectScope(.transient)

        container.register(RestrictiveNetworkView.self) { r in
            RestrictiveNetworkView(viewModel: RestrictiveNetworkViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                pushNotificationsManager: r.resolve(PushNotificationManager.self)!)
            )
        }.inObjectScope(.transient)

        container.register(MaintananceLocationView.self) { r in
            MaintananceLocationView(
                viewModel: r.resolve((any MaintananceLocationViewModel).self)!
            )
        }.inObjectScope(.transient)

        container.register(FlagsBackgroundView.self) { _ in
            FlagsBackgroundView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(FlagsBackgroundViewModelType.self)
        }.inObjectScope(.transient)

        container.register(ConnectButtonView.self) { _ in
            ConnectButtonView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ConnectButtonViewModelType.self)
        }.inObjectScope(.transient)

        container.register(ConnectionStateInfoView.self) { _ in
            ConnectionStateInfoView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ConnectionStateInfoViewModelType.self)
        }.inObjectScope(.transient)

        container.register(IPInfoView.self) { _ in
            IPInfoView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(IPInfoViewModelType.self)
        }.inObjectScope(.transient)

        container.register(WifiInfoView.self) { _ in
            WifiInfoView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(WifiInfoViewModelType.self)
        }.inObjectScope(.transient)

        container.register(ServerInfoView.self) { _ in
            ServerInfoView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ServerInfoViewModelType.self)
        }.inObjectScope(.transient)

        container.register(ListHeaderView.self) { _ in
            ListHeaderView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ListHeaderViewModelType.self)
        }.inObjectScope(.transient)

        container.register(FreeAccountFooterView.self) { _ in
            FreeAccountFooterView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(FreeAccountFooterViewModelType.self)
        }.inObjectScope(.transient)

        container.register(ProtocolSwitchNavigationRouter.self) { _ in
            ProtocolSwitchNavigationRouter()
        }.inObjectScope(.transient)

        container.register(ProtocolSwitchView.self) { r in
            ProtocolSwitchView(
                viewModel: r.resolve((any ProtocolSwitchViewModel).self)!,
                router: r.resolve(ProtocolSwitchNavigationRouter.self)!
            )
        }.inObjectScope(.transient)

        container.register(ProtocolConnectionResultView.self) { r in
            ProtocolConnectionResultView(
                viewModel: r.resolve((any ProtocolConnectionResultViewModel).self)!,
                router: r.resolve(ProtocolSwitchNavigationRouter.self)!
            )
        }.inObjectScope(.transient)

        container.register(ProtocolConnectionDebugView.self) { r in
            ProtocolConnectionDebugView(
                viewModel: r.resolve((any ProtocolConnectionDebugViewModel).self)!,
                router: r.resolve(ProtocolSwitchNavigationRouter.self)!
            )
        }.inObjectScope(.transient)

        container.register(BridgeApiFailedView.self) { r in
            BridgeApiFailedView(
                viewModel: BridgeApiFailedViewModelImpl(
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
                )
            )
        }.inObjectScope(.transient)
    }
}

// MARK: - Routers

class Routers: Assembly {
    func assemble(container: Container) {
        container.register(AuthenticationNavigationRouter.self) { _ in
            AuthenticationNavigationRouter()
        }.inObjectScope(.transient)
        container.register(PreferencesNavigationRouter.self) { _ in
            PreferencesNavigationRouter()
        }.inObjectScope(.transient)

        container.register(ScreenTestNavigationRouter.self) { _ in
            ScreenTestNavigationRouter()
        }.inObjectScope(.transient)

        container.register(ConnectionsNavigationRouter.self) { _ in
            ConnectionsNavigationRouter()
        }.inObjectScope(.transient)
        container.register(ShakeForDataNavigationRouter.self) { _ in
            ShakeForDataNavigationRouter()
        }.inObjectScope(.transient)
        container.register(HelpNavigationRouter.self) { _ in
            HelpNavigationRouter()
        }.inObjectScope(.transient)
        container.register(HomeRouter.self) { _ in
            HomeRouter()
        }.inObjectScope(.transient)
        container.register(AccountRouter.self) { _ in
            AccountRouter()
        }.inObjectScope(.transient)
        container.register(UpgradeRouter.self) { _ in
            UpgradeRouter()
        }.inObjectScope(.transient)
        container.register(PopupRouter.self) { _ in
            PopupRouter()
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchRouter.self) { _ in
            ProtocolSwitchRouter()
        }.inObjectScope(.transient)
    }
}
