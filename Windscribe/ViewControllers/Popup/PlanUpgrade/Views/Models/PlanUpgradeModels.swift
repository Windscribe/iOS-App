//
//  PlanUpgradeModels.swift
//  Windscribe
//
//  Created by Soner Yuksel on 2025-01-30.
//  Copyright © 2025 Windscribe. All rights reserved.
//

import Foundation

enum PlanUpgradeState {
    case success(Bool)
    case loading
    case error(String)
    case titledError(String, String)

}

enum PlanTypes {
    case discounted(WindscribeInAppProduct, MobilePlan)
    case standardPlans([WindscribeInAppProduct], [MobilePlan])
    case unableToLoad
}

enum PlanRestoreState {
    case error(String)
    case success
}

enum PlanUpgradeType {
    case monthly
    case yearly
}
