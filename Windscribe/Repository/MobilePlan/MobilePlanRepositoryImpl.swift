//
//  MobilePlanRepository.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-01.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

protocol MobilePlanRepository {
    func getMobilePlans(promo: String?) async throws -> [MobilePlanModel]
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

    func getMobilePlans(promo: String?) async throws -> [MobilePlanModel] {
        do {
            let plansList = try await apiManager.getMobileBillingPlans(promo: promo)
            let plans = Array(plansList.mobilePlans)
            let planModels = plans.map { MobilePlanModel.init(from: $0) }
            localDatabase.saveMobilePlans(mobilePlansList: plans)

            return planModels
        } catch {
            logger.logE("MobilePlanRepository", "Error getting mobile plans: \(error)")

            // Fallback to cached data if available and not empty
            if let cachedPlans = localDatabase.getMobilePlans(), !cachedPlans.isEmpty {
                return cachedPlans.map { MobilePlanModel.init(from: $0) }
            } else {
                throw error
            }
        }
    }
}
