//
//  SignUpViewModel.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-03-02.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import Combine

enum SignUpErrorState {
    case username(String), password(String), email(String), api(String), network(String), none
}

enum SignupRoutes {
    case main, noEmail, confirmEmail, setupLater
}

protocol SignUpViewModel {
    var isPremiumUser: BehaviorSubject<Bool> { get }
    var referralViewStatus: BehaviorSubject<Bool> { get }
    var textfieldStatus: BehaviorSubject<Bool> { get }
    var showLoadingView: BehaviorSubject<Bool> { get }
    var routeTo: PublishSubject<SignupRoutes> { get }
    var isDarkMode: CurrentValueSubject<Bool, Never> { get }
    var showCaptchaViewModel: PublishSubject<CaptchaViewModel> { get }
    var failedState: BehaviorSubject<SignUpErrorState> { get }

    func continueButtonTapped(userName: String?, password: String?, email: String?, referrelUsername: String?, ignoreEmailCheck: Bool, claimAccount: Bool, voucherCode: String?)
    func setupLaterButtonTapped()
    func referralViewTapped()
    func keyBoardWillShow()
}

class SignUpViewModelImpl: SignUpViewModel {
    let isDarkMode: CurrentValueSubject<Bool, Never>
    let showCaptchaViewModel = PublishSubject<CaptchaViewModel>()
    let routeTo = PublishSubject<SignupRoutes>()
    let isPremiumUser = BehaviorSubject(value: false)
    let referralViewStatus = BehaviorSubject(value: false)
    let textfieldStatus = BehaviorSubject(value: true)
    let showLoadingView = BehaviorSubject(value: false)
    let failedState = BehaviorSubject(value: SignUpErrorState.none)
    var claimGhostAccount = false
    private var appCancellable = [AnyCancellable]()

    let apiCallManager: APIManager
    let userSessionRepository: UserSessionRepository
    let userDataRepository: UserDataRepository
    let preferences: Preferences
    let emergencyConnectRepository: EmergencyRepository
    let connectivity: ConnectivityManager
    let vpnManager: VPNManager
    let protocolManager: ProtocolManagerType
    let latencyRepository: LatencyRepository
    let logger: FileLogger
    let disposeBag = DisposeBag()

    init(apiCallManager: APIManager, userSessionRepository: UserSessionRepository, userDataRepository: UserDataRepository, preferences: Preferences, connectivity: ConnectivityManager, vpnManager: VPNManager, protocolManager: ProtocolManagerType, latencyRepository: LatencyRepository, emergencyConnectRepository: EmergencyRepository, logger: FileLogger, lookAndFeelRepository: LookAndFeelRepositoryType) {
        self.apiCallManager = apiCallManager
        self.userSessionRepository = userSessionRepository
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
            showLoadingView.onNext(false)
            failedState.onNext(.username(TextsAsset.usernameValidationError))
            return
        }
        if !isPasswordValid(password: password) {
            showLoadingView.onNext(false)
            failedState.onNext(.password(TextsAsset.passwordValidationError))
            return
        }
        if email != "" && !isEmailValid(email: email) {
            showLoadingView.onNext(false)
            failedState.onNext(.email(TextsAsset.emailValidationError))
            return
        }
        if !ignoreEmailCheck && email?.isEmpty == true {
            routeTo.onNext(.noEmail)
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
        failedState.onNext(.none)
        showLoadingView.onNext(true)
        logger.logD("SignUpViewModelImpl", "Signing up for account.")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let response = try await self.apiCallManager.authTokenSignup(useAsciiCaptcha: true)

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
                                self?.logger.logI("SignupViewModel", "Captcha login success. Preparing user data.")
                                self?.showLoadingView.onNext(true)
                                self?.handleSignupSuccess(session: session)
                            }
                            .disposed(by: self.disposeBag)

