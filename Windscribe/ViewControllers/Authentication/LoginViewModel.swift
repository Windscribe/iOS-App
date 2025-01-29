//
//  LoginViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-27.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Swinject
import Combine

enum LoginErrorState: Equatable {
    case username(String), network(String), twoFa(String), api(String), loginCode(String)
}

protocol LoginViewModel {
    var showLoadingView: BehaviorSubject<Bool> { get }
    var failedState: BehaviorSubject<LoginErrorState?> { get }
    var show2faCodeField: BehaviorSubject<Bool> { get }
    var routeToMainView: PublishSubject<Bool> { get }
    var isDarkMode: BehaviorSubject<Bool> { get }
    var xpressCode: BehaviorSubject<String?> { get }
    func keyBoardWillShow()
    func continueButtonTapped(username: String, password: String, twoFactorCode: String?)
    func generateCodeTapped()
}

class LoginViewModelImpl: LoginViewModel {
    var xpressCode = BehaviorSubject<String?>(value: nil)
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
    let vpnManger: VPNManager
    let protocolManager: ProtocolManagerType
    let latencyRepository: LatencyRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()
    private var appCancellable = [AnyCancellable]()

    init(apiCallManager: APIManager, userRepository: UserRepository, connectivity: Connectivity, preferences: Preferences, emergencyConnectRepository: EmergencyRepository, userDataRepository: UserDataRepository,vpnManger: VPNManager, protocolManager: ProtocolManagerType, latencyRepository: LatencyRepository, logger: FileLogger, themeManager: ThemeManager) {
        self.apiCallManager = apiCallManager
        self.userRepository = userRepository
        self.connectivity = connectivity
        self.preferences = preferences
        self.emergencyConnectRepository = emergencyConnectRepository
        self.userDataRepository = userDataRepository
        self.vpnManger = vpnManger
        self.protocolManager = protocolManager
        self.latencyRepository = latencyRepository
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
                self?.preferences.saveLoginDate(date: Date())
                WifiManager.shared.saveCurrentWifiNetworks()
                self?.userRepository.login(session: session)
                self?.logger.logI(LoginViewModelImpl.self, "Login successful, Preparing user data for \(session.username)")
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
                case let Errors.apiError(e):
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

    func generateCodeTapped() {
        apiCallManager.getXpressLoginCode().observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] xpressResponse in
                self?.xpressCode.onNext(xpressResponse.xPressLoginCode)
                self?.startXPressLoginCodeVerifier(response: xpressResponse)
            }, onFailure: { [self] _ in
                self.logger.logE(self, "Unable to generate Login code. Check you network connection.")
                self.failedState.onNext(.loginCode(TvAssets.loginCodeError))
            }).disposed(by: disposeBag)
    }

    func startXPressLoginCodeVerifier(response: XPressLoginCodeResponse) {
        let startTime = Date()
        let dispose = CompositeDisposable()

        let d = Observable<Int>.interval(.seconds(5), scheduler: MainScheduler.instance)
            .subscribe(onNext: { _ in
                self.apiCallManager.verifyXPressLoginCode(code: response.xPressLoginCode, sig: response.signature)
                    .timeout(.seconds(20), scheduler: MainScheduler.instance)
                    .subscribe(onSuccess: { [self] verifyResponse in
                        if dispose.isDisposed {
                            return
                        }
                        let auth = verifyResponse.sessionAuth
                        self.apiCallManager.getSession(sessionAuth: auth).observe(on: MainScheduler.asyncInstance).subscribe(onSuccess: { [weak self] session in
                            dispose.dispose()
                            session.sessionAuthHash = auth
                            WifiManager.shared.saveCurrentWifiNetworks()
                            self?.preferences.saveLoginDate(date: Date())
                            self?.userRepository.login(session: session)
                            self?.logger.logI(LoginViewModelImpl.self, "Login successful with login code, Preparing user data for \(session.username)")
                            self?.prepareUserData()
                            self?.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                        }).disposed(by: self.disposeBag)
                    }, onFailure: { [self] error in
                        self.logger.logE(self, error.localizedDescription)
                        invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                    }).disposed(by: self.disposeBag)
            })

        _ = dispose.insert(d)
    }

    private func invalidateLoginCode(startTime: Date, loginCodeResponse: XPressLoginCodeResponse) {
        let now = Date()
        let secondsPassed = Int(now.timeIntervalSince(startTime) * 1000)
        if secondsPassed > loginCodeResponse.ttl {
            logger.logD(self, "Failed to verify XPress login code in ttl .Giving up")
            failedState.onNext(.network(""))
        }
    }

    func keyBoardWillShow() {
        failedState.onNext(.none)
    }

    private func disconnectFromEmergencyConnect() {
        vpnManger.disconnectFromViewModel()
            .flatMap { _ in
                return Future<Void, Error> { promise in
                    Task {
                        await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                        promise(.success(()))
                    }
                }
            }.sink { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.latencyRepository.refreshBestLocation()
                    self.latencyRepository.loadLatency()
                }
                self.showLoadingView.onNext(false)
                self.routeToMainView.onNext(true)
            } receiveValue: { _ in }.store(in: &appCancellable)
    }

    private func prepareUserData() {
        userDataRepository.prepareUserData().observe(on: MainScheduler.instance).subscribe(onSuccess: { [self] _ in
            logger.logD(self, "User data is ready")
            emergencyConnectRepository.cleansEmergencyConfigs()
            if emergencyConnectRepository.isConnected() == true {
                logger.logD(self, "Disconnecting emergency connect.")
                disconnectFromEmergencyConnect()
            } else {
                showLoadingView.onNext(false)
                routeToMainView.onNext(true)
            }
        }, onFailure: { [weak self] error in
            self?.preferences.saveUserSessionAuth(sessionAuth: nil)
            self?.logger.logE(LoginViewModelImpl.self, "Failed to prepare user data: \(error)")
            self?.showLoadingView.onNext(false)
            switch error {
            case let Errors.apiError(e):
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
                case LoginErrorState.network:
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
