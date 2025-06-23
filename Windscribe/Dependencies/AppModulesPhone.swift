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
                userRepository: r.resolve(UserRepository.self)!,
                preferences: r.resolve(Preferences.self)!,
                emergencyConnectRepository: r.resolve(EmergencyRepository.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                latencyRepository: r.resolve(LatencyRepository.self)!,
                connectivity: r.resolve(Connectivity.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any SignUpViewModel).self) { r in
            SignUpViewModelImpl(
                apiCallManager: r.resolve(APIManager.self)!,
                userRepository: r.resolve(UserRepository.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                preferences: r.resolve(Preferences.self)!,
                connectivity: r.resolve(Connectivity.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!,
                latencyRepository: r.resolve(LatencyRepository.self)!,
                emergencyConnectRepository: r.resolve(EmergencyRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any WelcomeViewModel).self) { r in
            WelcomeViewModelImpl(
                userRepository: r.resolve(UserRepository.self)!,
                keyChainDatabase: r.resolve(KeyChainDatabase.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
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
                sessionManager: r.resolve(SessionManaging.self)!,
                preferences: r.resolve(Preferences.self)!,
                inAppPurchaseManager: r.resolve(InAppPurchaseManager.self)!,
                pushNotificationManager: r.resolve(PushNotificationManagerV2.self)!,
                billingRepository: r.resolve(BillingRepository.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any EmergencyConnectViewModel).self) { r in
            EmergencyConnectViewModelImpl(
                vpnManager: r.resolve(VPNManager.self)!,
                emergencyRepository: r.resolve(EmergencyRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any EnterEmailViewModel).self) { r in
            EnterEmailViewModelImpl(
                sessionManager: r.resolve(SessionManaging.self)!,
                alertManager: r.resolve(AlertManagerV2.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register((any ConfirmEmailViewModel).self) { r in
            ConfirmEmailViewModelImpl(
                sessionManager: r.resolve(SessionManaging.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any GhostAccountViewModel).self) { r in
            GhostAccountViewModelImpl(
                sessionManager: r.resolve(SessionManaging.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any PreferencesMainCategoryViewModel).self) { r in
            PreferencesMainCategoryViewModelImpl(
                sessionManager: r.resolve(SessionManaging.self)!,
                alertManager: r.resolve(AlertManagerV2.self)!,
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                languageManager: r.resolve(LanguageManager.self)!,
                preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.transient)

        container.register((any AccountSettingsViewModel).self) { r in
            AccountSettingsViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                preferences: r.resolve(Preferences.self)!,
                sessionManager: r.resolve(SessionManaging.self)!,
                apiManager: r.resolve(APIManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                languageManager: r.resolve(LanguageManager.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any ConnectionSettingsViewModel).self) { r in
            ConnectionSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                preferences: r.resolve(Preferences.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                router: r.resolve(ConnectionsNavigationRouter.self)!,
                protocolManager: r.resolve(ProtocolManagerType.self)!
            )
        }.inObjectScope(.transient)

        container.register((any RobertSettingsViewModel).self) { r in
            RobertSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                apiManager: r.resolve(APIManager.self)!,
                localDB: r.resolve(LocalDatabase.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
            )
        }.inObjectScope(.transient)

        container.register((any ReferForDataSettingsViewModel).self) { r in
            ReferForDataSettingsViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                sessionManager: r.resolve(SessionManaging.self)!,
                referFriendManager: r.resolve(ReferAndShareManagerV2.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any LookAndFeelSettingsViewModel).self) { r in
            LookAndFeelSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                preferences: r.resolve(Preferences.self)!,
                backgroundFileManager: r.resolve(BackgroundFileManaging.self)!,
                soundFileManager: r.resolve(SoundFileManaging.self)!,
                serverRepository: r.resolve(ServerRepository.self)!
            )
        }.inObjectScope(.transient)

        container.register((any HelpSettingsViewModel).self) { r in
            HelpSettingsViewModelImpl(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                sessionManager: r.resolve(SessionManaging.self)!,
                apiManager: r.resolve(APIManager.self)!,
                connectivity: r.resolve(Connectivity.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register((any SendTicketViewModel).self) { r in
            SendTicketViewModelImpl(
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                sessionManager: r.resolve(SessionManaging.self)!)
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

        container.register(BannedAccountPopupModelType.self) { r in
            BannedAccountPopupModel(popupRouter: r.resolve(PopupRouter.self), sessionManager: r.resolve(SessionManaging.self)!)
        }.inObjectScope(.transient)
        container.register(OutOfDataAccountPopupModelType.self) { r in
            OutOfDataAccountPopupModel(popupRouter: r.resolve(PopupRouter.self), sessionManager: r.resolve(SessionManaging.self)!)
        }.inObjectScope(.transient)
        container.register(ProPlanExpiredAccountPopupModelType.self) { r in
            ProPlanExpiredAccountPopupModel(popupRouter: r.resolve(PopupRouter.self), sessionManager: r.resolve(SessionManaging.self)!)
        }.inObjectScope(.transient)
        container.register(SetPreferredProtocolModelType.self) { r in
            SetPreferredProtocolModel(connectivity: r.resolve(Connectivity.self)!, networkRepository: r.resolve(SecuredNetworkRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ProtocolSetPreferredViewModelV2.self) { r in
            ProtocolSetPreferredViewModel(alertManager: r.resolve(AlertManagerV2.self)!, type: ProtocolViewType.connected, securedNetwork: r.resolve(SecuredNetworkRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!, sessionManager: r.resolve(SessionManaging.self)!, logger: r.resolve(FileLogger.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register((any NewsFeedViewModelProtocol).self) { r in
            NewsFeedViewModel(
                localDatabase: r.resolve(LocalDatabase.self)!,
                sessionManager: r.resolve(SessionManaging.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!,
                router: r.resolve(AccountRouter.self)!,
                htmlParser: r.resolve(HTMLParsing.self)!,
                notificationRepository: r.resolve(NotificationRepository.self)!)
        }.inObjectScope(.transient)
        container.register(PrivacyViewModelType.self) { r in
            PrivacyViewModel(
                preferences: r.resolve(Preferences.self)!,
                networkRepository: r.resolve(SecuredNetworkRepository.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                logger: r.resolve(FileLogger.self)!
            )
        }.inObjectScope(.transient)
        container.register(TrustedNetworkPopupType.self) { r in
            TrustedNetworkPopup(securedNetwork: r.resolve(SecuredNetworkRepository.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ErrorPopupViewModelType.self) { _ in
            ErrorPopupViewModel()
        }.inObjectScope(.transient)

        container.register(EnterCredentialsViewModelType.self) { r in
            EnterCredentialsViewModel(
                vpnManager: r.resolve(VPNManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
            )
        }.inObjectScope(.transient)
        container.register(PushNotificationViewModelType.self) { r in
            PushNotificationViewModel(
                logger: r.resolve(FileLogger.self)!,
                pushNotificationsManager: r.resolve(PushNotificationManagerV2.self)!
            )
        }.inObjectScope(.transient)
        container.register(MainViewModelType.self) { r in
            MainViewModel(localDatabase: r.resolve(LocalDatabase.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!, serverRepository: r.resolve(ServerRepository.self)!, portMapRepo: r.resolve(PortMapRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!, preferences: r.resolve(Preferences.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, pushNotificationsManager: r.resolve(PushNotificationManagerV2.self)!, notificationsRepo: r.resolve(NotificationRepository.self)!, credentialsRepository: r.resolve(CredentialsRepository.self)!, connectivity: r.resolve(Connectivity.self)!, livecycleManager: r.resolve(LivecycleManagerType.self)!, locationsManager: r.resolve(LocationsManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(ShakeForDataPopupViewModelType.self) { r in
            ShakeForDataPopupViewModel(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ShakeForDataViewModelType.self) { r in
            ShakeForDataViewModel(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ShakeForDataResultViewModelType.self) { r in
            ShakeForDataResultViewModel(logger: r.resolve(FileLogger.self)!,
                                        repository: r.resolve(ShakeDataRepository.self)!,
                                        preferences: r.resolve(Preferences.self)!,
                                        alertManager: r.resolve(AlertManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(ViewLeaderboardViewModelType.self) { r in
            ViewLeaderboardViewModel(logger: r.resolve(FileLogger.self)!,
                                     repository: r.resolve(ShakeDataRepository.self)!,
                                     lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)
        container.register(SearchLocationsViewModelType.self) { r in
            SearchLocationsViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)
        container.register(LocationManagingViewModelType.self) { r in
            LocationManagingViewModel(connectivityManager: r.resolve(ProtocolManagerType.self)!, logger: r.resolve(FileLogger.self)!, connectivity: r.resolve(Connectivity.self)!, wifiManager: WifiManager.shared)
        }.inObjectScope(.transient)
        container.register(ConnectionViewModelType.self) { r in
            ConnectionViewModel(logger: r.resolve(FileLogger.self)!,
                                apiManager: r.resolve(APIManager.self)!,
                                vpnManager: r.resolve(VPNManager.self)!,
                                locationsManager: r.resolve(LocationsManagerType.self)!,
                                protocolManager: r.resolve(ProtocolManagerType.self)!,
                                preferences: r.resolve(Preferences.self)!,
                                connectivity: r.resolve(Connectivity.self)!,
                                wifiManager: WifiManager.shared,
                                securedNetwork: r.resolve(SecuredNetworkRepository.self)!,
                                credentialsRepository: r.resolve(CredentialsRepository.self)!,
                                ipRepository: r.resolve(IPRepository.self)!,
                                localDB: r.resolve(LocalDatabase.self)!,
                                customSoundPlaybackManager: r.resolve(CustomSoundPlaybackManaging.self)!)
        }.inObjectScope(.transient)
        container.register(ListSelectionViewModelType.self) { r in
            ListSelectionViewModel(
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
            )
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchViewModelType.self) { r in
            ProtocolSwitchViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, vpnManager: r.resolve(VPNManager.self)!)
        }.inObjectScope(.transient)
        container.register(SendDebugLogCompletedViewModelType.self) { r in
            SendDebugLogCompletedViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)
        container.register(CustomConfigPickerViewModelType.self) { r in
            CustomConfigPickerViewModel(logger: r.resolve(FileLogger.self)!,
                                        alertManager: r.resolve(AlertManagerV2.self)!,
                                        customConfigRepository: r.resolve(CustomConfigRepository.self)!,
                                        vpnManager: r.resolve(VPNManager.self)!,
                                        localDataBase: r.resolve(LocalDatabase.self)!,
                                        connectivity: r.resolve(Connectivity.self)!,
                                        locationsManager: r.resolve(LocationsManagerType.self)!,
                                        protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(FavNodesListViewModelType.self) { r in
            FavNodesListViewModel(logger: r.resolve(FileLogger.self)!,
                                  vpnManager: r.resolve(VPNManager.self)!,
                                  connectivity: r.resolve(Connectivity.self)!,
                                  sessionManager: r.resolve(SessionManaging.self)!,
                                  locationsManager: r.resolve(LocationsManagerType.self)!,
                                  protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(ServerListViewModelType.self) { r in
            ServerListViewModel(logger: r.resolve(FileLogger.self)!,
                                vpnManager: r.resolve(VPNManager.self)!,
                                connectivity: r.resolve(Connectivity.self)!,
                                localDataBase: r.resolve(LocalDatabase.self)!,
                                sessionManager: r.resolve(SessionManaging.self)!,
                                locationsManager: r.resolve(LocationsManagerType.self)!,
                                protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(StaticIPListViewModelType.self) { r in
            StaticIPListViewModel(logger: r.resolve(FileLogger.self)!,
                                  vpnManager: r.resolve(VPNManager.self)!,
                                  connectivity: r.resolve(Connectivity.self)!,
                                  locationsManager: r.resolve(LocationsManagerType.self)!,
                                  protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchDelegateViewModelType.self) { _ in
            ProtocolSwitchDelegateViewModel()
        }.inObjectScope(.transient)
        container.register(LatencyViewModel.self) { r in
            LatencyViewModelImpl(latencyRepo: r.resolve(LatencyRepository.self)!,
                                 serverRepository: r.resolve(ServerRepository.self)!,
                                 staticIpRepository: r.resolve(StaticIpRepository.self)!)
        }.inObjectScope(.transient)
        container.register(PopUpMaintenanceLocationModelType.self) { r in
            PopUpMaintenanceLocationModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register(FlagsBackgroundViewModelType.self) { r in
            FlagsBackgroundViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                                     locationsManager: r.resolve(LocationsManagerType.self)!,
                                     vpnManager: r.resolve(VPNManager.self)!,
                                     backgroundFileManager: r.resolve(BackgroundFileManaging.self)!)
        }.inObjectScope(.transient)

        container.register(ConnectButtonViewModelType.self) { r in
            ConnectButtonViewModel(vpnManager: r.resolve(VPNManager.self)!)
        }.inObjectScope(.transient)

        container.register(ConnectionStateInfoViewModelType.self) { r in
            ConnectionStateInfoViewModel(vpnManager: r.resolve(VPNManager.self)!,
                                         locationsManager: r.resolve(LocationsManagerType.self)!,
                                         preferences: r.resolve(Preferences.self)!,
                                         protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)

        container.register(IPInfoViewModelType.self) { r in
            IPInfoViewModel(ipRepository: r.resolve(IPRepository.self)!,
                            preferences: r.resolve(Preferences.self)!)
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
            ListHeaderViewModel(lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)

        container.register(FreeAccountFooterViewModelType.self) { r in
            FreeAccountFooterViewModel(localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.transient)
    }
}

// MARK: - ViewControllerModule

class ViewControllerModule: Assembly {
    func assemble(container: Swinject.Container) {
        container.register(WelcomeView.self) { r in
            WelcomeView(viewModel: WelcomeViewModelImpl(
                userRepository: r.resolve(UserRepository.self)!,
                keyChainDatabase: r.resolve(KeyChainDatabase.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                apiManager: r.resolve(APIManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                vpnManager: r.resolve(VPNManager.self)!,
                ssoManager: r.resolve(SSOManaging.self)!,
                logger: r.resolve(FileLogger.self)!
            ), router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(LoginView.self) { r in
            LoginView(viewModel: LoginViewModelImpl(
                    apiCallManager: r.resolve(APIManager.self)!,
                    userRepository: r.resolve(UserRepository.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    emergencyConnectRepository: r.resolve(EmergencyRepository.self)!,
                    userDataRepository: r.resolve(UserDataRepository.self)!,
                    vpnManager: r.resolve(VPNManager.self)!,
                    protocolManager: r.resolve(ProtocolManagerType.self)!,
                    latencyRepository: r.resolve(LatencyRepository.self)!,
                    connectivity: r.resolve(Connectivity.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    logger: r.resolve(FileLogger.self)!
                ), router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(SignUpView.self) { r in
            SignUpView(viewModel: SignUpViewModelImpl(
                apiCallManager: r.resolve(APIManager.self)!,
                userRepository: r.resolve(UserRepository.self)!,
                userDataRepository: r.resolve(UserDataRepository.self)!,
                preferences: r.resolve(Preferences.self)!,
                connectivity: r.resolve(Connectivity.self)!,
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
                vpnManager: r.resolve(VPNManager.self)!,
                emergencyRepository: r.resolve(EmergencyRepository.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!
            ))
        }.inObjectScope(.transient)

        container.register(GhostAccountView.self) { r in
            GhostAccountView(
                viewModel: GhostAccountViewModelImpl(
                    sessionManager: r.resolve(SessionManaging.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    logger: r.resolve(FileLogger.self)!),
                router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(EnterEmailView.self) { r in
            EnterEmailView(viewModel: EnterEmailViewModelImpl(
                sessionManager: r.resolve(SessionManaging.self)!,
                alertManager: r.resolve(AlertManagerV2.self)!,
                apiManager: r.resolve(APIManager.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
            ))
        }.inObjectScope(.transient)

        container.register(ConfirmEmailView.self) { r in
            ConfirmEmailView(
                viewModel: ConfirmEmailViewModelImpl(
                    sessionManager: r.resolve(SessionManaging.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    logger: r.resolve(FileLogger.self)!
                ), router: r.resolve(AuthenticationNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(PreferencesMainCategoryView.self) { r in
            PreferencesMainCategoryView(
                viewModel: PreferencesMainCategoryViewModelImpl(
                    sessionManager: r.resolve(SessionManaging.self)!,
                    alertManager: r.resolve(AlertManagerV2.self)!,
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    languageManager: r.resolve(LanguageManager.self)!,
                    preferences: r.resolve(Preferences.self)!
                ), router: r.resolve(PreferencesNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(GeneralSettingsView.self) { r in
            GeneralSettingsView(viewModel: GeneralSettingsViewModelImpl(
                logger: r.resolve(FileLogger.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                languageManager: r.resolve(LanguageManager.self)!,
                preferences: r.resolve(Preferences.self)!,
                pushNotificationManager: r.resolve(PushNotificationManagerV2.self)!
            ))
        }.inObjectScope(.transient)

        container.register(AccountSettingsView.self) { r in
            AccountSettingsView(
                viewModel: AccountSettingsViewModelImpl(
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    sessionManager: r.resolve(SessionManaging.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    languageManager: r.resolve(LanguageManager.self)!,
                    logger: r.resolve(FileLogger.self)!)
            )
        }.inObjectScope(.transient)

        container.register(ConnectionSettingsView.self) { r in
           ConnectionSettingsView(
                viewModel: ConnectionSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    router: r.resolve(ConnectionsNavigationRouter.self)!,
                    protocolManager: r.resolve(ProtocolManagerType.self)!
                )
           )
        }.inObjectScope(.transient)

        container.register(NetworkSecurityView.self) { r in
            NetworkSecurityView(
                viewModel: NetworkOptionsSecurityViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    preferences: r.resolve(Preferences.self)!,
                    connectivity: r.resolve(Connectivity.self)!,
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
                    connectivity: r.resolve(Connectivity.self)!,
                    localDatabase: r.resolve(LocalDatabase.self)!,
                    vpnManager: r.resolve(VPNManager.self)!,
                    protocolManager: r.resolve(ProtocolManagerType.self)!
                )
            )
        }.inObjectScope(.transient)

        container.register(RobertSettingsView.self) { r in
            RobertSettingsView(
                viewModel: RobertSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    localDB: r.resolve(LocalDatabase.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
                )
            )
        }.inObjectScope(.transient)

        container.register(ReferForDataSettingsView.self) { r in
            ReferForDataSettingsView(
                viewModel: ReferForDataSettingsViewModelImpl(
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    sessionManager: r.resolve(SessionManaging.self)!,
                    referFriendManager: r.resolve(ReferAndShareManagerV2.self)!,
                    logger: r.resolve(FileLogger.self)!))
        }.inObjectScope(.transient)

        container.register(LookAndFeelSettingsView.self) { r in
            LookAndFeelSettingsView(
                viewModel: LookAndFeelSettingsViewModelImpl(
                    logger: r.resolve(FileLogger.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
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
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    sessionManager: r.resolve(SessionManaging.self)!,
                    apiManager: r.resolve(APIManager.self)!,
                    connectivity: r.resolve(Connectivity.self)!,
                    logger: r.resolve(FileLogger.self)!),
                router: r.resolve(HelpNavigationRouter.self)!)
        }.inObjectScope(.transient)

        container.register(SendTicketView.self) { r in
            SendTicketView(
                viewModel: SendTicketViewModelImpl(
                    apiManager: r.resolve(APIManager.self)!,
                    lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                    sessionManager: r.resolve(SessionManaging.self)!)
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
            vc.locationManagerViewModel = r.resolve(LocationManagingViewModelType.self)
            vc.staticIPListViewModel = r.resolve(StaticIPListViewModelType.self)
            vc.vpnConnectionViewModel = r.resolve(ConnectionViewModelType.self)
            vc.customConfigPickerViewModel = r.resolve(CustomConfigPickerViewModelType.self)
            vc.favNodesListViewModel = r.resolve(FavNodesListViewModelType.self)
            vc.serverListViewModel = r.resolve(ServerListViewModelType.self)
            vc.protocolSwitchViewModel = r.resolve(ProtocolSwitchDelegateViewModelType.self)
            vc.latencyViewModel = r.resolve(LatencyViewModel.self)
        }.inObjectScope(.transient)

        container.register(PlanUpgradeViewController.self) { _ in
            PlanUpgradeViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(PlanUpgradeViewModel.self)
        }.inObjectScope(.transient)

        container.register(BannedAccountPopupViewController.self) { _ in
            BannedAccountPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(BannedAccountPopupModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(OutOfDataAccountPopupViewController.self) { _ in
            OutOfDataAccountPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(OutOfDataAccountPopupModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(ProPlanExpiredPopupViewController.self) { _ in
            ProPlanExpiredPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ProPlanExpiredAccountPopupModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)

        container.register(NewsFeedView.self) { r in
            NewsFeedView(viewModel: NewsFeedViewModel(
                localDatabase: r.resolve(LocalDatabase.self)!,
                sessionManager: r.resolve(SessionManaging.self)!,
                lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
                logger: r.resolve(FileLogger.self)!,
                router: r.resolve(AccountRouter.self)!,
                htmlParser: r.resolve(HTMLParsing.self)!,
                notificationRepository: r.resolve(NotificationRepository.self)!)
            )
        }.inObjectScope(.transient)
        container.register(SetPreferredProtocolPopupViewController.self) { _ in
            SetPreferredProtocolPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(SetPreferredProtocolModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchViewController.self) { _ in
            ProtocolSwitchViewController()
        }.initCompleted { r, c in
            c.protocolManager = ProtocolManager.shared
            c.viewModel = r.resolve(ProtocolSwitchViewModelType.self)
            c.router = r.resolve(ProtocolSwitchRouter.self)
            c.type = .change
        }.inObjectScope(.transient)
        container.register(ProtocolSetPreferredViewController.self) { _ in
            ProtocolSetPreferredViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ProtocolSetPreferredViewModelV2.self)
            c.type = .connected
            c.router = r.resolve(ProtocolSwitchRouter.self)
        }.inObjectScope(.transient)
        container.register(ErrorPopupViewController.self) { _ in
            ErrorPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ErrorPopupViewModelType.self)
        }.inObjectScope(.transient)
        container.register(PrivacyViewController.self) { _ in
            PrivacyViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(PrivacyViewModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(TrustedNetworkPopupViewController.self) { _ in
            TrustedNetworkPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(TrustedNetworkPopupType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(ShakeForDataPopupViewController.self) { _ in
            ShakeForDataPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ShakeForDataPopupViewModelType.self)
            c.popupRouter = r.resolve(PopupRouter.self)
        }.inObjectScope(.transient)
        container.register(ShakeForDataViewController.self) { _ in
            ShakeForDataViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ShakeForDataViewModelType.self)
            c.popupRouter = r.resolve(PopupRouter.self)
        }.inObjectScope(.transient)
        container.register(ShakeForDataResultViewController.self) { _ in
            ShakeForDataResultViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ShakeForDataResultViewModelType.self)
            c.popupRouter = r.resolve(PopupRouter.self)
        }.inObjectScope(.transient)
        container.register(ViewLeaderboardViewController.self) { _ in
            ViewLeaderboardViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ViewLeaderboardViewModelType.self)
        }.inObjectScope(.transient)
        container.register(PushNotificationViewController.self) { _ in
            PushNotificationViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(PushNotificationViewModelType.self)
        }.inObjectScope(.transient)
        container.register(EnterCredentialsViewController.self) { _ in
            EnterCredentialsViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(EnterCredentialsViewModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(ListSelectionView.self) { _ in
            ListSelectionView()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ListSelectionViewModelType.self)
        }.inObjectScope(.transient)
        container.register(PopUpMaintenanceLocationVC.self) { _ in
            PopUpMaintenanceLocationVC()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(PopUpMaintenanceLocationModelType.self)
        }.inObjectScope(.transient)
        container.register(SendDebugLogCompletedViewController.self) { _ in
            SendDebugLogCompletedViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(SendDebugLogCompletedViewModelType.self)
        }.inObjectScope(.transient)
        container.register(LocationPermissionInfoViewController.self) { _ in
            LocationPermissionInfoViewController()
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
        container.register(ConnectionsNavigationRouter.self) { _ in
            ConnectionsNavigationRouter()
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
