//
//  LoginViewModelOld.swift
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
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var showCaptchaViewModel: PublishSubject<CaptchaViewModel> { get }

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
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let showCaptchaViewModel = PublishSubject<CaptchaViewModel>()

    let apiCallManager: APIManager
    let userSessionRepository: UserSessionRepository
    let sessionManager: SessionManager
    let connectivity: ConnectivityManager
    let preferences: Preferences
    let emergencyConnectRepository: EmergencyRepository
    let userDataRepository: UserDataRepository
    let vpnManager: VPNManager
    let protocolManager: ProtocolManagerType
    let latencyRepository: LatencyRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()

    private var appCancellable = [AnyCancellable]()
    private var timerCancellable: AnyCancellable?

    init(apiCallManager: APIManager,
         userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager,
         connectivity: ConnectivityManager,
         preferences: Preferences,
         emergencyConnectRepository: EmergencyRepository,
         userDataRepository: UserDataRepository,
         vpnManager: VPNManager,
         protocolManager: ProtocolManagerType,
         latencyRepository: LatencyRepository,
         logger: FileLogger, lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.apiCallManager = apiCallManager
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.connectivity = connectivity
        self.preferences = preferences
        self.emergencyConnectRepository = emergencyConnectRepository
        self.userDataRepository = userDataRepository
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager
        self.latencyRepository = latencyRepository
        self.logger = logger
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        registerNetworkEventListener()
    }

    func continueButtonTapped(username: String, password: String, twoFactorCode: String?) {
        failedState.onNext(.none)

        // Step 1: Validate early
        if username.contains("@") {
            failedState.onNext(.username(TextsAsset.SignInError.usernameExpectedEmailProvided))
            return
        }

        showLoadingView.onNext(true)

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let response = try await self.apiCallManager.authTokenLogin(useAsciiCaptcha: true)

                if let captcha = response.data.captcha,
                   let asciiArt = captcha.asciiArt {

                    await MainActor.run {
                        self.logger.logD("LoginViewModel", "Captcha required — creating captcha view model.")

                        let captchaVM = CaptchaViewModel(
                            asciiArtBase64: asciiArt,
                            username: username,
                            password: password,
                            twoFactorCode: twoFactorCode,
                            secureToken: response.data.token,
                            apiCallManager: self.apiCallManager,
                            logger: self.logger
                        )

                        captchaVM.isLoading
                            .distinctUntilChanged()
                            .take(until: captchaVM.captchaDismiss)
                            .bind(to: self.showLoadingView)
                            .disposed(by: self.disposeBag)

                        captchaVM.loginSuccess
                            .observe(on: MainScheduler.instance)
                            .bind { [weak self] session in
                                guard let self = self else { return }
                                self.logger.logI("LoginViewModel", "Captcha login success. Preparing user data.")
                                self.showLoadingView.onNext(true)
                                Task { @MainActor in
                                    await self.handleLoginSuccess(session: session)
                                }
                            }
                            .disposed(by: self.disposeBag)

                        captchaVM.loginError
                            .observe(on: MainScheduler.instance)
                            .bind { [weak self] error in
                                self?.handleLoginError(error)
                            }
                            .disposed(by: self.disposeBag)

                        self.showCaptchaViewModel.onNext(captchaVM)
                    }
                    return
                }

                // No captcha required, proceed with direct login
                self.logger.logD("LoginViewModel", "AuthToken succeeded. Logging in with secureToken.")
                let session = try await self.apiCallManager.login(
                    username: username,
                    password: password,
                    code2fa: twoFactorCode ?? "",
                    secureToken: response.data.token,
                    captchaSolution: "",
                    captchaTrailX: [],
                    captchaTrailY: []
                )

                await self.handleLoginSuccess(session: session)
            } catch {
                await MainActor.run {
                    self.handleAuthTokenError(error)
                }
            }
        }
    }

    private func handleLoginSuccess(session: Session) {
        preferences.saveLoginDate(date: Date())
        WifiManager.shared.saveCurrentWifiNetworks()
        sessionManager.updateFrom(session: session)
        logger.logI("LoginViewModel", "Login successful. Preparing user data for \(session.username)")

        prepareUserData()
    }

    private func handleLoginError(_ error: Error) {
        logger.logE("LoginViewModel", "Login failed: \(error)")
        showLoadingView.onNext(false)

        switch error {
        case Errors.invalid2FA:
            failedState.onNext(.twoFa(TextsAsset.twoFactorInvalidError))
        case Errors.twoFactorRequired:
            failedState.onNext(.twoFa(TextsAsset.twoFactorRequiredError))
            show2faCodeField.onNext(true)
        case let Errors.apiError(e):
            failedState.onNext(.api(e.errorMessage ?? ""))
        default:
            if let err = error as? Errors {
                failedState.onNext(.network(err.description))
            } else {
                failedState.onNext(.network(error.localizedDescription))
            }
        }
    }

    private func handleAuthTokenError(_ error: Error) {
        logger.logE("LoginViewModel", "Auth token handshake failed: \(error)")
        showLoadingView.onNext(false)

        switch error {
        case let Errors.apiError(e):
            failedState.onNext(.api(e.errorMessage ?? ""))
        default:
            if let err = error as? Errors {
                failedState.onNext(.network(err.description))
            } else {
                failedState.onNext(.network(error.localizedDescription))
            }
        }
    }

    func generateCodeTapped() {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                let xpressResponse = try await self.apiCallManager.getXpressLoginCode()
                await MainActor.run {
                    self.xpressCode.onNext(xpressResponse.xPressLoginCode)
                    self.startXPressLoginCodeVerifier(response: xpressResponse)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("LoginViewModel", "Unable to generate Login code: \(error)")
                    self.failedState.onNext(.loginCode(TextsAsset.TVAsset.loginCodeError))
                }
            }
        }
    }

    func startXPressLoginCodeVerifier(response: XPressLoginCodeResponse) {
        let startTime = Date()

        timerCancellable = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                Task { [weak self] in
                    guard let self = self else { return }
                    do {
                        let verifyResponse = try await withTimeout(seconds: 20) {
                            try await self.apiCallManager.verifyXPressLoginCode(code: response.xPressLoginCode, sig: response.signature)
                        }

                        let auth = verifyResponse.sessionAuth

                        do {
                            try await sessionManager.login(auth: auth)
                            if let session = userSessionRepository.sessionModel {
                                WifiManager.shared.saveCurrentWifiNetworks()

                                self.preferences.saveLoginDate(date: Date())
                                self.timerCancellable?.cancel()
                                self.logger.logI("LoginViewModel", "Login successful with login code, Preparing user data for \(session.username)")
                                self.prepareUserData()
                                self.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                            }
                        } catch {
                            // Handle getSession error silently, just like the original code
                        }
                    } catch {
                        await MainActor.run {
                            self.logger.logE("LoginViewModel", "Failed to verify XPress login code: \(error.localizedDescription)")
                            self.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                        }
                    }
                }
            }
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw CancellationError()
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    private func invalidateLoginCode(startTime: Date, loginCodeResponse: XPressLoginCodeResponse) {
        let now = Date()
        let secondsPassed = Int(now.timeIntervalSince(startTime))
        if secondsPassed > loginCodeResponse.ttl {
            logger.logE("LoginViewModel", "Failed to verify XPress login code in ttl. Giving up")
            failedState.onNext(.network(""))
            timerCancellable?.cancel()
        }
    }

    func keyBoardWillShow() {
        failedState.onNext(.none)
    }

    private func disconnectFromEmergencyConnect() {
        vpnManager.disconnectFromViewModel()
            .flatMap { _ in
                return Future<Void, Error> { promise in
                    Task {
                        self.logger.logI("LoginViewmodel", "disconnectFromEmergencyConnect for getNextProtocol")
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
            logger.logD("LoginViewModel", "User data is ready")
            emergencyConnectRepository.cleansEmergencyConfigs()
            if emergencyConnectRepository.isConnected() == true {
                logger.logD("LoginViewModel", "Disconnecting emergency connect.")
                disconnectFromEmergencyConnect()
            } else {
                showLoadingView.onNext(false)
                routeToMainView.onNext(true)
            }
        }, onFailure: { [weak self] error in
            self?.preferences.saveUserSessionAuth(sessionAuth: nil)
            self?.userSessionRepository.clearSession()
            self?.logger.logE("LoginViewModel", "Failed to prepare user data: \(error)")
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
        connectivity.network.receive(on: DispatchQueue.main).sink { [weak self] appNetwork in
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

        }.store(in: &appCancellable)
    }
}
