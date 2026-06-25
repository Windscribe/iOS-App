//
//  SignUpAuthenticating.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-18.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import CoreGraphics
import Foundation
import UIKit

/// Signup/authentication side effects needed by the Neo signup screen.
protocol SignUpAuthenticating: Sendable {
    var isPremiumUser: Bool { get }
    var accountHash: String { get }
    var preImageData: Data { get }

    func authTokenSignup(username: String, useAsciiCaptcha: Bool) async throws -> AuthTokenResponse
    func signup(
        username: String,
        password: String,
        referringUsername: String,
        email: String,
        voucherCode: String,
        secureToken: String,
        captchaSolution: String,
        captchaTrailX: [CGFloat],
        captchaTrailY: [CGFloat]
    ) async throws -> SessionModel
    func claimAccount(username: String, password: String, email: String) async throws
    func generateRandomUsername() async throws -> String
    func generateRandomPassword() async throws -> String
    func completeSignup(session: SessionModel) async
    func refreshSession() async throws
    func clearSession()
    func regenerateHash()
    func copyHash()
    func loadHashFromFile(_ data: Data)
}

/// Adapter wrapping legacy signup/session/hash services.
final class LegacySignUpAuthenticator: SignUpAuthenticating, @unchecked Sendable {
    private let apiManager: APIManager
    private let sessionManager: SessionManager
    private let userSessionRepository: UserSessionRepository
    private let preferences: Preferences
    private let hashAuthManager: HashAuthManager

    init(
        apiManager: APIManager,
        sessionManager: SessionManager,
        userSessionRepository: UserSessionRepository,
        preferences: Preferences,
        hashAuthManager: HashAuthManager
    ) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
        self.userSessionRepository = userSessionRepository
        self.preferences = preferences
        self.hashAuthManager = hashAuthManager
    }

    var isPremiumUser: Bool {
        userSessionRepository.sessionModel?.isUserPro ?? false
    }

    var accountHash: String {
        hashAuthManager.accountHash
    }

    var preImageData: Data {
        hashAuthManager.preImageData
    }

    func authTokenSignup(username: String, useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        try await apiManager.authTokenSignup(username: username, useAsciiCaptcha: useAsciiCaptcha)
    }

    func signup(
        username: String,
        password: String,
        referringUsername: String,
        email: String,
        voucherCode: String,
        secureToken: String,
        captchaSolution: String,
        captchaTrailX: [CGFloat],
        captchaTrailY: [CGFloat]
    ) async throws -> SessionModel {
        try await apiManager.signup(
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
    }

    func claimAccount(username: String, password: String, email: String) async throws {
        _ = try await apiManager.claimAccount(username: username, password: password, email: email)
    }

    func generateRandomUsername() async throws -> String {
        let credential = try await apiManager.generateRandomUsername()
        return credential.value
    }

    func generateRandomPassword() async throws -> String {
        let credential = try await apiManager.generateRandomPassword()
        return credential.value
    }

    func completeSignup(session: SessionModel) async {
        await sessionManager.updateFrom(session: session)
        await sessionManager.updateAfterLoginIn()
    }

    func refreshSession() async throws {
        try await sessionManager.updateSession()
    }

    func clearSession() {
        preferences.clearSessionAuth()
        userSessionRepository.clearSession()
    }

    func regenerateHash() {
        hashAuthManager.regenerate()
    }

    func copyHash() {
        hashAuthManager.copyHash()
    }

    func loadHashFromFile(_ data: Data) {
        hashAuthManager.loadFromFile(data)
    }
}
