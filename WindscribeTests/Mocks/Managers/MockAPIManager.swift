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
    var customError: Error = Errors.notDefined
    var mockLeaderboard: Leaderboard?
    var mockAPIMessage: APIMessage?

    // PortMap tracking
    var portMapListToReturn: PortMapList?

    // Notifications tracking
    var noticeListToReturn: NoticeList?
    var getNotificationsCalled = false
    var lastPcpid: String?

    // StaticIP tracking
    var staticIPListToReturn: StaticIPList?
    var getStaticIpListCalled = false

    // Track method calls
    var getLeaderboardCalled = false
    var recordScoreCalled = false
    var lastRecordedScore: Int?
    var lastRecordedUserId: String?

    var mockServerList: ServerList?

    func reset() {
        shouldThrowError = false
        customError = Errors.notDefined
        mockLeaderboard = nil
        mockAPIMessage = nil
        portMapListToReturn = nil
        noticeListToReturn = nil
        getNotificationsCalled = false
        lastPcpid = nil
        staticIPListToReturn = nil
        getStaticIpListCalled = false
        getLeaderboardCalled = false
        recordScoreCalled = false
        lastRecordedScore = nil
        lastRecordedUserId = nil
        mockServerList = nil
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
        fatalError("Not implemented")
    }

    func getWebSession() async throws -> WebSession {
        fatalError("Not implemented")
    }

    func deleteSession() async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func getSession(sessionAuth: String) async throws -> Session {
        fatalError("Not implemented")
    }

    // MARK: - Signup and Login Methods

    func login(username: String, password: String, code2fa: String, secureToken: String, captchaSolution: String, captchaTrailX: [CGFloat], captchaTrailY: [CGFloat]) async throws -> Session {
        fatalError("Not implemented")
    }

    func signup(username: String, password: String, referringUsername: String, email: String, voucherCode: String, secureToken: String, captchaSolution: String, captchaTrailX: [CGFloat], captchaTrailY: [CGFloat]) async throws -> Session {
        fatalError("Not implemented")
    }

    func authTokenLogin(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        fatalError("Not implemented")
    }

    func authTokenSignup(useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        fatalError("Not implemented")
    }

    func regToken() async throws -> Token {
        fatalError("Not implemented")
    }

    func signUpUsingToken(token: String) async throws -> Session {
        fatalError("Not implemented")
    }

    func ssoSession(token: String) async throws -> SSOSession {
        fatalError("Not implemented")
    }

    // MARK: - Account Methods

    func addEmail(email: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func confirmEmail() async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func claimAccount(username: String, password: String, email: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func getXpressLoginCode() async throws -> XPressLoginCodeResponse {
        fatalError("Not implemented")
    }

    func verifyXPressLoginCode(code: String, sig: String) async throws -> XPressLoginVerifyResponse {
        fatalError("Not implemented")
    }

    func cancelAccount(password: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func verifyTvLoginCode(code: String) async throws -> XPressLoginVerifyResponse {
        fatalError("Not implemented")
    }

    func claimVoucherCode(code: String) async throws -> ClaimVoucherCodeResponse {
        fatalError("Not implemented")
    }

    // MARK: - VPN Methods

    func getServerList(languageCode: String, revision: String, isPro: Bool, alcList: [String]) async throws -> ServerList {
        guard let serverList = mockServerList, !shouldThrowError else {
            throw customError
        }
        return serverList
    }

    func getStaticIpList() async throws -> StaticIPList {
        getStaticIpListCalled = true

        if shouldThrowError {
            throw customError
        }

        guard let staticIPList = staticIPListToReturn else {
            // Return default mock static IP list from sample data
            let jsonData = SampleDataStaticIP.staticIPListJSON.data(using: .utf8)!
            let staticIPList = try! JSONDecoder().decode(StaticIPList.self, from: jsonData)
            return staticIPList
        }

        return staticIPList
    }

    func getOpenVPNServerConfig(openVPNVersion: String) async throws -> String {
        fatalError("Not implemented")
    }

    func getIKEv2ServerCredentials() async throws -> IKEv2ServerCredentials {
        fatalError("Not implemented")
    }

    func getOpenVPNServerCredentials() async throws -> OpenVPNServerCredentials {
        fatalError("Not implemented")
    }

    func getPortMap(version: Int, forceProtocols: [String]) async throws -> PortMapList {
        if shouldThrowError {
            throw customError
        }

        guard let portMapList = portMapListToReturn else {
            throw NSError(domain: "MockAPIManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No port map list configured"])
        }

        return portMapList
    }

    // MARK: - Billing Methods

    func getMobileBillingPlans(promo: String?) async throws -> MobilePlanList {
        fatalError("Not implemented")
    }

    func postBillingCpID(pcpID: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func verifyApplePayment(appleID: String, appleData: String, appleSIG: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    // MARK: - Robert Methods

    func getRobertFilters() async throws -> RobertFilters {
        fatalError("Not implemented")
    }

    func updateRobertSettings(id: String, status: Int32) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func syncRobertFilters() async throws -> APIMessage {
        fatalError("Not implemented")
    }

    // MARK: - Other Methods

    func recordInstall(platform: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func getNotifications(pcpid: String) async throws -> NoticeList {
        getNotificationsCalled = true
        lastPcpid = pcpid

        if shouldThrowError {
            throw customError
        }

        guard let noticeList = noticeListToReturn else {
            // Return default mock notice list from sample data
            let jsonData = SampleDataNotifications.notificationListJSON.data(using: .utf8)!
            let noticeList = try! JSONDecoder().decode(NoticeList.self, from: jsonData)
            return noticeList
        }

        return noticeList
    }

    func getIp() async throws -> MyIP {
        fatalError("Not implemented")
    }

    func sendDebugLog(username: String, log: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }

    func sendTicket(email: String, name: String, subject: String, message: String, category: String, type: String, channel: String, platform: String) async throws -> APIMessage {
        fatalError("Not implemented")
    }
}
