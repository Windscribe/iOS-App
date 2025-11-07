//
//  SignUpViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-26.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

enum SignUpErrorState: Equatable {
    case username(String), password(String), email(String), api(String), network(String), none
}

enum SignupRoutes {
    case main
    case confirmEmail
}

protocol SignUpViewModel: ObservableObject {
    var username: String { get set }
    var password: String { get set }
    var email: String { get set }
    var voucherCode: String { get set }
    var referralUsername: String { get set }
    var isDarkMode: Bool { get set }
    var isReferralVisible: Bool { get set }
    var isContinueButtonEnabled: Bool { get }
    var showLoadingView: Bool { get set }
    var failedState: SignUpErrorState { get set }
    var isPremiumUser: Bool { get }

    var routeTo: PassthroughSubject<SignupRoutes, Never> { get }

    func continueButtonTapped(ignoreEmailCheck: Bool, claimAccount: Bool)
    func referralViewTapped()
}

class SignUpViewModelImpl: SignUpViewModel {

    // Form Fields
    @Published var username: String = ""
    @Published var password: String = ""
    @Published var email: String = ""
    @Published var voucherCode: String = ""
    @Published var referralUsername: String = ""

    @Published var isDarkMode: Bool = false
    @Published var isPremiumUser: Bool = false
    @Published var isReferralVisible: Bool = false
    @Published var showLoadingView: Bool = false
    @Published var failedState: SignUpErrorState = .none

    @Published var showCaptchaPopup: Bool = false
    @Published var captchaData: CaptchaPopupModel?

    private var secureToken: String = ""

    // Routing
    let routeTo = PassthroughSubject<SignupRoutes, Never>()
    let showRestrictiveNetworkModal = PassthroughSubject<Bool, Never>()

    //  Derived States
    var isContinueButtonEnabled: Bool {
        username.count >= 3 && password.count >= 3
    }

    // Dependencies
    private let apiCallManager: APIManager
    private let userSessionRepository: UserSessionRepository
    private let userDataRepository: UserDataRepository
    private let preferences: Preferences
    private let connectivity: ConnectivityManager
    private let emergencyConnectRepository: EmergencyRepository
    private let vpnManager: VPNManager
    private let protocolManager: ProtocolManagerType
    private let latencyRepository: LatencyRepository
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()

    init(apiCallManager: APIManager,
         userSessionRepository: UserSessionRepository,
         userDataRepository: UserDataRepository,
         preferences: Preferences,
         connectivity: ConnectivityManager,
         vpnManager: VPNManager,
         protocolManager: ProtocolManagerType,
         latencyRepository: LatencyRepository,
         emergencyConnectRepository: EmergencyRepository,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger) {

        self.apiCallManager = apiCallManager
        self.userSessionRepository = userSessionRepository
        self.userDataRepository = userDataRepository
        self.preferences = preferences
        self.connectivity = connectivity
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager
        self.latencyRepository = latencyRepository
        self.emergencyConnectRepository = emergencyConnectRepository
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger

        bind()
        registerNetworkEventListener()
        checkUserStatus()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }

    // MARK: Actions

    func continueButtonTapped(ignoreEmailCheck: Bool, claimAccount: Bool) {
        // Validation
        if !isUsernameValid(username) {
            showLoadingView = false
            failedState = .username(TextsAsset.usernameValidationError)
            return
        }

        if password.count < 8 {
            showLoadingView = false
            failedState = .password(TextsAsset.passwordValidationError)
            return
        }

        if !email.isEmpty && !isEmailValid(email) {
            showLoadingView = false
            failedState = .email(TextsAsset.emailValidationError)
            return
        }

        if !ignoreEmailCheck && email.isEmpty {
            showLoadingView = false
            routeTo.send(.confirmEmail)
            return
        }

        failedState = .none
        showLoadingView = true

        if claimAccount {
            claimGhostAccount()
        } else {
            signUpUser()
        }
    }

    func referralViewTapped() {
        isReferralVisible.toggle()
    }

