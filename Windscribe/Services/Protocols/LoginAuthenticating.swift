//
//  LoginAuthenticating.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import CoreGraphics
import Foundation

/// Login/authentication side effects needed by the Neo sign-in screen.
protocol LoginAuthenticating: Sendable {
    func authTokenLogin(username: String, useAsciiCaptcha: Bool) async throws -> AuthTokenResponse
    func login(
        username: String,
        password: String,
        code2fa: String,
        secureToken: String,
        captchaSolution: String,
        captchaTrailX: [CGFloat],
        captchaTrailY: [CGFloat]
    ) async throws -> SessionModel
    func completeLogin(session: SessionModel) async
    func clearSession()
    func hash(from data: Data) -> String
}

/// Adapter wrapping legacy auth/session services.
final class LegacyLoginAuthenticator: LoginAuthenticating, @unchecked Sendable {
    private let apiManager: APIManager
    private let sessionManager: SessionManager
    private let userSessionRepository: UserSessionRepository
    private let preferences: Preferences
    private let wifiManager: WifiManager
    private let hashAuthManager: HashAuthManager

    init(
        apiManager: APIManager,
        sessionManager: SessionManager,
        userSessionRepository: UserSessionRepository,
        preferences: Preferences,
        wifiManager: WifiManager,
        hashAuthManager: HashAuthManager
    ) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
        self.userSessionRepository = userSessionRepository
        self.preferences = preferences
        self.wifiManager = wifiManager
        self.hashAuthManager = hashAuthManager
    }

    func authTokenLogin(username: String, useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        try await apiManager.authTokenLogin(username: username, useAsciiCaptcha: useAsciiCaptcha)
    }

    func login(
        username: String,
        password: String,
        code2fa: String,
        secureToken: String,
        captchaSolution: String,
        captchaTrailX: [CGFloat],
        captchaTrailY: [CGFloat]
    ) async throws -> SessionModel {
        try await apiManager.login(
            username: username,
            password: password,
            code2fa: code2fa,
            secureToken: secureToken,
            captchaSolution: captchaSolution,
            captchaTrailX: captchaTrailX,
            captchaTrailY: captchaTrailY
        )
    }

    func completeLogin(session: SessionModel) async {
        preferences.saveLoginDate(date: Date())
        wifiManager.saveCurrentWifiNetworks()
        await sessionManager.updateFrom(session: session)
        await sessionManager.updateAfterLoginIn()
    }

    func clearSession() {
        preferences.clearSessionAuth()
        userSessionRepository.clearSession()
    }

    func hash(from data: Data) -> String {
        hashAuthManager.hash(from: data)
    }
}
