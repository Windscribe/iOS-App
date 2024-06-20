//
//  APIManagerImpl+Robert.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-24.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
extension APIManagerImpl {
    func getRobertFilters() -> Single<RobertFilters> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: RobertFilters.self) { completion in
            self.api.getRobertFilters(sessionAuth, callback: completion)
        }
    }

    func updateRobertSettings(id: String, status: Int32) -> Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.setRobertFilter(sessionAuth, id: id, status: status, callback: completion)
        }
    }

    func syncRobertFilters() -> Single<APIMessage> {
        guard let sessionAuth = userRepository?.sessionAuth else {
            return Single.error(Errors.validationFailure)
        }
        return makeApiCall(modalType: APIMessage.self) { completion in
            self.api.syncRobert(sessionAuth, callback: completion)
        }
    }
}
