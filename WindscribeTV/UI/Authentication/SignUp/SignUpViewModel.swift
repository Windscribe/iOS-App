//
//  SignUpViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-03-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum SignUpErrorState {
    case username(String), password(String), email(String), api(String), network(String), none
}

enum SignupRoutes {
    case main, noEmail, confirmEmail, setupLater
}

protocol SignUpViewModel {
    var isPremiumUser: CurrentValueSubject<Bool, Never> { get }
    var referralViewStatus: CurrentValueSubject<Bool, Never> { get }
    var textfieldStatus: CurrentValueSubject<Bool, Never> { get }
    var showLoadingView: CurrentValueSubject<Bool, Never> { get }
    var routeTo: PassthroughSubject<SignupRoutes, Never> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var showCaptchaViewModel: PassthroughSubject<CaptchaViewModel, Never> { get }
    var failedState: CurrentValueSubject<SignUpErrorState, Never> { get }

    func continueButtonTapped(userName: String?, password: String?, email: String?, referrelUsername: String?, ignoreEmailCheck: Bool, claimAccount: Bool, voucherCode: String?)
    func setupLaterButtonTapped()
    func referralViewTapped()
    func keyBoardWillShow()
}

class SignUpViewModelImpl: SignUpViewModel {
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let showCaptchaViewModel = PassthroughSubject<CaptchaViewModel, Never>()
    let routeTo = PassthroughSubject<SignupRoutes, Never>()
    let isPremiumUser = CurrentValueSubject<Bool, Never>(false)
    let referralViewStatus = CurrentValueSubject<Bool, Never>(false)
    let textfieldStatus = CurrentValueSubject<Bool, Never>(true)
    let showLoadingView = CurrentValueSubject<Bool, Never>(false)
    let failedState = CurrentValueSubject<SignUpErrorState, Never>(.none)
    var claimGhostAccount = false
    private var appCancellable = [AnyCancellable]()

    let apiCallManager: APIManager
    let userSessionRepository: UserSessionRepository
    let sessionManager: SessionManager
    let userDataRepository: UserDataRepository
    let preferences: Preferences
    let emergencyConnectRepository: EmergencyRepository
    let connectivity: ConnectivityManager
    let vpnManager: VPNManager
    let protocolManager: ProtocolManagerType
    let latencyRepository: LatencyRepository
    let logger: FileLogger

    init(apiCallManager: APIManager,
         userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager,
         userDataRepository: UserDataRepository,
         preferences: Preferences,
         connectivity: ConnectivityManager,
         vpnManager: VPNManager,
         protocolManager: ProtocolManagerType,
         latencyRepository: LatencyRepository,
         emergencyConnectRepository: EmergencyRepository,
         logger: FileLogger,
         lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.apiCallManager = apiCallManager
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.userDataRepository = userDataRepository
        self.preferences = preferences
        self.connectivity = connectivity
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager
        self.latencyRepository = latencyRepository
        self.emergencyConnectRepository = emergencyConnectRepository
        self.logger = logger
        isDarkMode = lookAndFeelRepository.isDarkModeSubject
        registerNetworkEventListener()
        checkUserStatus()
    }

    func continueButtonTapped(userName: String?, password: String?, email: String?, referrelUsername: String?, ignoreEmailCheck: Bool, claimAccount: Bool, voucherCode: String?) {
        // Validate all inputs.
        if !isUsernameValid(username: userName) {
            showLoadingView.send(false)
            failedState.send(.username(TextsAsset.usernameValidationError))
            return
        }
        if !isPasswordValid(password: password) {
            showLoadingView.send(false)
            failedState.send(.password(TextsAsset.passwordValidationError))
            return
        }
        if email != "" && !isEmailValid(email: email) {
            showLoadingView.send(false)
            failedState.send(.email(TextsAsset.emailValidationError))
            return
        }
        if !ignoreEmailCheck && email?.isEmpty == true {
            routeTo.send(.noEmail)
            return
        }
        // A ghost account without username is created.
        if claimAccount {
            claimGhostAccount(username: userName ?? "", password: password ?? "", email: email ?? "")
        } else {
            signUpUser(username: userName ?? "", password: password ?? "", email: email ?? "", referralUsername: referrelUsername ?? "", voucherCode: voucherCode ?? "")
        }
    }

