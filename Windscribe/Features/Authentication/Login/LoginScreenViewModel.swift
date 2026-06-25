//
//  LoginScreenViewModel.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import CoreGraphics
import Foundation
import Observation

@available(iOS 17.0, *)
@Observable
@MainActor
final class LoginScreenViewModel {

    // MARK: - State (read by the view)

    var username = ""
    var password = ""
    var twoFactorCode = ""
    var accountHash = ""
    var showFileImporter = false
    var selectedTab: AuthTab = .standard
    var showLoadingView = false
    var failedState: LoginErrorState?
    var show2FAField = false
    var showCaptchaPopup = false
    var captchaData: CaptchaPopupModel?
    var showRestrictiveNetworkModal = false

    var isContinueButtonEnabled: Bool {
        switch selectedTab {
        case .standard:
            return username.count > 2 && password.count > 2
        case .hashed:
            return !accountHash.isEmpty
        }
    }

    // MARK: - Dependencies (injected via init — protocols only)

    private let loginAuthenticating: any LoginAuthenticating
    private let userDataProviding: any UserDataProviding
    private let emergencyConnecting: any EmergencyConnecting
    private let protocolManaging: any ProtocolManaging
    private let connectivityObserving: any ConnectivityObserving
    private let logger: any LogStoring
    private let mainRouting: any MainRouting

    // MARK: - Private vars

    private var secureToken = ""
    private var hasStarted = false

    // MARK: - Init

    init(
        loginAuthenticating: any LoginAuthenticating,
        userDataProviding: any UserDataProviding,
        emergencyConnecting: any EmergencyConnecting,
        protocolManaging: any ProtocolManaging,
        connectivityObserving: any ConnectivityObserving,
        logger: any LogStoring,
        mainRouting: any MainRouting
    ) {
        self.loginAuthenticating = loginAuthenticating
        self.userDataProviding = userDataProviding
        self.emergencyConnecting = emergencyConnecting
        self.protocolManaging = protocolManaging
        self.connectivityObserving = connectivityObserving
        self.logger = logger
        self.mainRouting = mainRouting
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !hasStarted else { return }
        hasStarted = true

        async let network: () = observeNetworkChanges()

        _ = await (network)
    }

    // MARK: - Actions (called by the view)

    func clearError() {
        failedState = nil
    }

    func submitTwoFactorCode(_ code: String) {
        twoFactorCode = code
        showLoadingView = true
        failedState = nil

        let loginUsername = selectedTab == .hashed ? accountHash : username
        let loginPassword = selectedTab == .hashed ? accountHash : password

        loginWithCredentials(
            username: loginUsername,
            password: loginPassword,
            code2fa: code,
            secureToken: secureToken
        )
    }

    func loadHashFromFile(_ data: Data) {
        accountHash = loginAuthenticating.hash(from: data)
    }

    func continueButtonTapped() {
        let loginUsername: String
        let loginPassword: String

        switch selectedTab {
        case .standard:
            if username.contains("@") {
                failedState = .username(TextsAsset.SignInError.usernameExpectedEmailProvided)
                return
            }
            loginUsername = username
            loginPassword = password
        case .hashed:
            guard !accountHash.isEmpty else { return }
            loginUsername = accountHash
            loginPassword = accountHash
        }

        failedState = nil
        showLoadingView = true

        Task {
            do {
                let tokenResponse = try await loginAuthenticating.authTokenLogin(username: loginUsername, useAsciiCaptcha: false)
                logger.logI("LoginViewModel", "Token received: \(tokenResponse.data.token.redacted)")
                secureToken = tokenResponse.data.token

                if let captcha = tokenResponse.data.captcha {
                    logger.logI("LoginViewModel", "Captcha required before login.")
                    if let popupModel = CaptchaPopupModel(from: captcha) {
                        captchaData = popupModel
                        showCaptchaPopup = true
                    } else {
                        logger.logE("LoginViewModel", "Failed to decode captcha images.")
                        failedState = .network(TextsAsset.Authentication.captchaImageDecodingFailed)
                    }
                    showLoadingView = false
                    return
                }

                let code2fa = show2FAField && !twoFactorCode.isEmpty ? twoFactorCode : ""
                loginWithCredentials(
                    username: loginUsername,
                    password: loginPassword,
                    code2fa: code2fa,
                    secureToken: secureToken
                )
            } catch {
                logger.logE("LoginViewModel", "Failed to get auth token: \(error)")
                failedState = .network("\(TextsAsset.Authentication.tokenRetrievalFailed) \(error)")
                showLoadingView = false
            }
        }
    }

