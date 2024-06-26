//
//  APIManagerImpl+Session.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
extension APIManagerImpl {
    func getSession() -> Single<Session> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: Session.self) { completion in
            self.api.session(sessionAuth, callback: completion)
        }
    }

    func getWebSession() -> Single<WebSession> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: WebSession.self) { completion in
            self.api.webSession(sessionAuth, callback: completion)
        }
    }

    func deleteSession() -> Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.deleteSession(sessionAuth, callback: completion)
        }
    }
}
