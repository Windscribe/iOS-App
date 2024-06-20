//
//  AppModules.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-01-30.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject
import RealmSwift
import RxSwift

// MARK: - App
class App: Assembly {
    func assemble(container: Swinject.Container) {
        container.register(WgCredentials.self) { r in
            return WgCredentials(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(WireguardConfigRepository.self) { r in
            return WireguardConfigRepositoryImpl(apiCallManager: r.resolve(WireguardAPIManager.self)!, fileDatabase: r.resolve(FileDatabase.self)!, wgCrendentials: r.resolve(WgCredentials.self)!, alertManager: r.resolve(AlertManagerV2.self), logger: r.resolve(FileLogger.self)!)
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
            return WireguardAPIManagerImpl(api: r.resolve(WSNetServerAPI.self)!, preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Repository
class Repository: Assembly {
    func assemble(container: Container) {
        let logger = container.resolve(FileLogger.self)!
        container.register(UserRepository.self) { r in
            UserRepositoryImpl(preferences: r.resolve(Preferences.self)!, apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, vpnmanager: r.resolve(VPNManager.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(UserDataRepository.self) { r in
            return UserDataRepositoryImpl(serverRepository: r.resolve(ServerRepository.self)!, credentialsRepository: r.resolve(CredentialsRepository.self)!, portMapRepository: r.resolve(PortMapRepository.self)!, latencyRepository: r.resolve(LatencyRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!, notificationsRepository: r.resolve(NotificationRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(IPRepository.self) { r in
            IPRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(BillingRepository.self) { r in
            BillingRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(NotificationRepository.self) { r in
            NotificationRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(StaticIpRepository.self) { r in
            StaticIpRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(ServerRepository.self) { r in
            ServerRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, userRepository: r.resolve(UserRepository.self)!, preferences: r.resolve(Preferences.self)!, advanceRepository: r.resolve(AdvanceRepository.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(CredentialsRepository.self) { r in
            CredentialsRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, fileDatabase: r.resolve(FileDatabase.self)!, vpnManager: VPNManager.shared, wifiManager: WifiManager.shared, preferences: r.resolve(Preferences.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(PortMapRepository.self) { r in
            PortMapRepositoryImpl(apiManager: r.resolve(APIManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(SecuredNetworkRepository.self) { r in
            SecuredNetworkRepositoryImpl(preferences: r.resolve(Preferences.self)!, localdatabase: r.resolve(LocalDatabase.self)!, connectivity: r.resolve(Connectivity.self)!, logger: logger)
        }.inObjectScope(.userScope)
        container.register(LatencyRepository.self) { r in
            LatencyRepositoryImpl(pingManager: WSNet.instance().pingManager(), database: r.resolve(LocalDatabase.self)!, vpnManager: VPNManager.shared, logger: logger)
        }.inObjectScope(.userScope)
        container.register(EmergencyRepository.self) { r in
            return EmergencyRepositoryImpl(wsnetEmergencyConnect: WSNet.instance().emergencyConnect(), vpnManager: r.resolve(VPNManager.self)!,fileDatabase: r.resolve(FileDatabase.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(CustomConfigRepository.self) { r in
            return CustomConfigRepositoryImpl(fileDatabase: r.resolve(FileDatabase.self)!, localDatabase: r.resolve(LocalDatabase.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.userScope)
        container.register(AdvanceRepository.self) { r in
            return AdvanceRepositoryImpl(preferences: r.resolve(Preferences.self)!, vpnManager: r.resolve(VPNManager.self)!)
        }.inObjectScope(.userScope)
        container.register(ShakeDataRepository.self) { r in
            return ShakeDataRepositoryImpl(apiManager: r.resolve(APIManager.self)!,
                                           sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.userScope)
    }
}

// MARK: - Managers
class Managers: Assembly {
    func assemble(container: Container) {
        container.register(InAppPurchaseManager.self) { r in
            InAppPurchaseManagerImpl(apiManager: r.resolve(APIManager.self)!, preferences: r.resolve(Preferences.self)! , logger: r.resolve(FileLogger.self)!, localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.userScope)
        container.register(SessionManagerV2.self) { _ in
            SessionManager()
        }.inObjectScope(.userScope)
        container.register(HapticFeedbackGeneratorV2.self) { r in
            HapticFeedbackGenerator(preference: r.resolve(Preferences.self)!)
        }.inObjectScope(.userScope)
        container.register(AlertManagerV2.self) { _ in
            AlertManager()
        }.inObjectScope(.userScope)
        container.register(VPNManager.self) { _ in
            VPNManager.shared
        }.inObjectScope(.userScope)
        container.register(IKEv2VPNManager.self) { _ in
            IKEv2VPNManager.shared
        }.inObjectScope(.userScope)
        container.register(ReferAndShareManagerV2.self) { r in
            ReferAndShareManager(preferences: r.resolve(Preferences.self)!, sessionManager: r.resolve(SessionManagerV2.self)!)
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
        container.register(ConnectionStateManagerType.self) {  r in
            ConnectionStateManager(apiManager: r.resolve(APIManager.self)!, vpnManager: r.resolve(VPNManager.self)!,
                                   securedNetwork: r.resolve(SecuredNetworkRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!,
                                   logger: r.resolve(FileLogger.self)!)
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

// MARK: - Routers
class Routers: Assembly {
    func assemble(container: Container) {
        container.register(WelcomeRouter.self) { _ in
            WelcomeRouter()
        }.inObjectScope(.transient)
        container.register(HomeRouter.self) { _ in
            HomeRouter()
        }.inObjectScope(.transient)
        container.register(LoginRouter.self) { _ in
            LoginRouter()
        }.inObjectScope(.transient)
        container.register(SignupRouter.self) { _ in
            SignupRouter()
        }.inObjectScope(.transient)
        container.register(GhostAccountRouter.self) { _ in
            GhostAccountRouter()
        }.inObjectScope(.container)
        container.register(PreferenceMainRouter.self) { _ in
            PreferenceMainRouter()
        }.inObjectScope(.transient)
        container.register(AccountRouter.self) { _ in
            AccountRouter()
        }.inObjectScope(.transient)
        container.register(HelpRouter.self) { _ in
            HelpRouter()
        }.inObjectScope(.transient)
        container.register(UpgradeRouter.self) { _ in
            UpgradeRouter()
        }.inObjectScope(.transient)
        container.register(ConnectionRouter.self) { _ in
            return ConnectionRouter()
        }.inObjectScope(.transient)
        container.register(GeneralRouter.self) { _ in
            return GeneralRouter()
        }.inObjectScope(.transient)
        container.register(NetworkSecurityRouter.self) { _ in
            return NetworkSecurityRouter()
        }.inObjectScope(.transient)
        container.register(EmailRouter.self) { _ in
            return EmailRouter()
        }.inObjectScope(.transient)
        container.register(PopupRouter.self) { _ in
            return PopupRouter()
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchViewRouter.self) { _ in
            return ProtocolSwitchViewRouter()
        }.inObjectScope(.transient)
    }
}

// MARK: - ViewModels
class ViewModels: Assembly {
    func assemble(container: Container) {
        container.register(LoginViewModel.self) { r in
            return LoginViewModelImpl(apiCallManager: r.resolve(APIManager.self)!, userRepository: r.resolve(UserRepository.self)!, connectivity: r.resolve(Connectivity.self)!, preferences: r.resolve(Preferences.self)!, emergencyConnectRepository: r.resolve(EmergencyRepository.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(SignUpViewModel.self) { r in
            return SignUpViewModelImpl(apiCallManager: r.resolve(APIManager.self)!, userRepository: r.resolve(UserRepository.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, preferences: r.resolve(Preferences.self)!, connectivity: r.resolve(Connectivity.self)!, logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(WelcomeViewModal.self) { r in
            return WelcomeViewModelImpl(userRepository: r.resolve(UserRepository.self)!, keyChainDatabase: r.resolve(KeyChainDatabase.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, apiManager: r.resolve(APIManager.self)!, preferences: r.resolve(Preferences.self)!,vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(EmergenyConnectViewModal.self) { r in
            return EmergencyConnectModalImpl(vpnManager: r.resolve(VPNManager.self)!, emergencyRepository: r.resolve(EmergencyRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(AdvanceParamsViewModel.self) { r in
            AdvanceParamsViewModelImpl(preferences: r.resolve(Preferences.self)!, apiManager: r.resolve(APIManager.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(ViewLogViewModel.self) { r in
            ViewLogViewModelImpl(logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(PreferencesMainViewModel.self) { r in
            return PreferencesMainViewModelImp(sessionManager: r.resolve(SessionManagerV2.self)!, logger: r.resolve(FileLogger.self)!, alertManager: r.resolve(AlertManagerV2.self)!, themeManager: r.resolve(ThemeManager.self)!, preferences: r.resolve(Preferences.self)!, languageManager: r.resolve(LanguageManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(GeneralViewModelType.self) { r in
            return GeneralViewModel(preferences: r.resolve(Preferences.self)!, themeManager: r.resolve(ThemeManager.self)!, languageManager: r.resolve(LanguageManagerV2.self)!, pushNotificationManager: r.resolve(PushNotificationManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(AccountViewModel.self) { r in
            return AccountViewModel(apiCallManager: r.resolve(APIManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(ShareWithFriendViewModelType.self) { r in
            return ShareWithFriendViewModel(themeManager: r.resolve(ThemeManager.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, referFriendManager: r.resolve(ReferAndShareManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(ConnectionsViewModelType.self) { r in
            return ConnectionsViewModel(preferences: r.resolve(Preferences.self)!, themeManager: r.resolve(ThemeManager.self)!, localDb: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.transient)
        container.register(LanguageViewModelType.self) { r in
            return LanguageViewModel(languageManager: r.resolve(LanguageManagerV2.self)!, preferences: r.resolve(Preferences.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(AboutViewModelType.self) { r in
            return AboutViewModel(themeManager: r.resolve(ThemeManager.self)!, preference: r.resolve(Preferences.self)!)
        }.inObjectScope(.transient)
        container.register(NetworkSecurityViewModelType.self) { r in
            return NetworkSecurityViewModel(localDatabase: r.resolve(LocalDatabase.self)!, preferences: r.resolve(Preferences.self)!, themeManager: r.resolve(ThemeManager.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)
        container.register(NetworkOptionViewModelType.self) { r in
            return NetworkOptionViewModel(localDatabase: r.resolve(LocalDatabase.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(GhostAccountViewModelType.self) { r in
            return GhostAccountViewModel(sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(EnterEmailViewModel.self) { r in
            return EnterEmailViewModelImpl(sessionManager: r.resolve(SessionManagerV2.self)!, alertManager: r.resolve(AlertManagerV2.self)!, themeManager: r.resolve(ThemeManager.self)!, apiManager: r.resolve(APIManager.self)!)
        }.inObjectScope(.transient)
        container.register(ConfirmEmailViewModel.self) { r in
            return ConfirmEmailViewModelImpl(alertManager: r.resolve(AlertManagerV2.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!)
        }.inObjectScope(.transient)
        container.register(UpgradeViewModel.self) { r in
            return UpgradeViewModelImpl(alertManager: r.resolve(AlertManagerV2.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, preferences: r.resolve(Preferences.self)!, inAppManager: r.resolve(InAppPurchaseManager.self)!, pushNotificationManager: r.resolve(PushNotificationManagerV2.self)!, billingRepository: r.resolve(BillingRepository.self)!, logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(SubmitTicketViewModel.self) { r in
            return SubmitTicketViewModelImpl(apiManager: r.resolve(APIManager.self)!, themeManager: r.resolve(ThemeManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(HelpViewModel.self) { r in
            return HelpViewModelImpl(themeManager: r.resolve(ThemeManager.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, apiManager: r.resolve(APIManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)
        container.register(BannedAccountPopupModelType.self) { r in
            return BannedAccountPopupModel(popupRouter: r.resolve(PopupRouter.self), sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(OutOfDataAccountPopupModelType.self) { r in
            return OutOfDataAccountPopupModel(popupRouter: r.resolve(PopupRouter.self), sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(ProPlanExpiredAccountPopupModelType.self) { r in
            return ProPlanExpiredAccountPopupModel(popupRouter: r.resolve(PopupRouter.self), sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(SetPreferredProtocolModelType.self) { r in
            return SetPreferredProtocolModel(connectivity: r.resolve(Connectivity.self)!, networkRepository: r.resolve(SecuredNetworkRepository.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ProtocolSetPreferredViewModelV2.self) { r in
            return ProtocolSetPreferredViewModel(alertManager: r.resolve(AlertManagerV2.self)!, type: .connected, securedNetwork: r.resolve(SecuredNetworkRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(NewsFeedModelType.self) { r in
            return NewsFeedModel(notificationRepository: r.resolve(NotificationRepository.self)!,
                                 localDatabase: r.resolve(LocalDatabase.self)!, sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(PrivacyViewModelType.self) { r in
            return PrivacyViewModel(
                preferences: r.resolve(Preferences.self)!,
                networkRepository: r.resolve(SecuredNetworkRepository.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                sharedVPNManager: r.resolve(IKEv2VPNManager.self)!,
                logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(TrustedNetworkPopupType.self) { r in
            return TrustedNetworkPopup(securedNetwork: r.resolve(SecuredNetworkRepository.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ErrorPopupViewModelType.self) { _ in
            return ErrorPopupViewModel()
        }.inObjectScope(.transient)
        container.register(RobertViewModelType.self) { r in
            return RobertViewModel(apiManager: r.resolve(APIManager.self)!, localDB: r.resolve(LocalDatabase.self)!, themeManager: r.resolve(ThemeManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(EnterCredentialsViewModelType.self) { r in
            return EnterCredentialsViewModel(
                vpnManager: r.resolve(VPNManager.self)!,
                localDatabase: r.resolve(LocalDatabase.self)!,
                themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(InfoPromptViewModelType.self) { _ in
            return InfoPromptViewModel()
        }.inObjectScope(.transient)
        container.register(PushNotificationViewModelType.self) { r in
            return PushNotificationViewModel(
                logger: r.resolve(FileLogger.self)!,
                pushNotificationsManager: r.resolve(PushNotificationManagerV2.self)!
            )
        }.inObjectScope(.transient)
        container.register(MainViewModelType.self) { r in
            return MainViewModel(localDatabase: r.resolve(LocalDatabase.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!, serverRepository: r.resolve(ServerRepository.self)!, portMapRepo: r.resolve(PortMapRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!, preferences: r.resolve(Preferences.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, themeManager: r.resolve(ThemeManager.self)!, pushNotificationsManager: r.resolve(PushNotificationManagerV2.self)!, notificationsRepo: r.resolve(NotificationRepository.self)!, credentialsRepository: r.resolve(CredentialsRepository.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)
        container.register(ShakeForDataPopupViewModelType.self) { r in
            return ShakeForDataPopupViewModel(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ShakeForDataViewModelType.self) { r in
            return ShakeForDataViewModel(logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ShakeForDataResultViewModelType.self) { r in
            return ShakeForDataResultViewModel(logger: r.resolve(FileLogger.self)!,
                                               repository: r.resolve(ShakeDataRepository.self)!,
                                               preferences: r.resolve(Preferences.self)!,
                                               alertManager: r.resolve(AlertManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(ViewLeaderboardViewModelType.self) { r in
            return ViewLeaderboardViewModel(logger: r.resolve(FileLogger.self)!,
                                            repository: r.resolve(ShakeDataRepository.self)!,
                                            themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(SearchLocationsViewModelType.self) { r in
            return SearchLocationsViewModel(themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(LocationManagingViewModelType.self) { r in
            return LocationManagingViewModel(connectivityManager: r.resolve(ConnectionManagerV2.self)!, logger: r.resolve(FileLogger.self)!, connectivity: r.resolve(Connectivity.self)!, wifiManager: WifiManager.shared)
        }.inObjectScope(.transient)
        container.register(ConnectionStateViewModelType.self) { r in
            return ConnectionStateViewModel(connectionStateManager: r.resolve(ConnectionStateManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(CardTopViewModelType.self) { r in
            return CardTopViewModel(themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchViewModelType.self) { r in
            return ProtocolSwitchViewModel(themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(SendDebugLogCompletedViewModelType.self) { r in
            return SendDebugLogCompletedViewModel(themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(CustomConfigPickerViewModelType.self) { r in
            return CustomConfigPickerViewModel(logger: r.resolve(FileLogger.self)!,
                                               alertManager: r.resolve(AlertManagerV2.self)!,
                                               customConfigRepository: r.resolve(CustomConfigRepository.self)!,
                                               vpnManager: r.resolve(VPNManager.self)!,
                                               localDataBase: r.resolve(LocalDatabase.self)!,
                                               connectionStateManager: r.resolve(ConnectionStateManagerType.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)
        container.register(FavNodesListViewModelType.self) { r in
            return FavNodesListViewModel(logger: r.resolve(FileLogger.self)!,
                                         vpnManager: r.resolve(VPNManager.self)!,
                                         connectivity: r.resolve(Connectivity.self)!,
                                         connectionStateManager: r.resolve(ConnectionStateManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(ServerListViewModelType.self) { r in
            return ServerListViewModel(logger: r.resolve(FileLogger.self)!,
                                       vpnManager: r.resolve(VPNManager.self)!,
                                       connectivity: r.resolve(Connectivity.self)!,
                                       localDataBase: r.resolve(LocalDatabase.self)!,
                                       connectionStateManager: r.resolve(ConnectionStateManagerType.self)!, sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(StaticIPListViewModelType.self) { r in
            return StaticIPListViewModel(logger: r.resolve(FileLogger.self)!,
                                         vpnManager: r.resolve(VPNManager.self)!,
                                         connectionStateManager: r.resolve(ConnectionStateManagerType.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)
        container.register(ProtocolSwitchDelegateViewModelType.self) { r in
            return ProtocolSwitchDelegateViewModel(vpnManager: r.resolve(VPNManager.self)!, connectionStateManager: r.resolve(ConnectionStateManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(LatencyViewModel.self) { r in
            return LatencyViewModelImpl(latencyRepo: r.resolve(LatencyRepository.self)!, serverRepository: r.resolve(ServerRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!)
        }.inObjectScope(.transient)
        container.register(PopUpMaintenanceLocationModelType.self) { r in
            return PopUpMaintenanceLocationModel(themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
    }
}

// MARK: - ViewControllerModule
class ViewControllerModule: Assembly {
    func assemble(container: Swinject.Container) {
        container.register(MainViewController.self) { _ in
            MainViewController()
        }.initCompleted { r, vc in
            vc.router = r.resolve(HomeRouter.self)
            vc.accountRouter = r.resolve(AccountRouter.self)
            vc.popupRouter = r.resolve(PopupRouter.self)
            vc.customConfigRepository = r.resolve(CustomConfigRepository.self)
            vc.viewModel = r.resolve(MainViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.locationManagerViewModel = r.resolve(LocationManagingViewModelType.self)
            vc.staticIPListViewModel = r.resolve(StaticIPListViewModelType.self)
            vc.connectionStateViewModel = r.resolve(ConnectionStateViewModelType.self)
            vc.customConfigPickerViewModel = r.resolve(CustomConfigPickerViewModelType.self)
            vc.favNodesListViewModel = r.resolve(FavNodesListViewModelType.self)
            vc.serverListViewModel = r.resolve(ServerListViewModelType.self)
            vc.protocolSwitchViewModel = r.resolve(ProtocolSwitchDelegateViewModelType.self)
            vc.latencyViewModel = r.resolve(LatencyViewModel.self)
        }.inObjectScope(.transient)
        container.register(WelcomeViewController.self) { _ in
            WelcomeViewController()
        }.initCompleted { r, vc in
            vc.router = r.resolve(WelcomeRouter.self)
            vc.viewmodal = r.resolve(WelcomeViewModal.self)
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(LoginViewController.self) { _ in
            LoginViewController()
        }.initCompleted { r, vc in
            vc.router = r.resolve(LoginRouter.self)
            vc.viewModel = r.resolve(LoginViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(SignUpViewController.self) { _ in
            SignUpViewController()
        }.initCompleted { r, vc in
            vc.router = r.resolve(SignupRouter.self)
            vc.popupRouter = r.resolve(PopupRouter.self)
            vc.viewModel = r.resolve(SignUpViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(EmergencyConnectViewController.self) { _ in
            EmergencyConnectViewController()
        }.initCompleted { r, vc in
            vc.viewmodal = r.resolve(EmergenyConnectViewModal.self)
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(PreferencesMainViewController.self) { _ in
            PreferencesMainViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(PreferencesMainViewModel.self)
            c.router = r.resolve(PreferenceMainRouter.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(GeneralViewController.self) { _ in
            GeneralViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(GeneralViewModelType.self)
            c.logger = r.resolve(FileLogger.self)
            c.router = r.resolve(GeneralRouter.self)
            c.popupRouter = r.resolve(PopupRouter.self)
        }.inObjectScope(.transient)
        container.register(AccountViewController.self) { _ in
            AccountViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(AccountViewModel.self)
            c.router = r.resolve(AccountRouter.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(AdvanceParamsViewController.self) { _ in
            AdvanceParamsViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(AdvanceParamsViewModel.self)
        }.inObjectScope(.transient)
        container.register(HelpViewController.self) { _ in
            HelpViewController()
        }.initCompleted { r, c in
            c.router = r.resolve(HelpRouter.self)
            c.logger = r.resolve(FileLogger.self)
            c.viewModel = r.resolve(HelpViewModel.self)
        }.inObjectScope(.transient)
        container.register(ViewLogViewController.self) { _ in
            ViewLogViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ViewLogViewModel.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(LanguageViewController.self) { _ in
            LanguageViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(LanguageViewModelType.self)
        }.inObjectScope(.transient)
        container.register(AboutViewController.self) { _ in
            AboutViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(AboutViewModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(ConnectionViewController.self) { _ in
            ConnectionViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ConnectionsViewModelType.self)
            c.router = r.resolve(ConnectionRouter.self)
            c.locationManagerViewModel = r.resolve(LocationManagingViewModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(NetworkSecurityViewController.self) { _ in
            NetworkSecurityViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(NetworkSecurityViewModelType.self)
            c.router = r.resolve(NetworkSecurityRouter.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(NetworkViewController.self) { _ in
            NetworkViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(NetworkOptionViewModelType.self)
        }.inObjectScope(.transient)
        container.register(ShareWithFriendViewController.self) { _ in
            ShareWithFriendViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ShareWithFriendViewModelType.self)
        }.inObjectScope(.transient)
        container.register(EnterEmailViewController.self) { _ in
            EnterEmailViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(EnterEmailViewModel.self)
            c.router = r.resolve(EmailRouter.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(ConfirmEmailViewController.self) { _ in
            ConfirmEmailViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ConfirmEmailViewModel.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(UpgradeViewController.self) { _ in
            UpgradeViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(UpgradeViewModel.self)
            c.router = r.resolve(UpgradeRouter.self)
            c.alertManager = r.resolve(AlertManagerV2.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(SubmitTicketViewController.self) { _ in
            SubmitTicketViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(SubmitTicketViewModel.self)
            c.logger = r.resolve(FileLogger.self)
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
        container.register(ProPlanExpireddAccountPopupViewController.self) { _ in
            ProPlanExpireddAccountPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ProPlanExpiredAccountPopupModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(RobertViewController.self) { _ in
            RobertViewController()
        }.initCompleted { r, c in
            c.logger = r.resolve(FileLogger.self)
            c.viewModel = r.resolve(RobertViewModelType.self)
        }.inObjectScope(.transient)
        container.register(NewsFeedViewController.self) { _ in
            NewsFeedViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(NewsFeedModelType.self)
            c.logger = r.resolve(FileLogger.self)
            c.accountRouter = r.resolve(AccountRouter.self)
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
            c.connectionManager = ConnectionManager.shared
            c.viewModel = r.resolve(ProtocolSwitchViewModelType.self)
            c.router = r.resolve(ProtocolSwitchViewRouter.self)
            c.type = .change
        }.inObjectScope(.transient)
        container.register(ProtocolSetPreferredViewController.self) { _ in
            ProtocolSetPreferredViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(ProtocolSetPreferredViewModelV2.self)
            c.type = .connected
            c.router = r.resolve(ProtocolSwitchViewRouter.self)
        }.inObjectScope(.transient)
        container.register(ErrorPopupViewController.self) { _ in
            ErrorPopupViewController()
        }.initCompleted { r, c in
            c.viewModel = r.resolve(ErrorPopupViewModelType.self)
        }.inObjectScope(.transient)
        container.register(PrivacyViewController.self) { _ in
            PrivacyViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(PrivacyViewModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(TrustedNetworkPopupViewController.self) { _ in
            TrustedNetworkPopupViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(TrustedNetworkPopupType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(ShakeForDataPopupViewController.self) { _ in
            ShakeForDataPopupViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(ShakeForDataPopupViewModelType.self)
            c.popupRouter = r.resolve(PopupRouter.self)
        }.inObjectScope(.transient)
        container.register(ShakeForDataViewController.self) { _ in
            ShakeForDataViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(ShakeForDataViewModelType.self)
            c.popupRouter = r.resolve(PopupRouter.self)
        }.inObjectScope(.transient)
        container.register(ShakeForDataResultViewController.self) { _ in
            ShakeForDataResultViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(ShakeForDataResultViewModelType.self)
            c.popupRouter = r.resolve(PopupRouter.self)
        }.inObjectScope(.transient)
        container.register(ViewLeaderboardViewController.self) { _ in
            ViewLeaderboardViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(ViewLeaderboardViewModelType.self)
        }.inObjectScope(.transient)
        container.register(PushNotificationViewController.self) { _ in
            PushNotificationViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(PushNotificationViewModelType.self)
        }.inObjectScope(.transient)
        container.register(EnterCredentialsViewController.self) { _ in
            EnterCredentialsViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(EnterCredentialsViewModelType.self)
            c.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(InfoPromptViewController.self) { _ in
            InfoPromptViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(InfoPromptViewModelType.self)
        }.inObjectScope(.transient)
        container.register(CardHeaderContainerView.self) { _ in
            CardHeaderContainerView()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(CardTopViewModelType.self)
        }.inObjectScope(.transient)
        container.register(PopUpMaintenanceLocationVC.self) { _ in
            PopUpMaintenanceLocationVC()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(PopUpMaintenanceLocationModelType.self)
        }.inObjectScope(.transient)
        container.register(SendDebugLogCompletedViewController.self) { _ in
            SendDebugLogCompletedViewController()
        }.initCompleted { r, c in
            c.viewModel =  r.resolve(SendDebugLogCompletedViewModelType.self)
        }.inObjectScope(.transient)
        container.register(LocationPermissionDisclosureViewController.self) { _ in
            LocationPermissionDisclosureViewController()
        }.inObjectScope(.transient)
    }
}
