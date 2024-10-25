//
//  InAppPurchaseManager+SKPaymentTransactionObserver.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit
extension InAppPurchaseManagerImpl: SKProductsRequestDelegate,
                                SKPaymentTransactionObserver {

    func request(_ request: SKRequest, didFailWithError error: Error) {
        delegate?.failedToLoadProducts()
    }

    func productsRequest(_ request: SKProductsRequest,
                         didReceive response: SKProductsResponse) {
        let products = response.products
        guard products.isEmpty == false else {
            delegate?.failedToLoadProducts()
            return
        }
        guard let plans = localDatabase.getMobilePlans() else {
            delegate?.failedToLoadProducts()
            return
        }
        let windscribeProducts = products.map { item in
            WindscribeInAppProduct(product: item,  plans: Array(plans))
        }
        iapProducts = windscribeProducts
        delegate?.didFetchAvailableProducts(windscribeProducts: iapProducts)
    }

    private func formatterCurrency(number: NSNumber,
                                   locale: Locale) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        return formatter.string(from: number)
    }

    /// Called to send uncompleted transactions for verification.
    ///  Backend will only verify items which are valid and never added to the database.
    /// - Parameter transactions: transactions added to queue as a result of user request of restore all completed transactions.
    private func verifyUncompletedTransactions(transactions: [UncompletedTransactions]) {
        var firstVerifiedTransaction: UncompletedTransactions?
        var firstError: String?
        let group = DispatchGroup()
        for transaction in transactions {
            group.enter()
            apiManager.verifyApplePayment(appleID: transaction.transactionID, appleData: transaction.appleData, appleSIG: transaction.signature).subscribe(onSuccess: { _ in
                defer { group.leave() }
                if firstVerifiedTransaction == nil {
                    firstVerifiedTransaction = transaction
                }
            }, onFailure: { error in
                defer { group.leave() }
                if firstError == nil {
                    firstError = "\(error)"
                }
            }).disposed(by: dispose)
        }
        group.notify(queue: .main) {
            self.delegate?.setVerifiedTransaction(transaction: firstVerifiedTransaction, error: firstError)
        }
    }

    private func filterUncompletedTransactions(transactions: [SKPaymentTransaction]) -> [UncompletedTransactions] {
        var transactionDic: [String: SKPaymentTransaction] = [:]
        transactions.filter { $0.transactionState == .restored }
            .sorted { t1, t2 in
                if let date1 = t1.transactionDate, let date2 = t2.transactionDate {
                    return date1 > date2
                }
                return false
            }
            .forEach { transaction in
            if let original = transaction.original, let id = original.transactionIdentifier {
                transactionDic[id] = original
            }
        }
        return transactionDic.values.compactMap { UncompletedTransactions(transaction: $0) }
    }

    func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
        logger.logD(InAppPurchaseManager.self, "Uncompleted transations: \(uncompletedTransactions)")
        verifyUncompletedTransactions(transactions: uncompletedTransactions)
    }

    func paymentQueue(_ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        delegate?.unableToRestorePurchase(error: error)
    }

    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        if isComingFromRestore {
            uncompletedTransactions = filterUncompletedTransactions(transactions: transactions)
            uncompletedTransactions.forEach { transaction in
                SKPaymentQueue.default().finishTransaction(transaction.transaction)
            }
            return
        }
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                self.matchInAppPurchaseWithWindscribeData(transaction: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                logger.logD(InAppPurchaseManager.self, "Apple InApp Purchase successful.")

            case .failed:
                logger.logD(InAppPurchaseManager.self, "Failed to purchase")

                delegate?.failedToPurchase()
                SKPaymentQueue.default().finishTransaction(transaction)
            default:
                break
            }
        }
    }

}
