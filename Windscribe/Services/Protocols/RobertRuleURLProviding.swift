//
//  RobertRuleURLProviding.swift
//  Windscribe
//
//  Created by Codescribe on 2026-06-04.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Provides authenticated R.O.B.E.R.T. custom-rule URLs for Neo screens.
protocol RobertRuleURLProviding: Sendable {
    func customRulesURL() async throws -> URL
}

/// Actor adapter over the legacy API manager so the non-Sendable API surface
/// stays isolated behind the Neo protocol.
actor LegacyRobertRuleURLProvider: RobertRuleURLProviding {
    private let apiManager: APIManager

    init(apiManager: APIManager) {
        self.apiManager = apiManager
    }

    func customRulesURL() async throws -> URL {
        let webSession = try await apiManager.getWebSession()
        guard let url = LinkProvider.getRobertRulesUrl(session: webSession.tempSession) else {
            throw RobertRuleURLProviderError.invalidURL
        }
        return url
    }
}

enum RobertRuleURLProviderError: Error {
    case invalidURL
}
