//
//  CaptchaViewModel.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-06-27.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import UIKit
import Combine

class CaptchaViewModel {
    let submitCaptcha = PassthroughSubject<String, Never>()
    let cancel = PassthroughSubject<Void, Never>()
    let refreshCaptcha = PassthroughSubject<Void, Never>()

    let captchaImage = CurrentValueSubject<UIImage?, Never>(nil)
    let isLoading = CurrentValueSubject<Bool, Never>(false)
    let errorMessage = CurrentValueSubject<String?, Never>(nil)

    let loginSuccess = PassthroughSubject<SessionModel, Never>()
    let loginError = PassthroughSubject<Error, Never>()
    let captchaDismiss = PassthroughSubject<Void, Never>()

    private var cancellables = Set<AnyCancellable>()

    private let asciiArtBase64: String
    private let username: String
    private let password: String
    private let twoFactorCode: String?
    private var secureToken: String
    private let isSignup: Bool

    private let apiCallManager: APIManager
    private let logger: FileLogger

    init(
        asciiArtBase64: String,
        username: String,
        password: String,
        twoFactorCode: String?,
        secureToken: String,
        isSignup: Bool,
        apiCallManager: APIManager,
        logger: FileLogger
    ) {
        self.asciiArtBase64 = asciiArtBase64
        self.username = username
        self.password = password
        self.twoFactorCode = twoFactorCode
        self.secureToken = secureToken
        self.isSignup = isSignup
        self.apiCallManager = apiCallManager
        self.logger = logger
        setupBindings()
    }

    private func setupBindings() {
        if let image = UIImage.fromAsciiBase64(asciiArtBase64) {
            captchaImage.send(image)
        } else {
            errorMessage.send("Unable to render captcha image.")
        }

        // Submit
        submitCaptcha
          .sink { [weak self] code in
            self?.verifyCaptchaAndLogin(with: code)
          }
          .store(in: &cancellables)

        // Cancel
        cancel
            .sink { [weak self] in
                self?.logger.logD("CaptchaViewModel", "Captcha cancelled by user")
            }
            .store(in: &cancellables)

        // Refresh
        refreshCaptcha
            .sink { [weak self] in
                self?.fetchNewCaptcha()
            }
            .store(in: &cancellables)
    }

    private func verifyCaptchaAndLogin(with solution: String) {
        isLoading.send(true)
        logger.logD("CaptchaViewModel", "Verifying captcha with solution: \(solution)")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let session = try await self.apiCallManager.login(
                    username: self.username,
                    password: self.password,
                    code2fa: self.twoFactorCode ?? "",
                    secureToken: self.secureToken,
                    captchaSolution: solution,
                    captchaTrailX: [],
                    captchaTrailY: []
                )

                await MainActor.run {
                    self.logger.logI("CaptchaViewModel", "Login successful after captcha.")
                    self.captchaDismiss.send(())
                    self.loginSuccess.send(session)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("CaptchaViewModel", "Captcha login failed: \(error)")
                    self.isLoading.send(false)
                    self.captchaDismiss.send(())
                    self.loginError.send(error)
                }
            }
        }
    }

    private func fetchNewCaptcha() {
        isLoading.send(true)
        logger.logD("CaptchaViewModel", "Fetching new captcha...")

        Task { [weak self] in
            guard let self = self else { return }

            do {
                let response: AuthTokenResponse
                if self.isSignup {
                    response = try await self.apiCallManager.authTokenSignup(username: username, useAsciiCaptcha: true)
                } else {
                    response = try await self.apiCallManager.authTokenLogin(username: username, useAsciiCaptcha: true)
                }

                await MainActor.run {
                    // Update secure token
                    self.secureToken = response.data.token

                    // Update captcha image
                    if let asciiArt = response.data.captcha?.asciiArt,
                       let image = UIImage.fromAsciiBase64(asciiArt) {
                        self.captchaImage.send(image)
                        self.logger.logD("CaptchaViewModel", "Captcha refreshed successfully")
                    } else {
                        self.errorMessage.send("Unable to render new captcha image.")
                        self.logger.logE("CaptchaViewModel", "Failed to decode new captcha image")
                    }

                    self.isLoading.send(false)
                }
            } catch {
                await MainActor.run {
                    self.logger.logE("CaptchaViewModel", "Failed to refresh captcha: \(error)")
                    self.errorMessage.send("Failed to refresh captcha. Please try again.")
                    self.isLoading.send(false)
                }
            }
        }
    }
}
