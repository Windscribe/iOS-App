//
//  APIManagerImpl+Account.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

extension APIManagerImpl {
    func login(username: String,
               password: String,
               code2fa: String,
               secureToken: String,
               captchaSolution: String,
               captchaTrailX: [CGFloat],
               captchaTrailY: [CGFloat]) async throws -> Session {

        return try await apiUtil.makeApiCall(modalType: Session.self) { [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.login(
                username,
                password: password,
                code2fa: code2fa,
                secureToken: secureToken,
                captchaSolution: captchaSolution,
                captchaTrailX: captchaTrailX.asNSNumberArray,
                captchaTrailY: captchaTrailY.asNSNumberArray,
                callback: completion
            )
        }
    }

    func signup(username: String,
                password: String,
                referringUsername: String,
                email: String,
                voucherCode: String,
                secureToken: String,
                captchaSolution: String,
                captchaTrailX: [CGFloat],
                captchaTrailY: [CGFloat]) async throws -> Session {

        return try await apiUtil.makeApiCall(modalType: Session.self) { [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.signup(
                username,
                password: password,
                referringUsername: referringUsername,
                email: email,
                voucherCode: voucherCode,
                secureToken: secureToken,
                captchaSolution: captchaSolution,
                captchaTrailX: captchaTrailX.asNSNumberArray,
                captchaTrailY: captchaTrailY.asNSNumberArray,
                callback: completion
            )
        }
    }
    func authTokenLogin(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        return try await apiUtil.makeApiCall(modalType: AuthTokenResponse.self) { [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.authTokenLogin(useAsciiCaptcha, callback: completion)

        }
    }

    func authTokenSignup(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        return try await apiUtil.makeApiCall(modalType: AuthTokenResponse.self) { [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.authTokenSignup(useAsciiCaptcha, callback: completion)
        }
    }

    func regToken() async throws -> Token {
        return try await apiUtil.makeApiCall(modalType: Token.self) { completion in
            self.api.regToken(completion)
        }
    }

    func signUpUsingToken(token: String) async throws -> Session {
        return try await apiUtil.makeApiCall(modalType: Session.self) { completion in
            self.api.signup(usingToken: token, callback: completion)
        }
    }

    func ssoSession(token: String) async throws -> SSOSession {
        return try await apiUtil.makeApiCall(modalType: SSOSession.self) {  [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.sso(SSOSessionType.apple.ssoID, token: token, callback: completion)
        }
    }

    func addEmail(email: String) async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.addEmail(sessionAuth, email: email, callback: completion)
        }
    }

    func confirmEmail() async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.confirmEmail(sessionAuth, callback: completion)
        }
    }

    func resetPassword(email: String) async throws -> APIMessage {
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.passwordRecovery(email, callback: completion)
        }
    }

    func claimAccount(username: String, password: String, email: String) async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.claimAccount(sessionAuth, username: username, password: password, email: email, voucherCode: "", claimAccount: "1", callback: completion)
        }
    }

    func getXpressLoginCode() async throws -> XPressLoginCodeResponse {
        return try await apiUtil.makeApiCall(modalType: XPressLoginCodeResponse.self) { completion in
            self.api.getXpressLoginCode(completion)
        }
    }

    func verifyXPressLoginCode(code: String, sig: String) async throws -> XPressLoginVerifyResponse {
        return try await apiUtil.makeApiCall(modalType: XPressLoginVerifyResponse.self) { completion in
            self.api.verifyXpressLoginCode(code, sig: sig, callback: completion)
        }
    }

    func verifyTvLoginCode(code: String) async throws -> XPressLoginVerifyResponse {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: XPressLoginVerifyResponse.self) { completion in
            self.api.verifyTvLoginCode(sessionAuth, xpressCode: code, callback: completion)
        }
    }

    func cancelAccount(password: String) async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.cancelAccount(sessionAuth, password: password, callback: completion)
        }
    }

    func claimVoucherCode(code: String) async throws -> ClaimVoucherCodeResponse {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: ClaimVoucherCodeResponse.self) { completion in
            self.api.claimVoucherCode(sessionAuth, voucherCode: code, callback: completion)
        }
    }
}
