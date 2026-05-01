//
//  LoginViewModelOld.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-02-27.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Swinject
import Combine

enum LoginErrorState: Equatable {
    case username(String), network(String), twoFa(String), api(String), loginCode(String)
}

protocol LoginViewModel {
    var showLoadingView: CurrentValueSubject<Bool, Never> { get }
    var failedState: CurrentValueSubject<LoginErrorState?, Never> { get }
    var show2faCodeField: CurrentValueSubject<Bool, Never> { get }
    var routeToMainView: PassthroughSubject<Bool, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var showCaptchaViewModel: PassthroughSubject<CaptchaViewModel, Never> { get }

    var xpressCode: CurrentValueSubject<String?, Never> { get }
    func keyBoardWillShow()
    func continueButtonTapped(username: String, password: String, twoFactorCode: String?)
    func generateCodeTapped()
}

class LoginViewModelImpl: LoginViewModel {
    var xpressCode = CurrentValueSubject<String?, Never>(nil)
    let showLoadingView = CurrentValueSubject<Bool, Never>(false)
    let stopEditing = CurrentValueSubject<Bool, Never>(false)
    let failedState = CurrentValueSubject<LoginErrorState?, Never>(nil)
    let show2faCodeField = CurrentValueSubject<Bool, Never>(false)
    let routeToMainView = PassthroughSubject<Bool, Never>()
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let showCaptchaViewModel = PassthroughSubject<CaptchaViewModel, Never>()

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
    let wifiManager: WifiManager

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
         logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         wifiManager: WifiManager) {
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
        self.wifiManager = wifiManager
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        registerNetworkEventListener()
    }

    func continueButtonTapped(username: String, password: String, twoFactorCode: String?) {
        failedState.send(.none)

        // Step 1: Validate early
        if username.contains("@") {
            failedState.send(.username(TextsAsset.SignInError.usernameExpectedEmailProvided))
            return
        }

        showLoadingView.send(true)

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let response = try await self.apiCallManager.authTokenLogin(username: username, useAsciiCaptcha: true)

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
                            isSignup: false,
                            apiCallManager: self.apiCallManager,
                            logger: self.logger
                        )

                        captchaVM.isLoading
                            .removeDuplicates()
                            .prefix(untilOutputFrom: captchaVM.captchaDismiss)
                            .sink { [weak self] isLoading in
                                self?.showLoadingView.send(isLoading)
                            }
                            .store(in: &self.appCancellable)

                        captchaVM.loginSuccess
                            .receive(on: DispatchQueue.main)
                            .sink { [weak self] session in
                                guard let self = self else { return }
                                self.logger.logI("LoginViewModel", "Captcha login success. Preparing user data.")
                                self.showLoadingView.send(true)
                                Task { @MainActor in
                                    self.handleLoginSuccess(session: session)
                                }
                            }
                            .store(in: &self.appCancellable)

                        captchaVM.loginError
                            .receive(on: DispatchQueue.main)
                            .sink { [weak self] error in
                                self?.handleLoginError(error)
                            }
                            .store(in: &self.appCancellable)

                        self.showCaptchaViewModel.send(captchaVM)
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

                self.handleLoginSuccess(session: session)
            } catch {
                await MainActor.run {
                    self.handleAuthTokenError(error)
                }
            }
        }
    }

    private func handleLoginSuccess(session: SessionModel) {
        preferences.saveLoginDate(date: Date())
        wifiManager.saveCurrentWifiNetworks()
        Task {
            // Create unmanaged Session from model (safe to use on any thread)
            await sessionManager.updateFrom(session: session)
            logger.logI("LoginViewModel", "Login successful. Preparing user data for \(session.username)")
            prepareUserData()
        }
    }

    private func handleLoginError(_ error: Error) {
        logger.logE("LoginViewModel", "Login failed: \(error)")
        showLoadingView.send(false)

        switch error {
        case Errors.invalid2FA:
            failedState.send(.twoFa(TextsAsset.twoFactorInvalidError))
        case Errors.twoFactorRequired:
            failedState.send(.twoFa(TextsAsset.twoFactorRequiredError))
            show2faCodeField.send(true)
        case let Errors.apiError(e):
            failedState.send(.api(e.errorMessage ?? ""))
        default:
            if let err = error as? Errors {
                failedState.send(.network(err.description))
            } else {
                failedState.send(.network(error.localizedDescription))
            }
        }
    }

    private func handleAuthTokenError(_ error: Error) {
        logger.logE("LoginViewModel", "Auth token handshake failed: \(error)")
        showLoadingView.send(false)

        switch error {
        case let Errors.apiError(e):
            failedState.send(.api(e.errorMessage ?? ""))
        default:
            if let err = error as? Errors {
                failedState.send(.network(err.description))
            } else {
                failedState.send(.network(error.localizedDescription))
            }
        }
    }

    func generateCodeTapped() {
        Task { [weak self] in
            guard let self = self else { return }

            do {
                let xpressResponse = try await self.apiCallManager.getXpressLoginCode()
                await MainActor.run {
                    self.xpressCode.send(xpressResponse.xPressLoginCode)
                    self.startXPressLoginCodeVerifier(response: xpressResponse)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("LoginViewModel", "Unable to generate Login code: \(error)")
                    self.failedState.send(.loginCode(TextsAsset.TVAsset.loginCodeError))
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

                            // Wait for repository update (SessionManager updates in separate Task)
                            // Use Combine to wait for the next non-nil session with 2-second timeout
                            let session: SessionModel = try await withTimeout(seconds: 2) {
                                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SessionModel, Error>) in
                                    var cancellable: AnyCancellable?
                                    cancellable = self.userSessionRepository.sessionModelSubject
                                        .compactMap { $0 }  // Filter for non-nil
                                        .first()            // Take first emission
                                        .sink { model in
                                            cancellable?.cancel()
                                            continuation.resume(returning: model)
                                        }
                                }
                            }

                            wifiManager.saveCurrentWifiNetworks()
                            self.preferences.saveLoginDate(date: Date())
                            self.timerCancellable?.cancel()
                            self.logger.logI("LoginViewModel", "Login successful with login code, Preparing user data for \(session.username)")
                            self.prepareUserData()
                            self.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)

                        } catch let error {
                            // Log and handle login errors (fixed: was silently swallowed)
                            self.logger.logE("LoginViewModel", "Lazy login failed: \(error.localizedDescription)")
                            self.timerCancellable?.cancel()
                            await MainActor.run {
                                self.failedState.send(.network(error.localizedDescription))
                            }
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
            failedState.send(.network(""))
            timerCancellable?.cancel()
        }
    }

    func keyBoardWillShow() {
        failedState.send(.none)
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
                self.showLoadingView.send(false)
                self.routeToMainView.send(true)
            } receiveValue: { _ in }.store(in: &appCancellable)
    }

    private func prepareUserData() {
        Task {
            do {
                try await userDataRepository.prepareUserData()

                logger.logD("LoginViewModel", "User data is ready")
                let wasEmergencyConnected = emergencyConnectRepository.isConnected()
                emergencyConnectRepository.cleansEmergencyConfigs()
                if wasEmergencyConnected {
                    logger.logD("LoginViewModel", "Disconnecting emergency connect.")
                    disconnectFromEmergencyConnect()
                } else {
                    showLoadingView.send(false)
                    routeToMainView.send(true)
                }
            } catch {
                preferences.clearSessionAuth()
                userSessionRepository.clearSession()
                logger.logE("LoginViewModel", "Failed to prepare user data: \(error)")
                showLoadingView.send(false)
                switch error {
                case let Errors.apiError(e):
                    failedState.send(.api(e.errorMessage ?? ""))
                default:
                    if let error = error as? Errors {
                        failedState.send(.network(error.description))
                    } else {
                        failedState.send(.network(error.localizedDescription))
                    }
                }
            }
        }
    }

    private func registerNetworkEventListener() {
        connectivity.network.receive(on: DispatchQueue.main).sink { [weak self] appNetwork in
            if let loginError = self?.failedState.value {
                switch loginError {
                case LoginErrorState.network:
                    // reset network error state if network re-connects.
                    if appNetwork.status == NetworkStatus.connected {
                        self?.failedState.send(.none)
                    }
                default: ()
                }
            }

        }.store(in: &appCancellable)
    }
}