    func submitCaptcha(captchaSolution: CGFloat, trailX: [CGFloat], trailY: [CGFloat]) {
        showCaptchaPopup = false
        showLoadingView = true

        let solution = "\(Int(captchaSolution))"
        let loginUsername = selectedTab == .hashed ? accountHash : username
        let loginPassword = selectedTab == .hashed ? accountHash : password
        let code2fa = show2FAField ? twoFactorCode : ""

        loginWithCredentials(
            username: loginUsername,
            password: loginPassword,
            code2fa: code2fa,
            secureToken: secureToken,
            captchaSolution: solution,
            captchaTrailX: trailX,
            captchaTrailY: trailY
        )
    }

    // MARK: - Private helpers

    private func loginWithCredentials(
        username: String,
        password: String,
        code2fa: String,
        secureToken: String,
        captchaSolution: String = "",
        captchaTrailX: [CGFloat] = [],
        captchaTrailY: [CGFloat] = []
    ) {
        Task {
            do {
                let session = try await loginAuthenticating.login(
                    username: username,
                    password: password,
                    code2fa: code2fa,
                    secureToken: secureToken,
                    captchaSolution: captchaSolution,
                    captchaTrailX: captchaTrailX,
                    captchaTrailY: captchaTrailY
                )
                await handleSuccessfulLogin(session: session)
            } catch {
                logger.logE("LoginViewModel", "Failed to login: \(error)")
                handleLoginError(error)
                showLoadingView = false
            }
        }
    }

    private func handleSuccessfulLogin(session: SessionModel) async {
        await loginAuthenticating.completeLogin(session: session)
        logger.logI("LoginViewModel", "Login successful, preparing user data for \(session.username)")
        await prepareUserData()
    }

    private func prepareUserData() async {
        do {
            try await userDataProviding.prepareUserData()
            logger.logI("LoginViewModel", "User data is ready")

            let wasEmergencyConnected = emergencyConnecting.isConnected()
            emergencyConnecting.cleanEmergencyConfigs()

            if wasEmergencyConnected {
                logger.logI("LoginViewModel", "Disconnecting emergency connect.")
                try? await emergencyConnecting.disconnect()
                logger.logI("LoginViewModel", "disconnectFromEmergencyConnect for getNextProtocol")
                await protocolManaging.refreshProtocols(shouldReset: true, shouldReconnect: false)
            }

            showLoadingView = false
            mainRouting.routeToMainView()
        } catch {
            loginAuthenticating.clearSession()
            logger.logE("LoginViewModel", "Failed to prepare user data: \(error)")
            showLoadingView = false

            switch error {
            case let Errors.apiError(e):
                failedState = .api(e.errorMessage ?? "")
            case Errors.failOverFailed:
                showRestrictiveNetworkModal = true
            default:
                if let error = error as? Errors {
                    failedState = .network(error.description)
                } else {
                    failedState = .network(error.localizedDescription)
                }
            }
        }
    }

    private func handleLoginError(_ error: Error) {
        switch error {
        case Errors.invalid2FA:
            failedState = .twoFactor(TextsAsset.twoFactorInvalidError)
        case Errors.twoFactorRequired:
            failedState = .twoFactor(TextsAsset.twoFactorRequiredError)
            show2FAField = true
        case Errors.failOverFailed:
            failedState = .api("")
            showRestrictiveNetworkModal = true
        case let Errors.apiError(e):
            failedState = .api(e.errorMessage ?? TextsAsset.unknownAPIError)
        default:
            if let error = error as? Errors {
                failedState = .network(error.description)
            } else {
                failedState = .network(error.localizedDescription)
            }
        }
    }

    private func observeNetworkChanges() async {
        for await appNetwork in connectivityObserving.networkUpdates {
            if appNetwork.status == .connected {
                failedState = nil
            }
        }
    }
}
