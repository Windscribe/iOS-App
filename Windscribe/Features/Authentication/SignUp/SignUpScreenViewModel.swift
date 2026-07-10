//
//  SignUpScreenViewModel.swift
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
final class SignUpScreenViewModel {

    // MARK: - State (read by the view)

    var username = ""
    var password = ""
    var confirmPassword = ""
    var email = ""
    var voucherCode = ""
    var referralUsername = ""
    var isPremiumUser = false
    var selectedTab: AuthTab = .standard
    var isReferralVisible = false
    var isVoucherVisible = false
    var showLoadingView = false
    var failedState: SignUpErrorState = .none
    var hasBackedUpHash = false
    var accountHash = ""
    var showFileExporter = false
    var showFileImporter = false
    var showCaptchaPopup = false
    var captchaData: CaptchaPopupModel?
    var showEmailWarning = false
    var showRestrictiveNetworkModal = false
    var navigateToLogin = false

    var preImageData: Data { signUpAuthenticating.preImageData }

    var isContinueButtonEnabled: Bool {
        switch selectedTab {
        case .standard:
            return username.count >= 3 && password.count >= 3 && confirmPassword == password
        case .hashed:
            return hasBackedUpHash && !accountHash.isEmpty
        }
    }

    // MARK: - Dependencies (injected via init — protocols only)

    private let claimGhostAccount: Bool
    private let signUpAuthenticating: any SignUpAuthenticating
    private let userDataProviding: any UserDataProviding
    private let emergencyConnecting: any EmergencyConnecting
    private let protocolManaging: any ProtocolManaging
    private let connectivityObserving: any ConnectivityObserving
    private let logger: any LogStoring
    private let mainRouting: any MainRouting

    // MARK: - Private vars

    private static let generateCooldownInterval: TimeInterval = 1.0
    private var secureToken = ""
    private var lastUsernameGenerateTime: Date = .distantPast
    private var lastPasswordGenerateTime: Date = .distantPast
    private var isObserving = false

    // MARK: - Init

    init(
        claimGhostAccount: Bool,
        signUpAuthenticating: any SignUpAuthenticating,
        userDataProviding: any UserDataProviding,
        emergencyConnecting: any EmergencyConnecting,
        protocolManaging: any ProtocolManaging,
        connectivityObserving: any ConnectivityObserving,
        logger: any LogStoring,
        mainRouting: any MainRouting
    ) {
        self.claimGhostAccount = claimGhostAccount
        self.signUpAuthenticating = signUpAuthenticating
        self.userDataProviding = userDataProviding
        self.emergencyConnecting = emergencyConnecting
        self.protocolManaging = protocolManaging
        self.connectivityObserving = connectivityObserving
        self.logger = logger
        self.mainRouting = mainRouting
        self.isPremiumUser = signUpAuthenticating.isPremiumUser
        regenerateHash()
    }

    // MARK: - Lifecycle

    func startObservers() async {
        guard !isObserving else { return }
        isObserving = true
        defer { isObserving = false }

        async let network: () = observeNetworkChanges()

        _ = await (network)
    }

    // MARK: - Actions

    func clearError() {
        failedState = .none
    }

    func continueButtonTapped(ignoreEmailCheck: Bool) {
        if selectedTab == .hashed {
            signUpWithHash()
            return
        }

        guard validateStandardFields(ignoreEmailCheck: ignoreEmailCheck) else { return }

        failedState = .none
        showLoadingView = true

        if claimGhostAccount {
            claimAccount()
        } else {
            signUpUser()
        }
    }

    func referralViewTapped() {
        isReferralVisible.toggle()
    }

    func voucherViewTapped() {
        isVoucherVisible.toggle()
    }

    func generateUsername() {
        let now = Date()
        guard now.timeIntervalSince(lastUsernameGenerateTime) >= Self.generateCooldownInterval else { return }
        lastUsernameGenerateTime = now

        Task {
            do {
                username = try await signUpAuthenticating.generateRandomUsername()
            } catch {
                logger.logE("SignUpViewModel", "Failed to generate username: \(error)")
            }
        }
    }

