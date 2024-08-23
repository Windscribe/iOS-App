//
//  AppModulesTV.swift
//  WindscribeTV
//
//  Created by Bushra Sagir on 08/07/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject
import RealmSwift
import RxSwift
import UIKit

// MARK: - ViewModels
class TVViewModels: Assembly {
    func assemble(container: Swinject.Container) {
        container.register(LoginViewModel.self) { r in
            return LoginViewModelImpl(apiCallManager: r.resolve(APIManager.self)!, userRepository: r.resolve(UserRepository.self)!, connectivity: r.resolve(Connectivity.self)!, preferences: r.resolve(Preferences.self)!, emergencyConnectRepository: r.resolve(EmergencyRepository.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(WelcomeViewModal.self) { r in
            return WelcomeViewModelImpl(userRepository: r.resolve(UserRepository.self)!, keyChainDatabase: r.resolve(KeyChainDatabase.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, apiManager: r.resolve(APIManager.self)!, preferences: r.resolve(Preferences.self)!,vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(SignUpViewModel.self) { r in
            return SignUpViewModelImpl(apiCallManager: r.resolve(APIManager.self)!, userRepository: r.resolve(UserRepository.self)!, userDataRepository: r.resolve(UserDataRepository.self)!, preferences: r.resolve(Preferences.self)!, connectivity: r.resolve(Connectivity.self)!, logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(GeneralViewModelType.self) { r in
            return GeneralViewModel(preferences: r.resolve(Preferences.self)!, themeManager: r.resolve(ThemeManager.self)!, languageManager: r.resolve(LanguageManagerV2.self)!, pushNotificationManager: r.resolve(PushNotificationManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(GeneralViewModelType.self) { r in
            return GeneralViewModel(preferences: r.resolve(Preferences.self)!, themeManager: r.resolve(ThemeManager.self)!, languageManager: r.resolve(LanguageManagerV2.self)!, pushNotificationManager: r.resolve(PushNotificationManagerV2.self)!)
        }.inObjectScope(.transient)
        container.register(AccountViewModelType.self) { r in
            return AccountViewModel(apiCallManager: r.resolve(APIManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, themeManager: r.resolve(ThemeManager.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, logger: r.resolve(FileLogger.self)!)
        }.inObjectScope(.transient)
        container.register(ConnectionsViewModelType.self) { r in
            return ConnectionsViewModel(preferences: r.resolve(Preferences.self)!, themeManager: r.resolve(ThemeManager.self)!, localDb: r.resolve(LocalDatabase.self)!, connectivity: r.resolve(Connectivity.self)!, networkRepository: r.resolve(SecuredNetworkRepository.self)!)
        }.inObjectScope(.transient)
        container.register(ViewLogViewModel.self) { r in
            return ViewLogViewModelImpl(logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(UpgradeViewModel.self) { r in
            return UpgradeViewModelImpl(alertManager: r.resolve(AlertManagerV2.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, preferences: r.resolve(Preferences.self)!, inAppManager: r.resolve(InAppPurchaseManager.self)!, pushNotificationManager: r.resolve(PushNotificationManagerV2.self)!, billingRepository: r.resolve(BillingRepository.self)!, logger: r.resolve(FileLogger.self)!, themeManager: r.resolve(ThemeManager.self)!)
        }.inObjectScope(.transient)
        container.register(ConnectionStateViewModelType.self) { r in
            return ConnectionStateViewModel(connectionStateManager: r.resolve(ConnectionStateManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(MainViewModelType.self) { r in
            return MainViewModel(localDatabase: r.resolve(LocalDatabase.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!, serverRepository: r.resolve(ServerRepository.self)!, portMapRepo: r.resolve(PortMapRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!, preferences: r.resolve(Preferences.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, themeManager: r.resolve(ThemeManager.self)!, pushNotificationsManager: r.resolve(PushNotificationManagerV2.self)!, notificationsRepo: r.resolve(NotificationRepository.self)!, credentialsRepository: r.resolve(CredentialsRepository.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)
        container.register(LatencyViewModel.self) { r in
            return LatencyViewModelImpl(latencyRepo: r.resolve(LatencyRepository.self)!, serverRepository: r.resolve(ServerRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!)
        }.inObjectScope(.transient)
        
        container.register(BasePopupViewModelType.self) { r in
            return BasePopupViewModel()
        }.inObjectScope(.transient)
        
        container.register(RateUsPopupModelType.self) { r in
            return RateUsPopupModel(preferences: r.resolve(Preferences.self)!)
        }.inObjectScope(.transient)
        
        container.register(EnterEmailViewModel.self) { r in
            return EnterEmailViewModelImpl(sessionManager: r.resolve(SessionManagerV2.self)!, alertManager: r.resolve(AlertManagerV2.self)!, themeManager: r.resolve(ThemeManager.self)!, apiManager: r.resolve(APIManager.self)!)
        }.inObjectScope(.transient)
        
        container.register(ConfirmEmailViewModel.self) { r in
            return ConfirmEmailViewModelImpl(alertManager: r.resolve(AlertManagerV2.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, localDatabase: r.resolve(LocalDatabase.self)!, apiManager: r.resolve(APIManager.self)!)
        }.inObjectScope(.transient)
        
        container.register(NewsFeedModelType.self) { r in
            return NewsFeedModel(notificationRepository: r.resolve(NotificationRepository.self)!, localDatabase: r.resolve(LocalDatabase.self)!, sessionManager: r.resolve(SessionManagerV2.self)!)
        }.inObjectScope(.transient)
 
		container.register(PreferencesMainViewModel.self) { r in
            return PreferencesMainViewModelImp(sessionManager: r.resolve(SessionManagerV2.self)!, logger: r.resolve(FileLogger.self)!, alertManager: r.resolve(AlertManagerV2.self)!, themeManager: r.resolve(ThemeManager.self)!, preferences: r.resolve(Preferences.self)!, languageManager: r.resolve(LanguageManagerV2.self)!)
        }.inObjectScope(.transient)
        
        container.register(HelpViewModel.self) { r in
            return HelpViewModelImpl(themeManager: r.resolve(ThemeManager.self)!, sessionManager: r.resolve(SessionManagerV2.self)!, apiManager: r.resolve(APIManager.self)!, alertManager: r.resolve(AlertManagerV2.self)!, connectivity: r.resolve(Connectivity.self)!)
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
        }.initCompleted {  r, vc in
            vc.viewModel = r.resolve(MainViewModelType.self)
            vc.connectionStateViewModel = r.resolve(ConnectionStateViewModelType.self)
            vc.logger =  r.resolve(FileLogger.self)
            vc.latencyViewModel = r.resolve(LatencyViewModel.self)
            vc.router = r.resolve(HomeRouter.self)
        }.inObjectScope(.transient)
        container.register(WelcomeViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "WelcomeViewController") as! WelcomeViewController
        }.initCompleted {  r, vc in
            vc.viewmodal = r.resolve(WelcomeViewModal.self)
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
        }.initCompleted {  _, _ in

        }.inObjectScope(.transient)

        container.register(PreferencesMainViewController.self) { _ in
            PreferencesMainViewController(nibName: "PreferencesMainViewController", bundle: nil)
        }.initCompleted {  r, vc in
            vc.viewModel = r.resolve(PreferencesMainViewModel.self)
            vc.generalViewModel = r.resolve(GeneralViewModelType.self)
            vc.accountViewModel = r.resolve(AccountViewModelType.self)
            vc.connectionsViewModel = r.resolve(ConnectionsViewModelType.self)
            vc.viewLogViewModel = r.resolve(ViewLogViewModel.self)
            vc.helpViewModel = r.resolve(HelpViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
            vc.router = r.resolve(HomeRouter.self)
        }.inObjectScope(.transient)
        
        container.register(ServerListViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServerListViewController") as! ServerListViewController
        }.initCompleted {  _, _ in
        }.inObjectScope(.transient)
        
        container.register(UpgradePopViewController.self) { _ in UpgradePopViewController(nibName: "UpgradePopViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(UpgradeViewModel.self)
        }.inObjectScope(.transient)
        
        container.register(BasePopUpViewController.self) { _ in BasePopUpViewController(nibName: "BasePopUpViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
        }.inObjectScope(.transient)
        
        container.register(RatePopupViewController.self) { _ in RatePopupViewController(nibName: "RatePopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.ruViewModel = r.resolve(RateUsPopupModelType.self)
        }.inObjectScope(.transient)
        
        container.register(GetMoreDataPopupViewController.self) { _ in GetMoreDataPopupViewController(nibName: "GetMoreDataPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.router = r.resolve(HomeRouter.self)
            vc.signupRouter = r.resolve(SignupRouter.self)
        }.inObjectScope(.transient)
        
        container.register(ConfirmEmailPopupViewController.self) { _ in ConfirmEmailPopupViewController(nibName: "ConfirmEmailPopupViewController", bundle: nil)
        }.initCompleted { r, vc in
            vc.viewModel = r.resolve(BasePopupViewModelType.self)
            vc.ceViewModel = r.resolve(ConfirmEmailViewModel.self)
            vc.logger = r.resolve(FileLogger.self)
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
    }
}
