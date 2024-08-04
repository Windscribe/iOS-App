//
//  APIManagerImpl+Others.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift

extension APIManagerImpl {
    func sendDebugLog(username: String, log: String) -> Single<APIMessage> {
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.debugLog(username, strLog: log, callback: completion)
        }
    }

    func getIp() -> Single<MyIP> {
        return makeApiCall(modalType: MyIP.self) { completion in
            self.api.myIP(completion)
        }
    }

    func getNotifications(pcpid: String) -> Single<NoticeList> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: NoticeList.self) { completion in
            self.api.notifications(sessionAuth, pcpid: pcpid, callback: completion)
        }
    }

    func recordInstall(platform: String) -> Single<APIMessage> {
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.recordInstall(false, callback: completion)
        }
    }

    func sendTicket(email: String, name: String, subject: String, message: String, category: String, type: String, channel: String, platform: String) -> Single<APIMessage> {
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.sendSupportTicket(email, supportName: name, supportSubject: subject, supportMessage: message, supportCategory: category, type: type, channel: channel, callback: completion)
        }
    }

    func getShakeForDataLeaderboard() -> Single<Leaderboard> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: Leaderboard.self) { completion in
            self.api.shakeData(sessionAuth, callback: completion)
        }
    }

    func recordShakeForDataScore(score: Int, userID: String) -> Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        var signatureText = ""
        signatureText.append(sessionAuth)
        signatureText.append(userID)
        signatureText.append(APIParameterValues.platform)
        signatureText.append("\(score)")
        signatureText.append("swiftMETROtaylorSTATION127!")

        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.recordShake(forDataScore: sessionAuth,
                                 score: "\(score)",
                                 signature: signatureText,
                                 callback: completion)
        }
    }
}
