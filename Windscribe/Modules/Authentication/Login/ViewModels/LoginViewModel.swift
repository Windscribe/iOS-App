//
//  LoginViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-21.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine
import UIKit

enum LoginErrorState: Equatable {
    case username(String), network(String), twoFactor(String), api(String), loginCode(String)
}

protocol LoginViewModel: ObservableObject {
    var username: String { get set }
    var password: String { get set }
    var twoFactorCode: String { get set }
    var isDarkMode: Bool { get set }
    var showLoadingView: Bool { get set }
    var failedState: LoginErrorState? { get set }
    var show2FAField: Bool { get set }
    var isContinueButtonEnabled: Bool { get }

    func continueButtonTapped()
    func generateCodeTapped()
}

class LoginViewModelImpl: LoginViewModel {

    // Published Properties
    @Published var username = ""
    @Published var password = ""
    @Published var twoFactorCode = ""

    @Published var isDarkMode: Bool = false
    @Published var showLoadingView = false
    @Published var failedState: LoginErrorState?
    @Published var show2FAField = false

    @Published var showCaptchaPopup: Bool = false
    @Published var captchaData: CaptchaPopupModel?

    private var secureToken: String = ""

    var isContinueButtonEnabled: Bool {
        username.count > 2 && password.count > 2
    }

    // Dependencies
    private let apiCallManager: APIManager
    private let preferences: Preferences
    private let userSessionRepository: UserSessionRepository
    private let emergencyConnectRepository: EmergencyRepository
    private let userDataRepository: UserDataRepository
    private let sessionManager: SessionManager
    private let vpnManager: VPNManager
    private let protocolManager: ProtocolManagerType
    private let latencyRepository: LatencyRepository
    private let connectivity: ConnectivityManager
    private let lookAndFeelRepository: LookAndFeelRepositoryType
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    /// UI Events
    var routeToMainView = PassthroughSubject<Bool, Never>()
    var showRestrictiveNetworkModal = PassthroughSubject<Bool, Never>()

    /// Initialization
    init(apiCallManager: APIManager,
         userSessionRepository: UserSessionRepository,
         sessionManager: SessionManager,
         preferences: Preferences,
         emergencyConnectRepository: EmergencyRepository,
         userDataRepository: UserDataRepository,
         vpnManager: VPNManager,
         protocolManager: ProtocolManagerType,
         latencyRepository: LatencyRepository,
         connectivity: ConnectivityManager,
         lookAndFeelRepository: LookAndFeelRepositoryType,
         logger: FileLogger) {

        self.apiCallManager = apiCallManager
        self.userSessionRepository = userSessionRepository
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.emergencyConnectRepository = emergencyConnectRepository
        self.userDataRepository = userDataRepository
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager
        self.latencyRepository = latencyRepository
        self.connectivity = connectivity
        self.lookAndFeelRepository = lookAndFeelRepository
        self.logger = logger

        bind()
        registerNetworkEventListener()
    }

