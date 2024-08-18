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
        container.register(ConnectionStateViewModelType.self) { r in
            return ConnectionStateViewModel(connectionStateManager: r.resolve(ConnectionStateManagerType.self)!)
        }.inObjectScope(.transient)
        container.register(MainViewModelType.self) { r in
            return MainViewModel(localDatabase: r.resolve(LocalDatabase.self)!, vpnManager: r.resolve(VPNManager.self)!, logger: r.resolve(FileLogger.self)!, serverRepository: r.resolve(ServerRepository.self)!, portMapRepo: r.resolve(PortMapRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!, preferences: r.resolve(Preferences.self)!, latencyRepo: r.resolve(LatencyRepository.self)!, themeManager: r.resolve(ThemeManager.self)!, pushNotificationsManager: r.resolve(PushNotificationManagerV2.self)!, notificationsRepo: r.resolve(NotificationRepository.self)!, credentialsRepository: r.resolve(CredentialsRepository.self)!, connectivity: r.resolve(Connectivity.self)!)
        }.inObjectScope(.transient)
        container.register(LatencyViewModel.self) { r in
            return LatencyViewModelImpl(latencyRepo: r.resolve(LatencyRepository.self)!, serverRepository: r.resolve(ServerRepository.self)!, staticIpRepository: r.resolve(StaticIpRepository.self)!)
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
        container.register(ServerListViewController.self) { _ in
            UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ServerListViewController") as! ServerListViewController
        }.initCompleted {  _, _ in
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
    }
}
