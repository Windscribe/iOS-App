//
//  InAppPurchaseManager.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit

protocol InAppPurchaseManager {
    func canMakePurchases() -> Bool
    func purchase(windscribeInAppProduct: WindscribeInAppProduct)
    func restorePurchase()
    func fetchAvailableProducts(productIDs: [String])
    func matchInAppPurchaseWithWindscribeData(transaction: SKPaymentTransaction)
    func verifyPendingTransaction()
    var delegate: InAppPurchaseManagerDelegate? { get set }
}
