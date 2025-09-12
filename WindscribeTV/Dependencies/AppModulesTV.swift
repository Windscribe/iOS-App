//
//  AppModulesTV.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RealmSwift
import RxSwift
import Swinject
import UIKit

typealias LocationsManagerType = LocationsManager

// MARK: - ViewModels

class TVViewModels: Assembly {
    func assemble(container: Swinject.Container) {
        container.register(LoginViewModel.self) { r in
            LoginViewModelImpl(apiCallManager: r.resolve(APIManager.self)!, userRepository: r.resolve(UserRepository.self)!, connectivity: r.resolve(Connectivity.self)!, preferences: r.resolve(Preferences.self)!, emergencyConnectRepository: r.resolve(EmergencyRepository.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, vpnManager: r.resolve(VPNManager.self)!, protocolManager: r.resolve(ProtocolManagerType.self)!, latencyRepository: r.resolve(LatencyRepository.self)!, logger: r.resolve(FileLogger.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)
        container.register(WelcomeViewModel.self) { r in
            WelcomeViewModelImpl(userRepository: r.resolve(UserRepository.self)!, keyChainDatabase: r.resolve(KeyChainDatabase.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, apiManager: r.resolve(APIManager.self)!, preferences: r.resolve(Preferences.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(SignUpViewModel.self) { r in
            SignUpViewModelImpl(apiCallManager: r.resolve(APIManager.self)!, userRepository: r.resolve(UserRepository.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, preferences: r.resolve(Preferences.self)!, connectivity: r.resolve(Connectivity.self)!, vpnManager: r.resolve(VPNManager.self)!, protocolManager: r.resolve(ProtocolManagerType.self)!, latencyRepository: r.resolve(LatencyRepository.self)!, emergencyConnectRepository: r.resolve(EmergencyRepository.self)!, logger: r.resolve(FileLogger.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)
        container.register(GeneralViewModelType.self) { r in
            GeneralViewModel(preferences: r.resolve(Preferences.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, languageManager: r.resolve(LanguageManager.self)!, pushNotificationManager: r.resolve(PushNotificationManager.self)!)
        }.inObjectScope(.transient)
        container.register(GeneralViewModelType.self) { r in
            GeneralViewModel(preferences: r.resolve(Preferences.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, languageManager: r.resolve(LanguageManager.self)!, pushNotificationManager: r.resolve(PushNotificationManager.self)!)
        }.inObjectScope(.transient)
        container.register(AccountViewModelType.self) { r in
            AccountViewModel(apiCallManager: r.resolve(APIManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, sessionManager: r.resolve(SessionManaging.self)!, logger: r.resolve(FileLogger.self)!, languageManager: r.resolve(LanguageManager.self)!, localDatabase: r.resolve(LocalDatabase.self)!)
        }.inObjectScope(.transient)
        container.register(ConnectionsViewModelType.self) { r in
            ConnectionsViewModel(preferences: r.resolve(Preferences.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, localDb: r.resolve(LocalDatabase.self)!, connectivity: r.resolve(Connectivity.self)!, networkRepository: r.resolve(SecuredNetworkRepository.self)!, languageManager: r.resolve(LanguageManager.self)!, protocolManager: r.resolve(ProtocolManagerType.self)!, dnsSettingsManager: r.resolve(DNSSettingsManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(ViewLogViewModel.self) { r in
            ViewLogViewModelImpl(logger: r.resolve(FileLogger.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
        }.inObjectScope(.transient)
        container.register(UpgradeViewModel.self) { r in
            UpgradeViewModelImpl(alertManager: r.resolve(AlertManagerV2.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!, sessionManager: r.resolve(SessionManaging.self)!, preferences: r.resolve(Preferences.self)!, inAppManager: r.resolve(InAppPurchaseManager.self)!, pushNotificationManager: r.resolve(PushNotificationManager.self)!, billingRepository: r.resolve(BillingRepository.self)!, logger: r.resolve(FileLogger.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!)
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
                                ipRepository: r.resolve(IPRepository.self)!, localDB: r.resolve(LocalDatabase.self)!,
                                customSoundPlaybackManager: r.resolve(CustomSoundPlaybackManaging.self)!)
        }.inObjectScope(.transient)
        container.register(MainViewModelType.self) { r in
            MainViewModel(localDatabase: r.resolve(LocalDatabase.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!, serverRepository: r.resolve(ServerRepository.self)!, portMapRepo: r.resolve(PortMapRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!, preferences: r.resolve(Preferences.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, pushNotificationsManager: r.resolve(PushNotificationManager.self)!, notificationsRepo: r.resolve(NotificationRepository.self)!, credentialsRepository: r.resolve(CredentialsRepository.self)!, connectivity: r.resolve(Connectivity.self)!, livecycleManager: r.resolve(LivecycleManagerType.self)!, locationsManager: r.resolve(LocationsManagerType.self)!, protocolManager: r.resolve(ProtocolManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(LatencyViewModel.self) { r in
            LatencyViewModelImpl(latencyRepo: r.resolve(LatencyRepository.self)!, serverRepository: r.resolve(ServerRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!)
        }.inObjectScope(.transient)

        container.register(BasePopupViewModelType.self) { _ in
            BasePopupViewModel()
        }.inObjectScope(.transient)

        container.register(RateUsPopupModelType.self) { r in
            RateUsPopupModel(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.transient)

        container.register(EnterEmailViewModel.self) { r in
            EnterEmailViewModelImpl(sessionManager: r.resolve(SessionManaging.self)!, alertManager: r.resolve(AlertManagerV2.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, apiManager: r.resolve(APIManager.self)!)
        }.inObjectScope(.transient)

        container.register(ConfirmEmailViewModel.self) { r in
            ConfirmEmailViewModelImpl(alertManager: r.resolve(AlertManagerV2.self)!, sessionManager: r.resolve(SessionManaging.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!)
        }.inObjectScope(.transient)

        container.register(NewsFeedModelType.self) { r in
            NewsFeedModel(
                localDatabase: r.resolve(LocalDatabase.self)!,
                sessionManager: r.resolve(SessionManaging.self)!,
                fileLogger: r.resolve(FileLogger.self)!,
                htmlParser: r.resolve(HTMLParsing.self)!)
        }.inObjectScope(.transient)

        container.register(PreferencesMainViewModelOld.self) { r in
            PreferencesMainViewModelImpOld(sessionManager: r.resolve(SessionManaging.self)!, logger: r.resolve(FileLogger.self)!, alertManager: r.resolve(AlertManagerV2.self)!, lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!, preferences: r.resolve(Preferences.self)!, languageManager: r.resolve(LanguageManager.self)!)
        }.inObjectScope(.transient)

        container.register(SubmitLogViewModel.self) { r in
            SubmitLogViewModelImpl(sessionManager: r.resolve(SessionManaging.self)!, apiManager: r.resolve(APIManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)

        container.register(PrivacyViewModelType.self) { r in
            PrivacyViewModel(preferences: r.resolve(Preferences.self)!, networkRepository: r.resolve(SecuredNetworkRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)

        container.register(OutOfDataAccountPopupModelType.self) { r in
            OutOfDataAccountPopupModel(localDatabase: r.resolve(LocalDatabase.self)!, router: r.resolve(HomeRouter.self)!)
        }.inObjectScope(.transient)
        container.register(AccountPopupModelType.self) { r in
            AccountPopupModel(localDatabase: r.resolve(LocalDatabase.self)!, router: r.resolve(HomeRouter.self)!)
        }.inObjectScope(.transient)
        container.register(ProPlanExpiredAccountPopupModelType.self) { r in
            ProPlanExpiredAccountPopupModel(localDatabase: r.resolve(LocalDatabase.self)!, router: r.resolve(HomeRouter.self)!)
        }.inObjectScope(.transient)
        container.register(BannedAccountPopupModelType.self) { r in
            BannedAccountPopupModel(localDatabase: r.resolve(LocalDatabase.self)!, router: r.resolve(HomeRouter.self)!)
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
        container.register(FavouriteListViewModelType.self) { r in
            FavouriteListViewModel(logger: r.resolve(FileLogger.self)!,
                                  vpnManager: r.resolve(VPNManager.self)!,
                                  connectivity: r.resolve(Connectivity.self)!,
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
        container.register(IPInfoViewModelType.self) { r in
            IPInfoViewModel(ipRepository: r.resolve(IPRepository.self)!,
                            preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.transient)
    }
}

// MARK: - ViewControllers

class TVViewControllers: Assembly {
    func assemble(container: Swinject.Container) {
        container.injectCore()
        // swiftlint:disable force_cast
        container.register(MainViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "MainViewController") as! MainViewController
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(MainViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.latencyViewModel = r.resolve(LatencyViewModel.self)
            vc.serverListViewModel = r.resolve(ServerListViewModelType.self)
            vc.favNodesListViewModel = r.resolve(FavouriteListViewModelType.self)
            vc.staticIPListViewModel = r.resolve(StaticIPListViewModelType.self)
            vc.vpnConnectionViewModel = r.resolve(ConnectionViewModelType.self)
            vc.ipInfoViewModel = r.resolve(IPInfoViewModelType.self)
            vc.router = r.resolve(HomeRouter.self)
        }.inObjectScope(.transient)
        container.register(WelcomeViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
        }.initCompleted { r, vc in
            vc.viewmodal = r.resolve(WelcomeViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.router = r.resolve(WelcomeRouter.self)
        }.inObjectScope(.transient)
        container.register(SignUpViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SignUpViewController") as! SignUpViewController
        }.initCompleted { r, vc in
            vc.router = r.resolve(SignupRouter.self)
            vc.viewModel = r.resolve(SignUpViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)
        container.register(LoginViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "LoginViewController") as! LoginViewController
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(LoginViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.router = r.resolve(LoginRouter.self)
        }.inObjectScope(.transient)
        container.register(ForgotPasswordViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ForgotPasswordViewController") as! ForgotPasswordViewController
        }.initCompleted { r, vc in
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)

        container.register(PreferencesMainViewController.self) { _ in
            PreferencesMainViewController(nibName: "PreferencesMainViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(PreferencesMainViewModelOld.self)
            vc.generalViewModel = r.resolve(GeneralViewModelType.self)
            vc.accountViewModel = r.resolve(AccountViewModelType.self)
            vc.connectionsViewModel = r.resolve(ConnectionsViewModelType.self)
            vc.viewLogViewModel = r.resolve(ViewLogViewModel.self)
            vc.helpViewModel = r.resolve(SubmitLogViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.router = r.resolve(HomeRouter.self)
        }.inObjectScope(.transient)

        container.register(ServerListViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServerListViewController") as! ServerListViewController
        }.initCompleted { _, _ in
        }.inObjectScope(.transient)

        container.register(UpgradePopViewController.self) { _ in UpgradePopViewController(nibName: "UpgradePopViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(UpgradeViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)

        container.register(BasePopUpViewController.self) { _ in BasePopUpViewController(nibName: "BasePopUpViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
        }.inObjectScope(.transient)

        container.register(RatePopupViewController.self) { _ in RatePopupViewController(nibName: "RatePopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.ruViewModel = r.resolve(RateUsPopupModelType.self)
        }.inObjectScope(.transient)

        container.register(GetMoreDataPopupViewController.self) { _ in GetMoreDataPopupViewController(nibName: "GetMoreDataPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.router = r.resolve(HomeRouter.self)
            vc.signupRouter = r.resolve(SignupRouter.self)
        }.inObjectScope(.transient)

        container.register(ConfirmEmailPopupViewController.self) { _ in ConfirmEmailPopupViewController(nibName: "ConfirmEmailPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.ceViewModel = r.resolve(ConfirmEmailViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.router = r.resolve(HomeRouter.self)
        }.inObjectScope(.transient)

        container.register(AddEmailPopupViewController.self) { _ in AddEmailPopupViewController(nibName: "AddEmailPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.aeViewModel = r.resolve(EnterEmailViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.router = r.resolve(HomeRouter.self)
        }.inObjectScope(.transient)

        container.register(NewsFeedViewController.self) { _ in NewsFeedViewController(nibName: "NewsFeedViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(NewsFeedModelType.self)
            vc.router = r.resolve(HomeRouter.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.alertManager = r.resolve(AlertManagerV2.self)
        }.inObjectScope(.transient)

        container.register(ServerListViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServerListViewController") as! ServerListViewController
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(MainViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.serverListViewModel = r.resolve(ServerListViewModelType.self)
            vc.router = r.resolve(ServerListRouter.self)
        }.inObjectScope(.transient)

        container.register(ServerDetailViewController.self) { _ in
            ServerDetailViewController(nibName: "ServerDetailViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(MainViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.serverListViewModel = r.resolve(ServerListViewModelType.self)
        }.inObjectScope(.transient)

        container.register(PrivacyPopUpViewController.self) { _ in PrivacyPopUpViewController(nibName: "PrivacyPopUpViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.privacyViewModel = r.resolve(PrivacyViewModelType.self)
        }.inObjectScope(.transient)

        container.register(AccountPopupViewController.self) { _ in AccountPopupViewController(nibName: "AccountPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.accountPopupViewModel = r.resolve(AccountPopupModelType.self)
        }.inObjectScope(.transient)

        container.register(BannedAccountPopupViewController.self) { _ in BannedAccountPopupViewController(nibName: "AccountPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.accountPopupViewModel = r.resolve(BannedAccountPopupModelType.self)
        }.inObjectScope(.transient)

        container.register(OutOfDataAccountPopupViewController.self) { _ in OutOfDataAccountPopupViewController(nibName: "AccountPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.accountPopupViewModel = r.resolve(OutOfDataAccountPopupModelType.self)
        }.inObjectScope(.transient)

        container.register(ProPlanExpiredAccountPopupViewController.self) { _ in ProPlanExpiredAccountPopupViewController(nibName: "AccountPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.accountPopupViewModel = r.resolve(ProPlanExpiredAccountPopupModelType.self)
        }.inObjectScope(.transient)

        // swiftlint:enable force_cast
    }
}

class TVRouters: Assembly {
    func assemble(container: Container) {
        container.register(WelcomeRouter.self) { _ in
            WelcomeRouter()
        }.inObjectScope(.transient)
        container.register(LoginRouter.self) { _ in
            LoginRouter()
        }.inObjectScope(.transient)
        container.register(SignupRouter.self) { _ in
            SignupRouter()
        }.inObjectScope(.transient)
        container.register(HomeRouter.self) { _ in
            HomeRouter()
        }
        container.register(ServerListRouter.self) { _ in
            ServerListRouter()
        }
    }
}