    // MARK: Networking

    private func signUpUser() {
        logger.logD("SignUpViewModel", "Requesting auth token for signup")
        showLoadingView = true

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let tokenResponse = try await self.apiCallManager.authTokenSignup(useAsciiCaptcha: false)

                await MainActor.run {
                    self.logger.logD("SignUpViewModel", "Token received: \(tokenResponse.data.token)")
                    self.secureToken = tokenResponse.data.token

                    // CAPTCHA required
                    if let captcha = tokenResponse.data.captcha {
                        self.logger.logI("SignUpViewModel", "Captcha required before signup.")
                        if let popupModel = CaptchaPopupModel(from: captcha) {
                            self.captchaData = popupModel
                            self.showCaptchaPopup = true
                        } else {
                            self.logger.logE("SignUpViewModel", "Failed to decode captcha images.")
                            self.failedState = .network(TextsAsset.Authentication.captchaImageDecodingFailed)
                        }
                        self.showLoadingView = false
                        return
                    }

                    // No captcha, proceed directly
                    self.signUpWithCredentials(
                        username: self.username,
                        password: self.password,
                        referringUsername: self.referralUsername,
                        email: self.email,
                        voucherCode: self.voucherCode,
                        secureToken: self.secureToken)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("SignUpViewModel", "Failed to get auth token: \(error)")
                    self.failedState = .network("\(TextsAsset.Authentication.tokenRetrievalFailed) \(error)")
                    self.showLoadingView = false
                }
            }
        }
    }

    /// Called when user completes the captcha interaction during signup.
    /// Sends the slider's final X offset (`captchaSolution`) and movement trail data to the server.
    func submitCaptcha(captchaSolution: CGFloat, trailX: [CGFloat], trailY: [CGFloat]) {
        // Step 1: Close the captcha popup
        showCaptchaPopup = false

        // Step 2: Show loading while performing signup
        showLoadingView = true

        // Step 3: Convert slider offset to backend-friendly Int string
        let solution = "\(Int(captchaSolution))"

        logger.logI("SignUpViewModel", "Submitting captcha solution with offset \(solution)")

        // Step 4: Call signup with full captcha metadata and secure token
        signUpWithCredentials(
            username: username,
            password: password,
            referringUsername: referralUsername,
            email: email,
            voucherCode: voucherCode,
            secureToken: secureToken,           // Comes from authTokenSignup
            captchaSolution: solution,          // Final X drag offset
            captchaTrailX: trailX,              // X movement samples
            captchaTrailY: trailY               // Y movement samples
        )
    }

    private func signUpWithCredentials(
        username: String,
        password: String,
        referringUsername: String,
        email: String,
        voucherCode: String,
        secureToken: String,
        captchaSolution: String = "",
        captchaTrailX: [CGFloat] = [],
        captchaTrailY: [CGFloat] = []) {
            Task { @MainActor [weak self] in
                guard let self = self else { return }

                do {
                    let session = try await self.apiCallManager.signup(
                username: username,
                password: password,
                referringUsername: referralUsername,
                email: email,
                voucherCode: voucherCode,
                secureToken: secureToken,
                captchaSolution: captchaSolution,
                captchaTrailX: captchaTrailX,
                captchaTrailY: captchaTrailY
                    )

                    await self.userSessionRepository.login(session: session)
                    await MainActor.run {
                        self.prepareUserData()
                    }
                } catch {
                    await MainActor.run {
                        self.logger.logE("SignUpViewModel", "Failed to signup: \(error)")
                        self.handleError(error)
                        self.showLoadingView = false
                    }
                }
            }
    }

    private func claimGhostAccount() {
        logger.logD("SignUpViewModel", "Claiming ghost account.")
        showLoadingView = true

        Task { [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.apiCallManager.claimAccount(username: self.username, password: self.password, email: self.email)

                await MainActor.run {
                    if self.isPremiumUser == false {
                        self.getUpdatedUser()
                    } else {
                        self.prepareUserData(ignoreError: true)
                    }
                }
            } catch {
                await MainActor.run {
                    self.logger.logD("SignUpViewModel", "Error claming account. \(error)")
                    self.handleError(error)
                }
            }
        }
    }

    private func getUpdatedUser() {
        logger.logD("SignUpViewModel", "Getting updated session.")

        Task { @MainActor [weak self] in
            guard let self = self else { return }

            do {
                _ = try await self.userSessionRepository.getUpdatedUser()

                if self.email.isEmpty == false {
                    self.routeTo.send(.confirmEmail)
                } else {
                    self.routeTo.send(.main)
                }
                self.showLoadingView = false
            } catch {
                self.logger.logE("SignUpViewModel", "Failed to get updated user: \(error)")
                self.routeTo.send(.main)
                self.showLoadingView = false
            }
        }
    }

    private func prepareUserData(ignoreError: Bool = false) {
        logger.logD("SignUpViewModel", "Preparing user data.")

        userDataRepository.prepareUserData()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] result in
                guard let self = self else { return }

                if case .failure(let error) = result {
                    if ignoreError {
                        self.routeTo.send(.main)
                    } else {
                        self.preferences.saveUserSessionAuth(sessionAuth: nil)

                        switch error {
                        case let Errors.apiError(e):
                            self.failedState = .api(e.errorMessage ?? "")
                        case Errors.failOverFailed:
                            self.showRestrictiveNetworkModal.send(true)
                            return
                        default:
                            if let error = error as? Errors {
                                self.failedState = .network(error.description)
                            } else {
                                self.failedState = .network(error.localizedDescription)
                            }
                        }
                    }
                }

                self.showLoadingView = false
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }

                self.emergencyConnectRepository.cleansEmergencyConfigs()

                if self.emergencyConnectRepository.isConnected() == true {
                    self.disconnectFromEmergencyConnect()
                } else {
                    self.routeTo.send(.main)
                    self.showLoadingView = false
                }
            }).store(in: &cancellables)
    }

    private func disconnectFromEmergencyConnect() {
        vpnManager.disconnectFromViewModel()
            .flatMap { _ in
                Future<Void, Error> { promise in
                    Task {
                        await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                        promise(.success(()))
                    }
                }
            }
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] _ in
                guard let self = self else { return }

                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.latencyRepository.loadLatency()
                }
                self.routeTo.send(.main)
                self.showLoadingView = false
            }).store(in: &cancellables)
    }

    private func handleError(_ error: Error) {
        showLoadingView = false
        switch error {
        case Errors.userExists:
            failedState = .username(TextsAsset.usernameIsTaken)
        case Errors.emailExists:
            failedState = .email(TextsAsset.emailIsTaken)
        case Errors.disposableEmail:
            failedState = .email(TextsAsset.disposableEmail)
        case Errors.cannotChangeExistingEmail:
            failedState = .email(TextsAsset.cannotChangeExistingEmail)
        case Errors.failOverFailed:
            failedState = .api("")
            showRestrictiveNetworkModal.send(true)
        case let Errors.apiError(e):
            failedState = .api(e.errorMessage ?? "")
        default:
            if let error = error as? Errors {
                failedState = .network(error.description)
            } else {
                failedState = .network(error.localizedDescription)
            }
        }
    }

    private func registerNetworkEventListener() {
        connectivity.network
            .receive(on: DispatchQueue.main)
            .sink { _ in } receiveValue: { [weak self] appNetwork in
                if case .network = self?.failedState, appNetwork.status == .connected {
                    self?.failedState = .none
                }
            }.store(in: &cancellables)
    }

    private func checkUserStatus() {
        let isPro = userSessionRepository.user?.isPro
        isPremiumUser = isPro ?? false
    }

    // Validation
    private func isUsernameValid(_ username: String) -> Bool {
        let charset = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted
        return !username.isEmpty && username.rangeOfCharacter(from: charset) == nil && username.count > 2
    }

    func isEmailValid(_ email: String) -> Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }
}