    func continueButtonTapped(username: String, password: String, twoFactorCode: String?) {
        failedState.send(.none)
        showLoadingView.send(true)
        logger.logD("SignUpViewModelImpl", "Signing up for account.")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let response = try await self.apiCallManager.authTokenSignup(username: username, useAsciiCaptcha: true)

                if let captcha = response.data.captcha,
                   let asciiArt = captcha.asciiArt {

                    await MainActor.run {
                        self.logger.logD("SignupViewModel", "Captcha required — creating captcha view model.")

                        let captchaVM = CaptchaViewModel(
                            asciiArtBase64: asciiArt,
                            username: username,
                            password: password,
                            twoFactorCode: twoFactorCode,
                            secureToken: response.data.token,
                            isSignup: true,
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
                                self.logger.logI("SignupViewModel", "Captcha login success. Preparing user data.")
                                self.showLoadingView.send(true)
                                Task { @MainActor in
                                    await self.handleSignupSuccess(session: session)
                                }
                            }
                            .store(in: &self.appCancellable)

                        captchaVM.loginError
                            .receive(on: DispatchQueue.main)
                            .sink { [weak self] error in
                                self?.handleSignupError(error)
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

                await self.handleSignupSuccess(session: session)
            } catch {
                await MainActor.run {
                    self.handleAuthTokenError(error)
                }
            }
        }
    }

    private func signUpUser(username: String, password: String, email: String, referralUsername: String, voucherCode: String) {
        showLoadingView.send(true)
        logger.logD("SignUpViewModelImpl", "Signing up for account.")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let session = try await self.apiCallManager.signup(
                    username: username,
                    password: password,
                    referringUsername: referralUsername,
                    email: email,
                    voucherCode: voucherCode,
                    secureToken: "",
                    captchaSolution: "",
                    captchaTrailX: [],
                    captchaTrailY: []
                )

                await self.handleSignupSuccess(session: session)
            } catch {
                await MainActor.run {
                    self.handleSignupError(error)
                }
            }
        }
    }

    private func handleSignupSuccess(session: SessionModel) async {
        Task {
            await sessionManager.updateFrom(session: session)
            logger.logI("SignUpViewModelImpl", "Signup successful, Preparing user data for \(session.username)")
            prepareUserData()
        }
    }

    private func handleAuthTokenError(_ error: Error) {
        logger.logE("SignupViewModel", "Auth token handshake failed: \(error)")
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

    private func handleSignupError(_ error: Error) {
        logger.logE("SignUpViewModelImpl", "Failed to signup: \(error)")

        showLoadingView.send(false)
        switch error {
        case Errors.userExists:
            failedState.send(.username(TextsAsset.usernameIsTaken))
        case Errors.emailExists:
            failedState.send(.email(TextsAsset.emailIsTaken))
        case Errors.disposableEmail:
            failedState.send(.email(TextsAsset.disposableEmail))
        case Errors.cannotChangeExistingEmail:
            failedState.send(.email(TextsAsset.cannotChangeExistingEmail))
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

    private func claimGhostAccount(username: String, password: String, email: String) {
        showLoadingView.send(true)
        logger.logD("SignUpViewModelImpl", "Claiming account.")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiCallManager.claimAccount(
                    username: username,
                    password: password,
                    email: email
                )

                await MainActor.run {
                    let isPro = self.isPremiumUser.value
                    if isPro == false {
                        self.getUpdatedUser(email: email)
                    } else {
                        self.logger.logD("SignUpViewModelImpl", "Getting user data.")
                        self.prepareUserData(ignoreError: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.logger.logD("SignUpViewModelImpl", "Error claming account. \(error)")
                    self.handleSignupError(error)
                }
            }
        }
    }

    private func getUpdatedUser(email: String) {
        logger.logD("SignUpViewModelImpl", "Getting updated session.")

        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                try await self.sessionManager.updateSession()

                self.showLoadingView.send(false)
                if email.isEmpty == false {
                    self.routeTo.send(.confirmEmail)
                } else {
                    self.routeTo.send(.main)
                }
            } catch {
                self.logger.logE("SignUpViewModelImpl", "Failed to get session. \(error)")
                self.showLoadingView.send(false)
                self.routeTo.send(.main)
            }
        }
    }

    private func disconnectFromEmergencyConnect() {
        vpnManager.disconnectFromViewModel()
            .flatMap { _ in
                return Future<Void, Error> { promise in
                    Task {
                        self.logger.logI("SignUpViewModel", "disconnectFromEmergencyConnect for getNextProtocol")
                        await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                        promise(.success(()))
                    }
                }
            }.sink { _ in
                self.showLoadingView.send(false)
                self.routeTo.send(.main)
            } receiveValue: { _ in }.store(in: &appCancellable)
    }

    private func prepareUserData(ignoreError: Bool = false) {
        Task {
            do {
                try await userDataRepository.prepareUserData()

                logger.logD("SignUpViewModelImpl", "User data is ready")
                let wasEmergencyConnected = emergencyConnectRepository.isConnected()
                emergencyConnectRepository.cleansEmergencyConfigs()
                if wasEmergencyConnected {
                    disconnectFromEmergencyConnect()
                } else {
                    showLoadingView.send(false)
                    routeTo.send(.main)
                }
            } catch {
                showLoadingView.send(false)
                if ignoreError {
                    routeTo.send(.main)
                } else {
                    preferences.clearSessionAuth()
                    userSessionRepository.clearSession()
                    logger.logE("SignUpViewModelImpl", "Failed to prepare user data: \(error)")

                    switch error {
                    case let Errors.apiError(e):
                        failedState.send(SignUpErrorState.api(e.errorMessage ?? ""))
                    default:
                        if let error = error as? Errors {
                            failedState.send(SignUpErrorState.network(error.description))
                        } else {
                            failedState.send(SignUpErrorState.network(error.localizedDescription))
                        }
                    }
                }
            }
        }
    }

    func referralViewTapped() {
        let value = referralViewStatus.value
        referralViewStatus.send(!value)
    }

    func keyBoardWillShow() {
        failedState.send(.none)
    }

    func setupLaterButtonTapped() {
        routeTo.send(.setupLater)
    }

    private func registerNetworkEventListener() {
        connectivity.network.receive(on: DispatchQueue.main).sink { [weak self] appNetwork in
            if let loginError = self?.failedState.value {
                switch loginError {
                case SignUpErrorState.network:
                    // reset network error state if network re-connects.
                    if appNetwork.status == NetworkStatus.connected {
                        self?.failedState.send(.none)
                    }
                default: ()
                }
            }

        }.store(in: &appCancellable)
    }

    private func checkUserStatus() {
        let isPro = userSessionRepository.sessionModel?.isUserPro
        isPremiumUser.send(isPro ?? false)
    }

    private func isUsernameValid(username: String?) -> Bool {
        guard let username = username else { return false }
        let set = NSCharacterSet(charactersIn: "ABCDEFGHIJKLMONPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_").inverted
        if username.rangeOfCharacter(from: set) == nil {
            if username.count > 2 {
                return true
            }
        }
        return false
    }

    private func isPasswordValid(password: String?) -> Bool {
        guard let password = password?.trimmingCharacters(in: .whitespacesAndNewlines) else { return false }
        if password.count > 7 {
            return true
        }
        return false
    }

    private func isEmailValid(email: String?) -> Bool {
        guard let email = email else { return false }
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
}
