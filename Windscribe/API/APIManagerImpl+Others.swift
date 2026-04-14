//
//  APIManagerImpl+Others.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

extension APIManagerImpl {
    func checkUpdate(appVersion: String, appBuild: String, osVersion: String) async throws -> CheckUpdateModel {
        return try await apiUtil.makeApiCall(modalType: CheckUpdateModel.self) { completion in
            self.api.checkUpdate(0,
                                 appVersion: appVersion,
                                 appBuild: appBuild,
                                 osVersion: osVersion,
                                 osBuild: "",
                                 callback: completion)
        }
    }

    func sendDebugLog(username: String, log: String) async throws -> APIMessage {
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.debugLog(username, strLog: log, callback: completion)
        }
    }

    func getIp(usePingTest: Bool = false) async throws -> String {
        if usePingTest {
            return try await apiUtil.makeApiCall(modalType: String.self) { completion in
                self.api.pingTest(5000, callback: completion)
            }
        } else {
            let myIP = try await apiUtil.makeApiCall(modalType: MyIP.self) { completion in
                self.api.myIP(completion)
            }
            return myIP.userIp
        }
    }

    func getNotifications(pcpid: String) async throws -> NoticeList {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: NoticeList.self) { completion in
            self.api.notifications(sessionAuth, pcpid: pcpid, callback: completion)
        }
    }

    func recordInstall(platform _: String) async throws -> APIMessage {
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.recordInstall(false, callback: completion)
        }
    }

    func sendTicket(email: String, name: String, subject: String, message: String, category: String, type: String, channel: String, platform _: String) async throws -> APIMessage {
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.sendSupportTicket(email, supportName: name, supportSubject: subject, supportMessage: message, supportCategory: category, type: type, channel: channel, callback: completion)
        }
    }

    func getShakeForDataLeaderboard() async throws -> Leaderboard {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: Leaderboard.self) { completion in
            self.api.shakeData(sessionAuth, callback: completion)
        }
    }

    func recordShakeForDataScore(score: Int, userID: String) async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        var signatureText = ""
        signatureText.append(sessionAuth)
        signatureText.append(userID)
        signatureText.append(APIParameterValues.platform)
        signatureText.append("\(score)")
        signatureText.append("swiftMETROtaylorSTATION127!")

        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.recordShake(forDataScore: sessionAuth,
                                 score: "\(score)",
                                 signature: signatureText,
                                 callback: completion)
        }
    }

    func rotateIp() async throws -> Bool {
        let result = try await bridgeApi.rotateIp()
        return try apiUtil.checkBridgeResult(statusCode: result.0, message: result.1)
    }

    func pinIp(ip: String) async throws -> Bool {
        let result = try await bridgeApi.pinIp(ip: ip)
        return try apiUtil.checkBridgeResult(statusCode: result.0, message: result.1)
    }

    func wgUnlockParams() async throws -> UnblockWgResponse {
            guard let sessionAuth = userSessionRepository?.sessionAuth else {
                throw Errors.validationFailure
            }
            return try await apiUtil.makeApiCall(modalType: UnblockWgResponse.self) { completion in
                self.api.amneziawgUnblockParams(sessionAuth, callback: completion)
            }
    }
}
