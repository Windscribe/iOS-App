//
//  APIManagerImpl+Others.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

extension APIManagerImpl {
    func sendDebugLog(username: String, log: String) async throws -> APIMessage {
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.debugLog(username, strLog: log, callback: completion)
        }
    }

    func getIp() async throws -> MyIP {
        return try await apiUtil.makeApiCall(modalType: MyIP.self) { completion in
            self.api.myIP(completion)
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
}
