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
    var planTitle = ""
    var planPrice = ""
    var planProductPrice = NSDecimalNumber(value: 0)
    var planDescription = ""
    var promoDescription = NSMutableAttributedString(string: "")
    var planName = ""
    var planDiscount = ""
    var product: SKProduct

    init(product: SKProduct, plans: [MobilePlanModel]) {
        self.product = product
        price = formatterCurrency(number: product.price, locale: product.priceLocale) ?? ""
        planProductPrice = product.price
        extId = product.productIdentifier

        if let plan = plans.first(where: { $0.extId == product.productIdentifier }) {
            if plan.duration == 12 {
                planLabel = "\(price)/\(TextsAsset.UpgradeView.year)"
                tvPlanLabel = TextsAsset.UpgradeView.oneYear
                planTitle = TextsAsset.UpgradeView.yearly

                if let formattedPrice = formatPrice(price: product.price, locale: product.priceLocale) {
                    planPrice = formattedPrice.codeFormat
                }

                if let formattedMonthlyPrice =
                    formatPrice(price: yearlyPlanPerMonthPrice(price: product.price), locale: product.priceLocale) {
                    planDescription = "\(formattedMonthlyPrice.symbolFormat)/\(TextsAsset.UpgradeView.month.lowercased()), \(TextsAsset.UpgradeView.billedAnnually)"
                }

                planName = plan.name
                planDiscount = "\(plan.discount)"

                promoDescription =
                setupDiscountLabel(product: product, plan: plan)
                    ?? NSMutableAttributedString(string: planName)

            } else if plan.duration == 1 {
                planLabel = "\(price)/\(TextsAsset.UpgradeView.month)"
                tvPlanLabel = TextsAsset.UpgradeView.oneMonth
                planTitle = TextsAsset.UpgradeView.monthly

                if let formattedPrice = formatPrice(price: product.price, locale: product.priceLocale) {
                    planPrice = formattedPrice.codeFormat
                }

                planDescription = TextsAsset.UpgradeView.billedMonthly

                planName = plan.name
                planDiscount = "\(plan.discount)"

                promoDescription =
                setupDiscountLabel(product: product, plan: plan)
                    ?? NSMutableAttributedString(string: planName)

            } else {
                planLabel = "\(price)/\(plan.duration) \(TextsAsset.UpgradeView.months)"
                tvPlanLabel = planLabel
            }
        }
    }

    private func formatterCurrency(number: NSNumber, locale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: number)
    }

    private func formatPrice(price: NSNumber, locale: Locale) -> (symbolFormat: String, codeFormat: String)? {
        let locale = extractValidLocale(from: locale)

        // Formatter for **Symbol Format** (e.g., "$399.99" or "399,99 zł")
        let symbolFormatter = NumberFormatter()
        symbolFormatter.numberStyle = .currency
        symbolFormatter.locale = locale

        guard let symbolFormat = symbolFormatter.string(from: price) else { return nil }

        // Formatter for **Code Format** (e.g., "USD 399.99" or "PLN 399,99")
        let codeFormatter = NumberFormatter()
        codeFormatter.numberStyle = .currency
        codeFormatter.locale = locale

        if #available(iOS 16.0, *) {
            codeFormatter.currencyCode = locale.currency?.identifier // "USD", "PLN"
        } else {
            codeFormatter.currencyCode = locale.currencyCode
        }

        // **Force Currency Code Instead of Symbol**
        if let currencyCode = codeFormatter.currencyCode {
            codeFormatter.currencySymbol = currencyCode // Replaces "zł" with "PLN"
        }

        guard let codeFormat = codeFormatter.string(from: price) else { return nil }

        return (symbolFormat, codeFormat)
    }

    func extractValidLocale(from locale: Locale) -> Locale {
        let identifier = locale.identifier // Example: "en_PL@currency=PLN"

        // Extract only the region code (last 2 characters after "_")
        if let underscoreIndex = identifier.firstIndex(of: "_") {
            let regionCode = String(identifier.suffix(from: underscoreIndex).dropFirst()) // Get "PL"
            return Locale(identifier: regionCode) // Convert "en_PL" → "PL"
        }

        return locale // Return original if no fix needed
    }

    private func yearlyPlanPerMonthPrice(price: NSNumber) -> NSNumber {
        let monthlyPrice = price.decimalValue / 12

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2

        if let formattedString = formatter.string(from: NSDecimalNumber(decimal: monthlyPrice)),
           let formattedNumber = formatter.number(from: formattedString) {
            return formattedNumber
        }

        return NSDecimalNumber(decimal: monthlyPrice) // Fallback
    }

    private func fullPlanPriceFromDiscount(price: NSNumber, discountPercentage: Int) -> NSNumber {
        let discountedPrice = price.doubleValue
        let fullPrice = discountedPrice / (1 - (Double(discountPercentage) / 100))

        let formattedPrice = String(format: "%.2f", fullPrice) // Ensuring max 2 decimal places
        return NSNumber(value: Double(formattedPrice) ?? fullPrice)
    }

    private func setupDiscountLabel(product: SKProduct, plan: MobilePlanModel) -> NSMutableAttributedString? {

        let originalPrice = fullPlanPriceFromDiscount(price: product.price, discountPercentage: plan.discount)

        guard let formattedOriginalPrice = formatPrice(price: originalPrice, locale: product.priceLocale),
              let discountedPrice =  formatPrice(price: product.price, locale: product.priceLocale) else {
           return nil
        }

        let originalPriceAttributes: [NSAttributedString.Key: Any] = [
            .strikethroughStyle: NSUnderlineStyle.single.rawValue,
            .foregroundColor: UIColor.whiteWithOpacity(opacity: 0.5)
        ]

        let originalPriceAttributed = NSAttributedString(
            string: "\(formattedOriginalPrice.codeFormat)",
            attributes: originalPriceAttributes
        )
        let fullTextDescription = "charged \(plan.duration == 12 ? "every 12 months" : "every month")"

        let fullText = NSMutableAttributedString()
        fullText.append(originalPriceAttributed)
        fullText.append(NSAttributedString(string: " \(discountedPrice.codeFormat) \(fullTextDescription)", attributes: [
            .foregroundColor: UIColor.planUpgradeSelectionHighlight
        ]))

        return fullText
    }
}
