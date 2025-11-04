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
    func getRobertFilters() async throws -> RobertFilters {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: RobertFilters.self) { completion in
            self.api.getRobertFilters(sessionAuth, callback: completion)
        }
    }

    func updateRobertSettings(id: String, status: Int32) async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.setRobertFilter(sessionAuth, id: id, status: status, callback: completion)
        }
    }

    func syncRobertFilters() async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self) { completion in
            self.api.syncRobert(sessionAuth, callback: completion)
        }
    }
}