    private func bind() {
        lookAndFeelRepository.isDarkModeSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isDark in
                self?.isDarkMode = isDark
            }
            .store(in: &cancellables)
    }

    func continueButtonTapped() {
        if username.contains("@") {
            failedState = .username(TextsAsset.SignInError.usernameExpectedEmailProvided)
            return
        }

        failedState = nil
        showLoadingView = true

        // iOS - iPadOS is using captcha with puzzle
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let tokenResponse = try await apiCallManager.authTokenLogin(useAsciiCaptcha: false)
                await MainActor.run {
                    self.logger.logI("LoginViewModel", "Token received: \(tokenResponse.data.token)")
                    self.secureToken = tokenResponse.data.token

                    // If CAPTCHA required
                    if let captcha = tokenResponse.data.captcha {
                        self.logger.logI("LoginViewModel", "Captcha required before login.")
                        if let popupModel = CaptchaPopupModel(from: captcha) {
                            self.captchaData = popupModel
                            self.showCaptchaPopup = true
                        } else {
                            self.logger.logE("LoginViewModel", "Failed to decode captcha images.")
                            self.failedState = .network(TextsAsset.Authentication.captchaImageDecodingFailed)
                        }
                        self.showLoadingView = false
                        return
                    }

                    // No captcha → proceed to login
                    let code2fa = self.show2FAField && !self.twoFactorCode.isEmpty ? self.twoFactorCode : ""
                    self.loginWithCredentials(
                        username: self.username,
                        password: self.password,
                        code2fa: code2fa,
                        secureToken: self.secureToken)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("LoginViewModel", "Failed to get auth token: \(error)")
                    self.failedState = .network("\(TextsAsset.Authentication.tokenRetrievalFailed) \(error)")
                    self.showLoadingView = false
                }
            }
        }
    }

    /// Submits the captcha result from the user interaction in the popup.
    /// Sends the final slider offset (`captchaSolution`) and the user's movement trails (`trailX`, `trailY`) to the server.
    func submitCaptcha(captchaSolution: CGFloat, trailX: [CGFloat], trailY: [CGFloat]) {
        // Step 1: Close the captcha popup
        showCaptchaPopup = false

        // Step 2: Show loading view while waiting for login to complete
        showLoadingView = true

        // Step 3: Determine if 2FA code should be included
        let code2fa = show2FAField ? twoFactorCode : ""

        // Step 4: Convert slider's final horizontal offset to stringified Int for backend format
        let solution = "\(Int(captchaSolution))"

        // Step 5: Call login API with all required fields including captcha metadata
        loginWithCredentials(
            username: username,
            password: password,
            code2fa: code2fa,
            secureToken: secureToken, // Provided from authTokenLogin()
            captchaSolution: solution, // X offset of the slider
            captchaTrailX: trailX, // Array of user X-axis movements
            captchaTrailY: trailY) // Array of user Y-axis movements
    }

    /// Common logic that runs after a successful login, shared between normal login and captcha login flows.
    private func handleSuccessfulLogin(session: Session) {
        // Save login time to preferences
        preferences.saveLoginDate(date: Date())

        // Cache current Wi-Fi state to use for reconnect logic
        WifiManager.shared.saveCurrentWifiNetworks()

        // Store authenticated session
        sessionManager.updateFrom(session: session)

        // Log the success with the username
        logger.logI("LoginViewModel", "Login successful, preparing user data for \(session.username)")

        // Continue with user-specific data preparation and transition to main app screen
        prepareUserData()
    }

    private func loginWithCredentials(
        username: String,
        password: String,
        code2fa: String,
        secureToken: String,
        captchaSolution: String = "",
        captchaTrailX: [CGFloat] = [],
        captchaTrailY: [CGFloat] = []) {

        Task { [weak self] in
            guard let self = self else { return }
            do {
                let session = try await apiCallManager.login(
                    username: username,
                    password: password,
                    code2fa: code2fa,
                    secureToken: secureToken,
                    captchaSolution: captchaSolution,
                    captchaTrailX: captchaTrailX,
                    captchaTrailY: captchaTrailY
                )
                await MainActor.run {
                    self.handleSuccessfulLogin(session: session)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("LoginViewModel", "Failed to login: \(error)")

                    switch error {
                    case Errors.invalid2FA:
                        self.failedState = .twoFactor(TextsAsset.twoFactorInvalidError)
                    case Errors.twoFactorRequired:
                        self.failedState = .twoFactor(TextsAsset.twoFactorRequiredError)
                        self.show2FAField = true
                    case Errors.failOverFailed:
                        self.failedState = .api("")
                        self.showRestrictiveNetworkModal.send(true)
                    case let Errors.apiError(e):
                        self.failedState = .api(e.errorMessage ?? TextsAsset.unknownAPIError)
                    default:
                        if let error = error as? Errors {
                            self.failedState = .network(error.description)
                        } else {
                            self.failedState = .network(error.localizedDescription)
                        }
                    }

                    self.showLoadingView = false
                }
            }
        }
    }
    /// Generate Code Logic
    func generateCodeTapped() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                let xpressResponse = try await apiCallManager.getXpressLoginCode()
                await MainActor.run {
                    self.twoFactorCode = xpressResponse.xPressLoginCode
                    self.startXPressLoginCodeVerifier(response: xpressResponse)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("LoginViewModel", "Unable to generate Login code.")
                    self.failedState = .loginCode(TextsAsset.TVAsset.loginCodeError)
                }
            }
        }
    }

    /// Start XPress Login Code Verifier
    private func startXPressLoginCodeVerifier(response: XPressLoginCodeResponse) {
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
                                self.logger.logI("LoginViewModel",
                                                 "Login successful with login code, Preparing user data for \(session.username)")
                                self.prepareUserData()
                                self.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                            }
                        } catch {
                            // Handle getSession error silently, just like the original code
                        }
                    } catch {
                        await MainActor.run {
                            self.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                            self.timerCancellable?.cancel()
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

    /// Invalidate Login Code
    private func invalidateLoginCode(startTime: Date, loginCodeResponse: XPressLoginCodeResponse) {
        let now = Date()
        let secondsPassed = Int(now.timeIntervalSince(startTime) * 1000)

        if secondsPassed > loginCodeResponse.ttl {
            logger.logE("LoginViewModel", "Failed to verify XPress login code in TTL. Giving up.")
            failedState = .network(TextsAsset.loginCodeExpired)
        }
    }

    /// Disconnect Emergency Connect
    func disconnectFromEmergencyConnect() {
        vpnManager.disconnectFromViewModel()
            .flatMap { _ in
                return Future<Void, Error> { promise in
                    Task {
                        self.logger.logI("LoginViewModel", "disconnectFromEmergencyConnect for getNextProtocol")
                        await self.protocolManager.refreshProtocols(shouldReset: true, shouldReconnect: false)
                        promise(.success(()))
                    }
                }
            }.sink { _ in
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    self.latencyRepository.refreshBestLocation()
                    self.latencyRepository.loadLatency()
                }
                self.showLoadingView = false
                self.routeToMainView.send(true)
            } receiveValue: { _ in }.store(in: &cancellables)
    }

    /// Prepare User Data
    private func prepareUserData() {
        userDataRepository.prepareUserData()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }

                if case let .failure(error) = completion {
                    self.preferences.saveUserSessionAuth(sessionAuth: nil)
                    self.userSessionRepository.clearSession()
                    self.logger.logE("LoginViewModel", "Failed to prepare user data: \(error)")
                    self.showLoadingView = false

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
            }, receiveValue: { [weak self] _ in
                guard let self = self else { return }

                self.logger.logI("LoginViewModel", "User data is ready")
                self.emergencyConnectRepository.cleansEmergencyConfigs()

                if self.emergencyConnectRepository.isConnected() == true {
                    logger.logI("LoginViewModel", "Disconnecting emergency connect.")
                    self.disconnectFromEmergencyConnect()
                } else {
                    self.showLoadingView = false
                    self.routeToMainView.send(true)
                }
            })
            .store(in: &cancellables)
    }

    /// Network Listener
    private func registerNetworkEventListener() {
        connectivity.network
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] appNetwork in
                if appNetwork.status == .connected {
                    self?.failedState = .none
                }
            })
            .store(in: &cancellables)
    }
}
