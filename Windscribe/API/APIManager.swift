//
//  APIManager.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-21.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

protocol APIManager {
    // Session
    func getSession(_ appleID: String?) async throws -> Session
    func getWebSession() async throws -> WebSession
    func deleteSession() async throws -> APIMessage
    func getSession(sessionAuth: String) async throws -> Session

    // Signup and Login
    func login(username: String,
               password: String,
               code2fa: String,
               secureToken: String,
               captchaSolution: String,
               captchaTrailX: [CGFloat],
               captchaTrailY: [CGFloat]) async throws -> Session
    func signup(username: String,
                password: String,
                referringUsername: String,
                email: String,
                voucherCode: String,
                secureToken: String,
                captchaSolution: String,
                captchaTrailX: [CGFloat],
                captchaTrailY: [CGFloat]) async throws -> Session
    func authTokenLogin(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse
    func authTokenSignup(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse
    func regToken() async throws -> Token
    func signUpUsingToken(token: String) async throws -> Session
    func ssoSession(token: String) async throws -> SSOSession

    // Account
    func addEmail(email: String) async throws -> APIMessage
    func confirmEmail() async throws -> APIMessage
    func claimAccount(username: String, password: String, email: String) async throws -> APIMessage
    func getXpressLoginCode() async throws -> XPressLoginCodeResponse
    func verifyXPressLoginCode(code: String, sig: String) async throws -> XPressLoginVerifyResponse
    func cancelAccount(password: String) async throws -> APIMessage
    func verifyTvLoginCode(code: String) async throws -> XPressLoginVerifyResponse
    func claimVoucherCode(code: String) async throws -> ClaimVoucherCodeResponse

    // VPN
    func getServerList(languageCode: String, revision: String, isPro: Bool, alcList: [String]) async throws -> ServerList
    func getStaticIpList() async throws -> StaticIPList
    func getOpenVPNServerConfig(openVPNVersion: String) async throws -> String
    func getIKEv2ServerCredentials() async throws -> IKEv2ServerCredentials
    func getOpenVPNServerCredentials() async throws -> OpenVPNServerCredentials
    func getPortMap(version: Int, forceProtocols: [String]) async throws -> PortMapList

    // Billing
    func getMobileBillingPlans(promo: String?) async throws -> MobilePlanList
    func postBillingCpID(pcpID: String) async throws -> APIMessage
    func verifyApplePayment(appleID: String, appleData: String, appleSIG: String) async throws -> APIMessage

    // Robert
    func getRobertFilters() async throws -> RobertFilters
    func updateRobertSettings(id: String, status: Int32) async throws -> APIMessage
    func syncRobertFilters() async throws -> APIMessage

    // Other
    func recordInstall(platform: String) async throws -> APIMessage
    func getNotifications(pcpid: String) async throws -> NoticeList
    func getIp() async throws -> MyIP
    func sendDebugLog(username: String, log: String) async throws -> APIMessage
    func sendTicket(email: String, name: String, subject: String, message: String, category: String, type: String, channel: String, platform: String) async throws -> APIMessage
    func getShakeForDataLeaderboard() async throws -> Leaderboard
    func recordShakeForDataScore(score: Int, userID: String) async throws -> APIMessage
}
