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
    var price  = ""
    var extId = ""
    var planLabel = ""
    var product: SKProduct

    init(product: SKProduct, plans: [MobilePlan]) {
        self.product = product
        price = formatterCurrency(number: product.price, locale: product.priceLocale) ?? ""
        extId = product.productIdentifier

        if let plan = plans.first(where: {$0.extId == product.productIdentifier}) {
            if plan.duration == 12 {
                planLabel = "\(price)/\(TextsAsset.UpgradeView.year)"
            } else if plan.duration == 1 {
                planLabel = "\(price)/\(TextsAsset.UpgradeView.month)"
            } else {
                planLabel = "\(price)/\(plan.duration) \(TextsAsset.UpgradeView.months)"
            }
           }
        }

    private func formatterCurrency(number: NSNumber,
                                   locale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: number)
    }
}
