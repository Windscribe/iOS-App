//
//  LoginViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-03-21.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
import Combine

enum LoginErrorState: Equatable {
    case username(String), network(String), twoFactor(String), api(String), loginCode(String)
}

protocol LoginViewModel: ObservableObject {
    var username: String { get set }
    var password: String { get set }
    var twoFactorCode: String { get set }
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

    @Published var showLoadingView = false
    @Published var failedState: LoginErrorState?
    @Published var show2FAField = false

    var isContinueButtonEnabled: Bool {
        username.count > 2 && password.count > 2
    }

    // Dependencies
    private let apiCallManager: APIManager
    private let preferences: Preferences
    private let userRepository: UserRepository
    private let emergencyConnectRepository: EmergencyRepository
    private let userDataRepository: UserDataRepository
    private let vpnManager: VPNManager
    private let protocolManager: ProtocolManagerType
    private let latencyRepository: LatencyRepository
    private let connectivity: Connectivity
    private let logger: FileLogger

    private var cancellables = Set<AnyCancellable>()
    private var timerCancellable: AnyCancellable?

    /// UI Events
    var routeToMainView = PassthroughSubject<Bool, Never>()

    /// Initialization
    init(apiCallManager: APIManager,
         userRepository: UserRepository,
         preferences: Preferences,
         emergencyConnectRepository: EmergencyRepository,
         userDataRepository: UserDataRepository,
         vpnManager: VPNManager,
         protocolManager: ProtocolManagerType,
         latencyRepository: LatencyRepository,
         connectivity: Connectivity,
         logger: FileLogger) {

        self.apiCallManager = apiCallManager
        self.userRepository = userRepository
        self.preferences = preferences
        self.emergencyConnectRepository = emergencyConnectRepository
        self.userDataRepository = userDataRepository
        self.vpnManager = vpnManager
        self.protocolManager = protocolManager
        self.latencyRepository = latencyRepository
        self.connectivity = connectivity
        self.logger = logger

        registerNetworkEventListener()
    }

    /// Continue Button Logic
    func continueButtonTapped() {
        if username.contains("@") {
            failedState = .username(TextsAsset.SignInError.usernameExpectedEmailProvided)
            return
        }

        failedState = nil
        showLoadingView = true

        let code2FA = show2FAField && !twoFactorCode.isEmpty ? twoFactorCode : ""

        apiCallManager.login(username: username, password: password, code2fa: code2FA)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                guard let self = self else { return }

                self.showLoadingView = false

                if case let .failure(error) = completion {
                    self.logger.logE("LoginViewModel", "Failed to login: \(error)")

                    switch error {
                    case Errors.invalid2FA:
                        self.failedState = .twoFactor(TextsAsset.twoFactorInvalidError)
                    case Errors.twoFactorRequired:
                        self.failedState = .twoFactor(TextsAsset.twoFactorRequiredError)
                        self.show2FAField = true
                    case let Errors.apiError(e):
                        self.failedState = .api(e.errorMessage ?? "Unknown API error")
                    default:
                        if let error = error as? Errors {
                            self.failedState = .network(error.description)
                        } else {
                            self.failedState = .network(error.localizedDescription)
                        }
                    }
                }
            } receiveValue: { [weak self] session in
                self?.preferences.saveLoginDate(date: Date())
                WifiManager.shared.saveCurrentWifiNetworks()
                self?.userRepository.login(session: session)
                self?.logger.logI("LoginViewModel",
                                  "Login successful, Preparing user data for \(session.username)")
                self?.prepareUserData()
            }
            .store(in: &cancellables)
    }

    /// Generate Code Logic
    func generateCodeTapped() {
        apiCallManager.getXpressLoginCode()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] completion in
                if case .failure = completion {
                    self?.logger.logE("LoginViewModel", "Unable to generate Login code.")
                    self?.failedState = .loginCode(TextsAsset.TVAsset.loginCodeError)
                }
            } receiveValue: { [weak self] xpressResponse in
                self?.twoFactorCode = xpressResponse.xPressLoginCode
                self?.startXPressLoginCodeVerifier(response: xpressResponse)
            }
            .store(in: &cancellables)
    }

    /// Start XPress Login Code Verifier
    private func startXPressLoginCodeVerifier(response: XPressLoginCodeResponse) {
        let startTime = Date()

        timerCancellable = Timer.publish(every: 5, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }

                self.apiCallManager.verifyXPressLoginCode(code: response.xPressLoginCode, sig: response.signature)
                    .asPublisher()
                    .timeout(.seconds(20), scheduler: DispatchQueue.main)
                    .sink(receiveCompletion: { [weak self] completion in
                        guard let self = self else { return }

                        if case .failure = completion {
                            self.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                            self.timerCancellable?.cancel()
                        }
                    }, receiveValue: { [weak self] verifyResponse in
                        guard let self = self else { return }

                        let auth = verifyResponse.sessionAuth

                        self.apiCallManager.getSession(sessionAuth: auth)
                            .asPublisher()
                            .receive(on: DispatchQueue.main)
                            .sink(receiveCompletion: { _ in },
                                  receiveValue: { [weak self] session in
                                guard let self = self else { return }

                                session.sessionAuthHash = auth
                                WifiManager.shared.saveCurrentWifiNetworks()

                                self.preferences.saveLoginDate(date: Date())
                                self.userRepository.login(session: session)
                                self.timerCancellable?.cancel()
                                self.logger.logI("LoginViewModel",
                                                 "Login successful with login code, Preparing user data for \(session.username)")
                                self.prepareUserData()
                                self.invalidateLoginCode(startTime: startTime, loginCodeResponse: response)
                            })
                            .store(in: &self.cancellables)
                    })
                    .store(in: &self.cancellables)
            }
    }

    /// Invalidate Login Code
    private func invalidateLoginCode(startTime: Date, loginCodeResponse: XPressLoginCodeResponse) {
        let now = Date()
        let secondsPassed = Int(now.timeIntervalSince(startTime) * 1000)

        if secondsPassed > loginCodeResponse.ttl {
            logger.logD("LoginViewModel", "Failed to verify XPress login code in TTL. Giving up.")
            failedState = .network("Login code expired. Please try again.")
        }
    }

    /// Disconnect Emergency Connect
    func disconnectFromEmergencyConnect() {
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
                    self.logger.logE("LoginViewModel", "Failed to prepare user data: \(error)")
                    self.showLoadingView = false

                    switch error {
                    case let Errors.apiError(e):
                        self.failedState = .api(e.errorMessage ?? "")
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

                self.logger.logD("LoginViewModel", "User data is ready")
                self.emergencyConnectRepository.cleansEmergencyConfigs()

                if self.emergencyConnectRepository.isConnected() == true {
                    logger.logD("LoginViewModel", "Disconnecting emergency connect.")
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
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] appNetwork in
                if appNetwork.status == .connected {
                    self?.failedState = .none
                }
            })
            .store(in: &cancellables)
    }
}
