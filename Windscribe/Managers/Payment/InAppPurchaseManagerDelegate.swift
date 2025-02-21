//
//  InAppPurchaseManagerDelegate.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit

protocol InAppPurchaseManagerDelegate: AnyObject {
    func didFetchAvailableProducts(windscribeProducts: [WindscribeInAppProduct])
    func purchasedSuccessfully(transaction: SKPaymentTransaction, appleID: String, appleData: String, appleSIG: String)
    func failedToPurchase()
    func failedCanceledByUser()
    func failedDueToNetworkIssue()
    func unableToMakePurchase()
    func setVerifiedTransaction(transaction: UncompletedTransactions?, error: String?)
    func failedToLoadProducts()
    func unableToRestorePurchase(error: Error)
}