    func generatePassword() {
        let now = Date()
        guard now.timeIntervalSince(lastPasswordGenerateTime) >= Self.generateCooldownInterval else { return }
        lastPasswordGenerateTime = now

        Task {
            do {
                let generatedPassword = try await signUpAuthenticating.generateRandomPassword()
                password = generatedPassword
                confirmPassword = generatedPassword
            } catch {
                logger.logE("SignUpViewModel", "Failed to generate password: \(error)")
            }
        }
    }

    func regenerateHash() {
        signUpAuthenticating.regenerateHash()
        accountHash = signUpAuthenticating.accountHash
    }

    func copyHash() {
        signUpAuthenticating.copyHash()
    }

    func loadHashFromFile(_ data: Data) {
        signUpAuthenticating.loadHashFromFile(data)
        accountHash = signUpAuthenticating.accountHash
    }

    func submitCaptcha(captchaSolution: CGFloat, trailX: [CGFloat], trailY: [CGFloat]) {
        showCaptchaPopup = false
        showLoadingView = true

        let solution = "\(Int(captchaSolution))"
        logger.logI("SignUpViewModel", "Submitting captcha solution with offset \(solution)")

        if selectedTab == .hashed {
            signUpWithCredentials(
                username: accountHash,
                password: accountHash,
                referringUsername: "",
                email: "",
                voucherCode: voucherCode,
                secureToken: secureToken,
                captchaSolution: solution,
                captchaTrailX: trailX,
                captchaTrailY: trailY
            )
        } else {
            signUpWithCredentials(
                username: username,
                password: password,
                referringUsername: referralUsername,
                email: email,
                voucherCode: voucherCode,
                secureToken: secureToken,
                captchaSolution: solution,
                captchaTrailX: trailX,
                captchaTrailY: trailY
            )
        }
    }

