//
//  WindscribeInAppProduct.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit

struct WindscribeInAppProduct {
    var price = ""
    var extId = ""
    var planLabel = ""
    var tvPlanLabel = ""
    var product: SKProduct

    init(product: SKProduct, plans: [MobilePlan]) {
        self.product = product
        price = formatterCurrency(number: product.price, locale: product.priceLocale) ?? ""
        extId = product.productIdentifier

        if let plan = plans.first(where: { $0.extId == product.productIdentifier }) {
            if plan.duration == 12 {
                planLabel = "\(price)/\(TextsAsset.UpgradeView.year)"
                tvPlanLabel = TextsAsset.UpgradeView.oneYear
            } else if plan.duration == 1 {
                planLabel = "\(price)/\(TextsAsset.UpgradeView.month)"
                tvPlanLabel = TextsAsset.UpgradeView.oneMonth
            } else {
                planLabel = "\(price)/\(plan.duration) \(TextsAsset.UpgradeView.months)"
                tvPlanLabel = planLabel
            }
        }
    }

    private func formatterCurrency(number: NSNumber,
                                   locale: Locale) -> String?
    {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: number)
    }
}
