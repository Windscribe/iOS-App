//
//  LoginViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-27.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
enum LoginErrorState: Equatable {
    case username(String), network(String), twoFa(String), api(String)
}
protocol LoginViewModel {
    var showLoadingView: BehaviorSubject<Bool> { get }
    var failedState: BehaviorSubject<LoginErrorState?> { get }
    var show2faCodeField: BehaviorSubject<Bool> { get }
    var routeToMainView: PublishSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    func keyBoardWillShow()
    func continueButtonTapped(username: String, password: String, twoFactorCode: String?)
}
class LoginViewModelImpl: LoginViewModel {
    let showLoadingView = BehaviorSubject(value: false)
    let stopEditing = BehaviorSubject(value: false)
    let failedState = BehaviorSubject<LoginErrorState?>(value: nil)
    let show2faCodeField = BehaviorSubject(value: false)
    let routeToMainView = PublishSubject<Bool>()
    let isDarkMode: BehaviorSubject<Bool>

    let apiCallManager: APIManager
    let userRepository: UserRepository
    let connectivity: Connectivity
    let preferences: Preferences
    let emergencyConnectRepository: EmergencyRepository
    let userDataRepository: UserDataRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()

    init(apiCallManager: APIManager, userRepository: UserRepository, connectivity: Connectivity, preferences: Preferences, emergencyConnectRepository: EmergencyRepository, userDataRepository: UserDataRepository, logger: FileLogger, themeManager: ThemeManager) {
        self.apiCallManager = apiCallManager
        self.userRepository = userRepository
        self.connectivity = connectivity
        self.preferences = preferences
        self.emergencyConnectRepository = emergencyConnectRepository
        self.userDataRepository = userDataRepository
        self.logger = logger
        isDarkMode = themeManager.darkTheme
        registerNetworkEventListener()
    }

    func continueButtonTapped(username: String, password: String, twoFactorCode: String? = "") {
        failedState.onNext(.none)
        if username.contains("@") {
            failedState.onNext(LoginErrorState.username(TextsAsset.SignInError.usernameExpectedEmailProvided))
            return
        }
        showLoadingView.onNext(true)
        logger.logD(self, "Logging in user.")
        apiCallManager.login(username: username, password: password, code2fa: twoFactorCode ?? "").observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] session in
                WifiManager.shared.configure()
                self?.userRepository.login(session: session)
                self?.logger.logE(LoginViewModelImpl.self, "Login successful, Preparing user data for \(session.username)")
                self?.prepareUserData()
            }, onFailure: { [weak self] error in
                self?.logger.logE(LoginViewModelImpl.self, "Failed to login: \(error)")
                self?.showLoadingView.onNext(false)
                switch error {
                case Errors.invalid2FA:
                    self?.failedState.onNext(.twoFa(TextsAsset.twoFactorInvalidError))
                case Errors.twoFactorRequired:
                    self?.failedState.onNext(.twoFa(TextsAsset.twoFactorRequiredError))
                    self?.show2faCodeField.onNext(true)
                case Errors.apiError(let e):
                    self?.failedState.onNext(.api(e.errorMessage ?? ""))
                default:
                    if let error = error as? Errors {
                        self?.failedState.onNext(.network(error.description))
                    } else {
                        self?.failedState.onNext(.network(error.localizedDescription))
                    }
                }
            }).disposed(by: disposeBag)
    }

    func keyBoardWillShow() {
        failedState.onNext(.none)
    }

    private func prepareUserData() {
        userDataRepository.prepareUserData().observe(on: MainScheduler.instance).subscribe(onSuccess: { [self] _ in
            logger.logD(self, "User data is ready")
            showLoadingView.onNext(false)
            if emergencyConnectRepository.isConnected() == true {
                logger.logD(self, "Disconnecting emergency connect.")
                emergencyConnectRepository.removesConfig()
                emergencyConnectRepository.removeProfile().subscribe(onCompleted: {
                    self.routeToMainView.onNext(true)
                }).disposed(by: disposeBag)
            } else {
                routeToMainView.onNext(true)
            }
        }, onFailure: { [weak self] error in
            self?.preferences.saveUserSessionAuth(sessionAuth: nil)
            self?.logger.logE(LoginViewModelImpl.self, "Failed to prepare user data: \(error)")
            self?.showLoadingView.onNext(false)
            switch error {
            case Errors.apiError(let e):
                self?.failedState.onNext(.api(e.errorMessage ?? ""))
            default:
                if let error = error as? Errors {
                    self?.failedState.onNext(.network(error.description))
                } else {
                    self?.failedState.onNext(.network(error.localizedDescription))
                }
            }
        }).disposed(by: disposeBag)
    }

    private func registerNetworkEventListener() {
        connectivity.network.observe(on: MainScheduler.instance).subscribe(onNext: { [weak self] appNetwork in
            if let loginError = try? self?.failedState.value() {
                switch loginError {
                case LoginErrorState.network(_):
                    // reset network error state if network re-connects.
                    if appNetwork.status == NetworkStatus.connected {
                        self?.failedState.onNext(.none)
                    }
                default: ()
                }
            }

        }).disposed(by: disposeBag)
    }
}
