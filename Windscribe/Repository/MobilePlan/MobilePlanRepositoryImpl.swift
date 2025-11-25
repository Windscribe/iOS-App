//
//  MobilePlanRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol MobilePlanRepository {
    func getMobilePlans(promo: String?) async throws -> [MobilePlan]
}

class MobilePlanRepositoryImpl: MobilePlanRepository {
    private let apiManager: APIManager
    private let localDatabase: LocalDatabase
    private let logger: FileLogger

    init(apiManager: APIManager, localDatabase: LocalDatabase, logger: FileLogger) {
        self.apiManager = apiManager
        self.localDatabase = localDatabase
        self.logger = logger
    }

    func getMobilePlans(promo: String?) async throws -> [MobilePlan] {
        do {
            let plans = try await apiManager.getMobileBillingPlans(promo: promo)
            localDatabase.saveMobilePlans(mobilePlansList: Array(plans.mobilePlans))

            return Array(plans.mobilePlans)
        } catch {
            logger.logE("MobilePlanRepository", "Error getting mobile plans: \(error)")

            // Fallback to cached data if available and not empty
            if let cachedPlans = localDatabase.getMobilePlans(), !cachedPlans.isEmpty {
                return cachedPlans
            } else {
                throw error
            }
        }
    }
}
