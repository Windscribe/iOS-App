//
//  MockAPIManager.swift
//  WindscribeTests
//
//  Created by Soner Yuksel on 2025-10-07.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation
@testable import Windscribe

class MockAPIManager: APIManager {
    var shouldThrowError = false
    var customError: Error = Errors.sessionIsInvalid
    var mockLeaderboard: Leaderboard?
    var mockAPIMessage: APIMessage?

    // Track method calls
    var getLeaderboardCalled = false
    var recordScoreCalled = false
    var lastRecordedScore: Int?
    var lastRecordedUserId: String?

    func reset() {
        shouldThrowError = false
        customError = Errors.sessionIsInvalid
        mockLeaderboard = nil
        mockAPIMessage = nil
        getLeaderboardCalled = false
        recordScoreCalled = false
        lastRecordedScore = nil
        lastRecordedUserId = nil
    }

    // MARK: - ShakeForData Methods (Implemented)

    func getShakeForDataLeaderboard() async throws -> Leaderboard {
        getLeaderboardCalled = true

        if shouldThrowError {
            throw customError
        }

        guard let leaderboard = mockLeaderboard else {
            // Return default mock leaderboard from sample data
            let jsonData = SampleDataLeaderboard.leaderboardJSON.data(using: .utf8)!
            let leaderboard = try! JSONDecoder().decode(Leaderboard.self, from: jsonData)
            return leaderboard
        }

        return leaderboard
    }

    func recordShakeForDataScore(score: Int, userID: String) async throws -> APIMessage {
        recordScoreCalled = true
        lastRecordedScore = score
        lastRecordedUserId = userID

        if shouldThrowError {
            throw customError
        }

        guard let message = mockAPIMessage else {
            // Return default success message from sample data
            let jsonData = SampleDataLeaderboard.apiMessageSuccessJSON.data(using: .utf8)!
            let defaultMessage = try! JSONDecoder().decode(APIMessage.self, from: jsonData)
            return defaultMessage
        }

        return message
    }

    // MARK: - Session Methods

    func getSession(_ appleID: String?) async throws -> Session {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getWebSession() async throws -> WebSession {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func deleteSession() async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getSession(sessionAuth: String) async throws -> Session {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    // MARK: - Signup and Login Methods

    func login(username: String, password: String, code2fa: String, secureToken: String, captchaSolution: String, captchaTrailX: [CGFloat], captchaTrailY: [CGFloat]) async throws -> Session {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func signup(username: String, password: String, referringUsername: String, email: String, voucherCode: String, secureToken: String, captchaSolution: String, captchaTrailX: [CGFloat], captchaTrailY: [CGFloat]) async throws -> Session {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func authTokenLogin(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func authTokenSignup(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func regToken() async throws -> Token {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func signUpUsingToken(token: String) async throws -> Session {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func ssoSession(token: String) async throws -> SSOSession {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    // MARK: - Account Methods

    func addEmail(email: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func confirmEmail() async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func claimAccount(username: String, password: String, email: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getXpressLoginCode() async throws -> XPressLoginCodeResponse {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func verifyXPressLoginCode(code: String, sig: String) async throws -> XPressLoginVerifyResponse {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func cancelAccount(password: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func verifyTvLoginCode(code: String) async throws -> XPressLoginVerifyResponse {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func claimVoucherCode(code: String) async throws -> ClaimVoucherCodeResponse {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    // MARK: - VPN Methods

    func getServerList(languageCode: String, revision: String, isPro: Bool, alcList: [String]) async throws -> ServerList {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getStaticIpList() async throws -> StaticIPList {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getOpenVPNServerConfig(openVPNVersion: String) async throws -> String {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getIKEv2ServerCredentials() async throws -> IKEv2ServerCredentials {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getOpenVPNServerCredentials() async throws -> OpenVPNServerCredentials {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getPortMap(version: Int, forceProtocols: [String]) async throws -> PortMapList {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    // MARK: - Billing Methods

    func getMobileBillingPlans(promo: String?) async throws -> MobilePlanList {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func postBillingCpID(pcpID: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func verifyApplePayment(appleID: String, appleData: String, appleSIG: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    // MARK: - Robert Methods

    func getRobertFilters() async throws -> RobertFilters {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func updateRobertSettings(id: String, status: Int32) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func syncRobertFilters() async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    // MARK: - Other Methods

    func recordInstall(platform: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getNotifications(pcpid: String) async throws -> NoticeList {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func getIp() async throws -> MyIP {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func sendDebugLog(username: String, log: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }

    func sendTicket(email: String, name: String, subject: String, message: String, category: String, type: String, channel: String, platform: String) async throws -> APIMessage {
        fatalError("Not implemented for ShakeDataRepository tests")
    }
}