                        captchaVM.loginError
                            .observe(on: MainScheduler.instance)
                            .bind { [weak self] error in
                                self?.handleSignupError(error)
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

                await MainActor.run {
                    self.handleSignupSuccess(session: session)
                }
            } catch {
                await MainActor.run {
                    self.handleAuthTokenError(error)
                }
            }
        }
    }

    private func signUpUser(username: String, password: String, email: String, referralUsername: String, voucherCode: String) {
        showLoadingView.onNext(true)
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

                await MainActor.run {
                    self.handleSignupSuccess(session: session)
                }
            } catch {
                await MainActor.run {
                    self.handleSignupError(error)
                }
            }
        }
    }

    private func handleSignupSuccess(session: Session) {
        userSessionRepository.login(session: session)
        logger.logI("SignUpViewModelImpl", "Signup successful, Preparing user data for \(session.username)")

        prepareUserData()
    }

    private func handleAuthTokenError(_ error: Error) {
        logger.logE("SignupViewModel", "Auth token handshake failed: \(error)")
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

    private func handleSignupError(_ error: Error) {
        logger.logE("SignUpViewModelImpl", "Failed to signup: \(error)")

        showLoadingView.onNext(false)
        switch error {
        case Errors.userExists:
            failedState.onNext(.username(TextsAsset.usernameIsTaken))
        case Errors.emailExists:
            failedState.onNext(.email(TextsAsset.emailIsTaken))
        case Errors.disposableEmail:
            failedState.onNext(.email(TextsAsset.disposableEmail))
        case Errors.cannotChangeExistingEmail:
            failedState.onNext(.email(TextsAsset.cannotChangeExistingEmail))
        case let Errors.apiError(e):
            failedState.onNext(.api(e.errorMessage ?? ""))
        default:
            if let error = error as? Errors {
                failedState.onNext(.network(error.description))
            } else {
                failedState.onNext(.network(error.localizedDescription))
            }
        }
    }

    private func claimGhostAccount(username: String, password: String, email: String) {
        showLoadingView.onNext(true)
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
                    let isPro = try? self.isPremiumUser.value()
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
                _ = try await self.userSessionRepository.getUpdatedUser()

                self.showLoadingView.onNext(false)
                if email.isEmpty == false {
                    self.routeTo.onNext(.confirmEmail)
                } else {
                    self.routeTo.onNext(.main)
                }
            } catch {
                self.logger.logE("SignUpViewModelImpl", "Failed to get session. \(error)")
                self.showLoadingView.onNext(false)
                self.routeTo.onNext(.main)
            }
        }
    }

    private func disconnectFromEmergencyConnect() {
        vpnManager.disconnectFromViewModel()
            .flatMap { _ in
                return Future<Void, Error> { promise in
                    Task {
                        await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                        promise(.success(()))
                    }
                }
            }.sink { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.latencyRepository.loadLatency()
                }
                self.showLoadingView.onNext(false)
                self.routeTo.onNext(.main)
            } receiveValue: { _ in }.store(in: &appCancellable)
    }

    private func prepareUserData(ignoreError: Bool = false) {
        userDataRepository.prepareUserData().observe(on: MainScheduler.instance).subscribe(onSuccess: { [weak self] _ in
            DispatchQueue.main.async { [weak self] in
                self?.logger.logD("SignUpViewModelImpl", "User data is ready")
                self?.emergencyConnectRepository.cleansEmergencyConfigs()
                if self?.emergencyConnectRepository.isConnected() == true {
                    self?.disconnectFromEmergencyConnect()
                } else {
                    self?.showLoadingView.onNext(false)
                    self?.routeTo.onNext(.main)
                }
            }
        }, onFailure: { [weak self] error in
            self?.showLoadingView.onNext(false)
            if ignoreError {
                self?.routeTo.onNext(.main)
            } else {
                self?.preferences.saveUserSessionAuth(sessionAuth: nil)
                self?.logger.logE("SignUpViewModelImpl", "Failed to prepare user data: \(error)")

                switch error {
                case let Errors.apiError(e):
                    self?.failedState.onNext(SignUpErrorState.api(e.errorMessage ?? ""))
                default:
                    if let error = error as? Errors {
                        self?.failedState.onNext(SignUpErrorState.network(error.description))
                    } else {
                        self?.failedState.onNext(SignUpErrorState.network(error.localizedDescription))
                    }
                }

            }
        }).disposed(by: disposeBag)
    }

    func referralViewTapped() {
        if let value = try? referralViewStatus.value() {
            referralViewStatus.onNext(!value)
        }
    }

    func keyBoardWillShow() {
        failedState.onNext(.none)
    }

    func setupLaterButtonTapped() {
        routeTo.onNext(.setupLater)
    }

    private func registerNetworkEventListener() {
        connectivity.network.receive(on: DispatchQueue.main).sink { [weak self] appNetwork in
            if let loginError = try? self?.failedState.value() {
                switch loginError {
                case SignUpErrorState.network:
                    // reset network error state if network re-connects.
                    if appNetwork.status == NetworkStatus.connected {
                        self?.failedState.onNext(.none)
                    }
                default: ()
                }
            }

        }.store(in: &appCancellable)
    }

    private func checkUserStatus() {
        let isPro = userSessionRepository.user?.isPro
        isPremiumUser.onNext(isPro ?? false)
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
