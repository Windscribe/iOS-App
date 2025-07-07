//
//  APIManagerImpl+Account.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

extension APIManagerImpl {
    func login(username: String,
               password: String,
               code2fa: String,
               secureToken: String,
               captchaSolution: String,
               captchaTrailX: [CGFloat],
               captchaTrailY: [CGFloat]) -> Single<Session> {

        return makeApiCall(modalType: Session.self) { [weak self] completion in
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
                captchaTrailY: [CGFloat]) -> Single<Session> {

        return makeApiCall(modalType: Session.self) { [weak self] completion in
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
    func authTokenLogin(useAsciiCaptcha: Bool) -> RxSwift.Single<AuthTokenResponse> {
        return makeApiCall(modalType: AuthTokenResponse.self) { [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.authTokenLogin(useAsciiCaptcha, callback: completion)

        }
    }

    func authTokenSignup(useAsciiCaptcha: Bool) -> RxSwift.Single<AuthTokenResponse> {
        return makeApiCall(modalType: AuthTokenResponse.self) { [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.authTokenSignup(useAsciiCaptcha, callback: completion)
        }
    }

    func regToken() -> RxSwift.Single<Token> {
        return makeApiCall(modalType: Token.self) { completion in
            self.api.regToken(completion)
        }
    }

    func signUpUsingToken(token: String) -> RxSwift.Single<Session> {
        return makeApiCall(modalType: Session.self) { completion in
            self.api.signup(usingToken: token, callback: completion)
        }
    }

    func ssoSession(token: String) -> RxSwift.Single<SSOSession> {
        return makeApiCall(modalType: SSOSession.self) {  [weak self] completion in
            guard let self = self else {
                return nil
            }

            return self.api.sso(SSOSessionType.apple.ssoID, token: token, callback: completion)
        }
    }

    func addEmail(email: String) -> RxSwift.Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.addEmail(sessionAuth, email: email, callback: completion)
        }
    }

    func confirmEmail() -> RxSwift.Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.confirmEmail(sessionAuth, callback: completion)
        }
    }

    func claimAccount(username: String, password: String, email: String) -> RxSwift.Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.claimAccount(sessionAuth, username: username, password: password, email: email, voucherCode: "", claimAccount: "1", callback: completion)
        }
    }

    func getXpressLoginCode() -> RxSwift.Single<XPressLoginCodeResponse> {
        return makeApiCall(modalType: XPressLoginCodeResponse.self) { completion in
            self.api.getXpressLoginCode(completion)
        }
    }

    func verifyXPressLoginCode(code: String, sig: String) -> RxSwift.Single<XPressLoginVerifyResponse> {
        return makeApiCall(modalType: XPressLoginVerifyResponse.self) { completion in
            self.api.verifyXpressLoginCode(code, sig: sig, callback: completion)
        }
    }

    func verifyTvLoginCode(code: String) -> RxSwift.Single<XPressLoginVerifyResponse> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: XPressLoginVerifyResponse.self) { completion in
            self.api.verifyTvLoginCode(sessionAuth, xpressCode: code, callback: completion)
        }
    }

    func cancelAccount(password: String) -> RxSwift.Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.cancelAccount(sessionAuth, password: password, callback: completion)
        }
    }

    func claimVoucherCode(code: String) -> RxSwift.Single<ClaimVoucherCodeResponse> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: ClaimVoucherCodeResponse.self) { completion in
            self.api.claimVoucherCode(sessionAuth, voucherCode: code, callback: completion)
        }
    }
}