    func isEmailValid(_ email: String) -> Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: email)
    }

    // MARK: - Private helpers

    private func validateStandardFields(ignoreEmailCheck: Bool) -> Bool {
        if !isUsernameValid(username) {
            showLoadingView = false
            failedState = .username(TextsAsset.usernameValidationError)
            return false
        }

        if password.count < 8 {
            showLoadingView = false
            failedState = .password(TextsAsset.passwordValidationError)
            return false
        }

        if confirmPassword != password {
            showLoadingView = false
            failedState = .confirmPassword(TextsAsset.passwordsDoNotMatch)
            return false
        }

        if !email.isEmpty && !isEmailValid(email) {
            showLoadingView = false
            failedState = .email(TextsAsset.emailValidationError)
            return false
        }

        if !ignoreEmailCheck && email.isEmpty {
            showLoadingView = false
            showEmailWarning = true
            return false
        }

        return true
    }

    private func signUpWithHash() {
        guard !accountHash.isEmpty else { return }
        failedState = .none
        showLoadingView = true

        Task {
            do {
                let tokenResponse = try await signUpAuthenticating.authTokenSignup(username: accountHash, useAsciiCaptcha: false)
                secureToken = tokenResponse.data.token

                if let captcha = tokenResponse.data.captcha {
                    if let popupModel = CaptchaPopupModel(from: captcha) {
                        captchaData = popupModel
                        showCaptchaPopup = true
                    } else {
                        failedState = .network(TextsAsset.Authentication.captchaImageDecodingFailed)
                    }
                    showLoadingView = false
                    return
                }

                signUpWithCredentials(
                    username: accountHash,
                    password: accountHash,
                    referringUsername: "",
                    email: "",
                    voucherCode: voucherCode,
                    secureToken: secureToken
                )
            } catch {
                logger.logE("SignUpViewModel", "Hashed signup token failed: \(error)")
                failedState = .network("\(TextsAsset.Authentication.tokenRetrievalFailed) \(error)")
                showLoadingView = false
            }
        }
    }

    private func signUpUser() {
        logger.logD("SignUpViewModel", "Requesting auth token for signup")
        showLoadingView = true

        Task {
            do {
                let tokenResponse = try await signUpAuthenticating.authTokenSignup(username: username, useAsciiCaptcha: false)
                logger.logD("SignUpViewModel", "Token received: \(tokenResponse.data.token.redacted)")
                secureToken = tokenResponse.data.token

                if let captcha = tokenResponse.data.captcha {
                    logger.logI("SignUpViewModel", "Captcha required before signup.")
                    if let popupModel = CaptchaPopupModel(from: captcha) {
                        captchaData = popupModel
                        showCaptchaPopup = true
                    } else {
                        logger.logE("SignUpViewModel", "Failed to decode captcha images.")
                        failedState = .network(TextsAsset.Authentication.captchaImageDecodingFailed)
                    }
                    showLoadingView = false
                    return
                }

                signUpWithCredentials(
                    username: username,
                    password: password,
                    referringUsername: referralUsername,
                    email: email,
                    voucherCode: voucherCode,
                    secureToken: secureToken
                )
            } catch {
                logger.logE("SignUpViewModel", "Failed to get auth token: \(error)")
                failedState = .network("\(TextsAsset.Authentication.tokenRetrievalFailed) \(error)")
                showLoadingView = false
            }
        }
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
        captchaTrailY: [CGFloat] = []
    ) {
        Task {
            do {
                let session = try await signUpAuthenticating.signup(
                    username: username,
                    password: password,
                    referringUsername: referringUsername,
                    email: email,
                    voucherCode: voucherCode,
                    secureToken: secureToken,
                    captchaSolution: captchaSolution,
                    captchaTrailX: captchaTrailX,
                    captchaTrailY: captchaTrailY
                )

                await signUpAuthenticating.completeSignup(session: session)
                await prepareUserData()
            } catch {
                logger.logE("SignUpViewModel", "Failed to signup: \(error)")
                handleError(error)
                showLoadingView = false
            }
        }
    }

    private func claimAccount() {
        logger.logD("SignUpViewModel", "Claiming ghost account.")
        showLoadingView = true

        Task {
            do {
                try await signUpAuthenticating.claimAccount(username: username, password: password, email: email)

                if isPremiumUser == false {
                    await getUpdatedUser()
                } else {
                    await prepareUserData(ignoreError: true)
                }
            } catch {
                logger.logD("SignUpViewModel", "Error claiming account. \(error)")
                handleError(error)
            }
        }
    }

    private func getUpdatedUser() async {
        logger.logD("SignUpViewModel", "Getting updated session.")

        do {
            try await signUpAuthenticating.refreshSession()
            showLoadingView = false
            if email.isEmpty == false {
                showEmailWarning = true
            } else {
                mainRouting.routeToMainView()
            }
        } catch {
            logger.logE("SignUpViewModel", "Failed to get updated user: \(error)")
            showLoadingView = false
            mainRouting.routeToMainView()
        }
    }

    private func prepareUserData(ignoreError: Bool = false) async {
        logger.logD("SignUpViewModel", "Preparing user data.")

        do {
            try await userDataProviding.prepareUserData()

            if await emergencyConnecting.checkEmergencyConnectCleaning() {
                logger.logI("LoginViewModel", "disconnectFromEmergencyConnect for getNextProtocol")
                await protocolManaging.refreshProtocols(shouldReset: true, shouldReconnect: false)
            }

            showLoadingView = false
            mainRouting.routeToMainView()
        } catch {
            if ignoreError {
                mainRouting.routeToMainView()
            } else {
                signUpAuthenticating.clearSession()
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
            showRestrictiveNetworkModal = true
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

    private func observeNetworkChanges() async {
        for await appNetwork in connectivityObserving.networkUpdates {
            if case .network = failedState, appNetwork.status == .connected {
                failedState = .none
            }
        }
    }

    private func isUsernameValid(_ username: String) -> Bool {
        let charset = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "_")).inverted
        return !username.isEmpty && username.rangeOfCharacter(from: charset) == nil && username.count > 2
    }
}
