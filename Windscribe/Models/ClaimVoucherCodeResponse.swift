//
//  ClaimVoucherCodeResponse.swift
//  Windscribe
//
//  Created by Bushra Sagir on 03/10/24.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation

class ClaimVoucherCodeResponse: Decodable {
    let isClaimed: Bool
    let isUsed: Bool
    let isTaken: Bool
    let emailRequired: Bool?

    // Discount code fields (for IAP purchase)
    let promoCode: Int?
    let promoDiscount: Int?
    let promoPrice: String?
    let promoYearPlan: Int?
    let promoYearPrice: String?

    // Direct plan activation fields (activates plan immediately)
    let billingPlanId: Int?
    let isPremium: Int?
    let newPlanId: Int?
    let newPlanName: String?

    enum CodingKeys: String, CodingKey {
        case data
        case isClaimed = "voucher_claimed"
        case isUsed = "voucher_used"
        case isTaken = "voucher_taken"
        case emailRequired = "email_required"
        case promoCode = "promo_code"
        case promoDiscount = "promo_discount"
        case promoPrice = "promo_price"
        case promoYearPlan = "promo_year_plan"
        case promoYearPrice = "promo_year_price"
        case billingPlanId = "billing_plan_id"
        case isPremium = "is_premium"
        case newPlanId = "new_plan_id"
        case newPlanName = "new_plan_name"
    }

    var isDiscountCode: Bool {
        return promoCode != nil
    }

    var isDirectPlanActivation: Bool {
        return newPlanId != nil
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let data = try container.nestedContainer(keyedBy: CodingKeys.self, forKey: .data)
        isClaimed = try data.decodeIfPresent(Bool.self, forKey: .isClaimed) ?? false
        isUsed = try data.decodeIfPresent(Bool.self, forKey: .isUsed) ?? false
        isTaken = try data.decodeIfPresent(Bool.self, forKey: .isTaken) ?? false
        emailRequired = try data.decodeIfPresent(Bool.self, forKey: .emailRequired)

        // Decode discount code fields
        promoCode = try data.decodeIfPresent(Int.self, forKey: .promoCode)
        promoDiscount = try data.decodeIfPresent(Int.self, forKey: .promoDiscount)
        promoPrice = try data.decodeIfPresent(String.self, forKey: .promoPrice)
        promoYearPlan = try data.decodeIfPresent(Int.self, forKey: .promoYearPlan)
        promoYearPrice = try data.decodeIfPresent(String.self, forKey: .promoYearPrice)

        // Decode direct plan activation fields
        billingPlanId = try data.decodeIfPresent(Int.self, forKey: .billingPlanId)
        isPremium = try data.decodeIfPresent(Int.self, forKey: .isPremium)
        newPlanId = try data.decodeIfPresent(Int.self, forKey: .newPlanId)
        newPlanName = try data.decodeIfPresent(String.self, forKey: .newPlanName)
    }
}
