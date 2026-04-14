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

    // Session tracking
    var mockSession: SessionModel?

    // MobilePlan tracking
    var mobilePlanListToReturn: MobilePlanList?
    var getMobileBillingPlansCalled = false
    var lastPromoCode: String?

    // Track method calls
    var getLeaderboardCalled = false
    var recordScoreCalled = false
    var lastRecordedScore: Int?
    var lastRecordedUserId: String?
    var rotateIpCalled = false
    var pinIpCalled = false
    var lastPinnedIp: String?

    var mockServerList: ServerMachinesListModel?
    var mockLocationList: LocationsListModel?

    // UnblockWg tracking
    var wgUnlockParamsCalled = false
    var mockUnblockWgResponse: Windscribe.UnblockWgResponse?

    // Robert tracking
    var getRobertFiltersCalled = false
    var updateRobertSettingsCalled = false
    var syncRobertFiltersCalled = false
    var mockRobertFilters: RobertFilters?
    var lastRobertFilterId: String?
    var lastRobertFilterStatus: Int32?
    var shouldThrowSyncError = false
    var customSyncError: Error = Errors.notDefined

    // Credentials tracking
    var mockOpenVPNCredentials: OpenVPNServerCredentials?
    var mockIKEv2Credentials: IKEv2ServerCredentials?
    var mockOpenVPNServerConfig: String?

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
        mobilePlanListToReturn = nil
        getMobileBillingPlansCalled = false
        lastPromoCode = nil
        getLeaderboardCalled = false
        recordScoreCalled = false
        lastRecordedScore = nil
        lastRecordedUserId = nil
        rotateIpCalled = false
        pinIpCalled = false
        lastPinnedIp = nil
        mockServerList = nil
        mockLocationList = nil
        getIpCalled = false
        getIpUsedPingTest = nil
        mockIpAddress = nil
        wgUnlockParamsCalled = false
        mockUnblockWgResponse = nil
        getRobertFiltersCalled = false
        updateRobertSettingsCalled = false
        syncRobertFiltersCalled = false
        mockRobertFilters = nil
        lastRobertFilterId = nil
        lastRobertFilterStatus = nil
        shouldThrowSyncError = false
        customSyncError = Errors.notDefined
        mockOpenVPNCredentials = nil
        mockIKEv2Credentials = nil
        mockOpenVPNServerConfig = nil
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

    func getSession(_ appleID: String?) async throws -> SessionModel {
        if shouldThrowError {
            throw customError
        }

        guard let session = mockSession else {
            throw Errors.notDefined
        }

        return session
    }

    func getWebSession() async throws -> WebSession {
        throw Errors.notDefined
    }

    func deleteSession() async throws -> APIMessage {
        throw Errors.notDefined
    }

    func getSession(sessionAuth: String) async throws -> SessionModel {
        if shouldThrowError {
            throw customError
        }

        guard let session = mockSession else {
            throw Errors.notDefined
        }

        return session
    }

    // MARK: - Signup and Login Methods

    func login(username: String, password: String, code2fa: String, secureToken: String, captchaSolution: String, captchaTrailX: [CGFloat], captchaTrailY: [CGFloat]) async throws -> SessionModel {
        if shouldThrowError {
            throw customError
        }

        guard let session = mockSession else {
            throw Errors.notDefined
        }

        return session
    }

    func signup(username: String, password: String, referringUsername: String, email: String, voucherCode: String, secureToken: String, captchaSolution: String, captchaTrailX: [CGFloat], captchaTrailY: [CGFloat]) async throws -> SessionModel {
        if shouldThrowError {
            throw customError
        }

        guard let session = mockSession else {
            throw Errors.notDefined
        }

        return session
    }

    var authTokenLoginCalled = false
    var authTokenSignupCalled = false
    var lastAuthTokenUsername: String?

    func authTokenLogin(username: String, useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        authTokenLoginCalled = true
        lastAuthTokenUsername = username
        if shouldThrowError { throw customError }
        throw Errors.notDefined
    }

    func authTokenSignup(username: String, useAsciiCaptcha: Bool) async throws -> AuthTokenResponse {
        authTokenSignupCalled = true
        lastAuthTokenUsername = username
        if shouldThrowError { throw customError }
        throw Errors.notDefined
    }

    func regToken() async throws -> Token {
        throw Errors.notDefined
    }

    func signUpUsingToken(token: String) async throws -> SessionModel {
        if shouldThrowError {
            throw customError
        }

        guard let session = mockSession else {
            throw Errors.notDefined
        }

        return session
    }

    func ssoSession(token: String) async throws -> SSOSession {
        throw Errors.notDefined
    }

    // MARK: - Account Methods

    func addEmail(email: String) async throws -> APIMessage {
        throw Errors.notDefined
    }

    func confirmEmail() async throws -> APIMessage {
        throw Errors.notDefined
    }

    func resetPassword(email: String) async throws -> APIMessage {
        return APIMessage.mock(success: true)
    }

    func claimAccount(username: String, password: String, email: String) async throws -> APIMessage {
        throw Errors.notDefined
    }

    func getXpressLoginCode() async throws -> XPressLoginCodeResponse {
        throw Errors.notDefined
    }

    func verifyXPressLoginCode(code: String, sig: String) async throws -> XPressLoginVerifyResponse {
        throw Errors.notDefined
    }

    func cancelAccount(password: String) async throws -> APIMessage {
        throw Errors.notDefined
    }

    func verifyTvLoginCode(code: String) async throws -> XPressLoginVerifyResponse {
        throw Errors.notDefined
    }

    func claimVoucherCode(code: String) async throws -> ClaimVoucherCodeResponse {
        throw Errors.notDefined
    }

    // MARK: - VPN Methods

    func getLocationsList() async throws -> LocationsListModel {
        if shouldThrowError {
            throw customError
        }

        guard let locationList = mockLocationList else {
            throw Errors.datanotfound
        }

        return locationList
    }

    func getServerMachinesList() async throws -> ServerMachinesListModel {
        if shouldThrowError {
            throw customError
        }

        guard let serverList = mockServerList else {
            throw Errors.datanotfound
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
        if shouldThrowError {
            throw customError
        }

        guard let config = mockOpenVPNServerConfig else {
            throw NSError(domain: "MockAPIManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No OpenVPN server config configured"])
        }

        return config
    }

    func getIKEv2ServerCredentials() async throws -> IKEv2ServerCredentials {
        if shouldThrowError {
            throw customError
        }

        guard let credentials = mockIKEv2Credentials else {
            throw NSError(domain: "MockAPIManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No IKEv2 credentials configured"])
        }

        return credentials
    }

    func getOpenVPNServerCredentials() async throws -> OpenVPNServerCredentials {
        if shouldThrowError {
            throw customError
        }

        guard let credentials = mockOpenVPNCredentials else {
            throw NSError(domain: "MockAPIManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No OpenVPN credentials configured"])
        }

        return credentials
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
        getMobileBillingPlansCalled = true
        lastPromoCode = promo

        if shouldThrowError {
            throw customError
        }

        guard let mobilePlanList = mobilePlanListToReturn else {
            // Return default mock mobile plan list from sample data
            let jsonData = SampleDataMobilePlan.mobilePlanListJSON.data(using: .utf8)!
            let mobilePlanList = try! JSONDecoder().decode(MobilePlanList.self, from: jsonData)
            return mobilePlanList
        }

        return mobilePlanList
    }

    func postBillingCpID(pcpID: String) async throws -> APIMessage {
        throw Errors.notDefined
    }

    func verifyApplePayment(appleID: String, appleData: String, appleSIG: String) async throws -> APIMessage {
        throw Errors.notDefined
    }

    // MARK: - Robert Methods

    func getRobertFilters() async throws -> RobertFilters {
        getRobertFiltersCalled = true

        if shouldThrowError {
            throw customError
        }

        guard let filters = mockRobertFilters else {
            throw Errors.notDefined
        }

        return filters
    }

    func updateRobertSettings(id: String, status: Int32) async throws -> APIMessage {
        updateRobertSettingsCalled = true
        lastRobertFilterId = id
        lastRobertFilterStatus = status

        if shouldThrowError {
            throw customError
        }

        guard let message = mockAPIMessage else {
            return APIMessage(message: "", success: true)
        }

        return message
    }

    func syncRobertFilters() async throws -> APIMessage {
        syncRobertFiltersCalled = true

        if shouldThrowSyncError {
            throw customSyncError
        }

        guard let message = mockAPIMessage else {
            return APIMessage(message: "", success: true)
        }

        return message
    }

    // MARK: - Other Methods

    func checkUpdate(appVersion: String, appBuild: String, osVersion: String) async throws -> CheckUpdateModel {
        fatalError("Not implemented")
    }

    func recordInstall(platform: String) async throws -> APIMessage {
        throw Errors.notDefined
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

    var getIpCalled = false
    var getIpUsedPingTest: Bool?
    var mockIpAddress: String?

    func getIp(usePingTest: Bool = false) async throws -> String {
        getIpCalled = true
        getIpUsedPingTest = usePingTest

        if shouldThrowError {
            throw customError
        }

        // Return mock IP if provided, otherwise default
        return mockIpAddress ?? "192.168.1.100"
    }

    func sendDebugLog(username: String, log: String) async throws -> APIMessage {
        throw Errors.notDefined
    }

    func sendTicket(email: String, name: String, subject: String, message: String, category: String, type: String, channel: String, platform: String) async throws -> APIMessage {
        throw Errors.notDefined
    }

    // MARK: - Bridge API Methods

    func rotateIp() async throws -> Bool {
        rotateIpCalled = true

        if shouldThrowError {
            throw customError
        }

        return true
    }

    func pinIp(ip: String) async throws -> Bool {
        pinIpCalled = true
        lastPinnedIp = ip

        if shouldThrowError {
            throw customError
        }

        return true
    }

    func wgUnlockParams() async throws -> Windscribe.UnblockWgResponse {
        wgUnlockParamsCalled = true

        if shouldThrowError {
            throw customError
        }

        guard let response = mockUnblockWgResponse else {
            // Return default empty response
            return Windscribe.UnblockWgResponse(params: [])
        }

        return response
    }

    // MARK: - Generate Random Credentials

    var generateUsernameCalled = false
    var generatePasswordCalled = false
    var mockGeneratedUsername = "testuser123"
    var mockGeneratedPassword = "testpass456"

    func generateRandomUsername() async throws -> GeneratedCredential {
        generateUsernameCalled = true
        if shouldThrowError { throw customError }
        return try JSONDecoder().decode(GeneratedCredential.self, from: """
            {"data": {"username": "\(mockGeneratedUsername)"}}
            """.data(using: .utf8)!)
    }

    func generateRandomPassword() async throws -> GeneratedCredential {
        generatePasswordCalled = true
        if shouldThrowError { throw customError }
        return try JSONDecoder().decode(GeneratedCredential.self, from: """
            {"data": {"password": "\(mockGeneratedPassword)"}}
            """.data(using: .utf8)!)
    }
}
