//
//  APIManagerImpl+Session.swift
//  Windscribe
//
//  Created by Ginder Singh on 2023-12-31.
//  Copyright © 2023 Windscribe. All rights reserved.
//

import Foundation

extension APIManagerImpl {
    func getSession(_ appleID: String?) async throws -> SessionModel {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        let revision = preferences.getServerRevision()
        let useBackup = preferences.getRoutingType().apiValue
        return try await apiUtil.makeApiCall(modalType: SessionModel.self) { completion in
            self.api.session(sessionAuth, appleId: appleID ?? "", gpDeviceId: "", invRev: revision, backup: useBackup, callback: completion)
        }
    }

    func getWebSession() async throws -> WebSession {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: WebSession.self) { completion in
            self.api.webSession(sessionAuth, callback: completion)
        }
    }

    func deleteSession() async throws -> APIMessage {
        guard let sessionAuth = userSessionRepository?.sessionAuth else {
            throw Errors.validationFailure
        }
        return try await apiUtil.makeApiCall(modalType: APIMessage.self, maxRetries: 3) { completion in
            self.api.deleteSession(sessionAuth, callback: completion)
        }
    }

    func getSession(sessionAuth: String) async throws -> SessionModel {
        let revision = preferences.getServerRevision()
        let useBackup = preferences.getRoutingType().apiValue
        return try await apiUtil.makeApiCall(modalType: SessionModel.self) { completion in
            self.api.session(sessionAuth, appleId: "", gpDeviceId: "", invRev: revision, backup: useBackup, callback: completion)
        }
    }
}
