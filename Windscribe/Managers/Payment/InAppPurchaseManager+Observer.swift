//
//  InAppPurchaseManager+Observer.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit

extension InAppPurchaseManagerImpl: SKProductsRequestDelegate, SKPaymentTransactionObserver {
    func request(_: SKRequest, didFailWithError _: Error) {
        delegate?.failedToLoadProducts()
    }

    func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
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
            WindscribeInAppProduct(product: item, plans: Array(plans))
        }
        iapProducts = windscribeProducts
        delegate?.didFetchAvailableProducts(windscribeProducts: iapProducts)
    }

    private func formatterCurrency(number: NSNumber, locale: Locale) -> String? {
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
            apiManager.verifyApplePayment(
                appleID: transaction.transactionID,
                appleData: transaction.appleData,
                appleSIG: transaction.signature).subscribe(onSuccess: { _ in
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

    func paymentQueueRestoreCompletedTransactionsFinished(_: SKPaymentQueue) {
        logger.logD(InAppPurchaseManager.self, "Uncompleted transations: \(uncompletedTransactions)")
        verifyUncompletedTransactions(transactions: uncompletedTransactions)
    }

    func paymentQueue(_: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        delegate?.unableToRestorePurchase(error: error)
    }

    func paymentQueue(_: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        if isComingFromRestore {
            uncompletedTransactions = filterUncompletedTransactions(transactions: transactions)
            for transaction in uncompletedTransactions {
                SKPaymentQueue.default().finishTransaction(transaction.transaction)
            }
            return
        }
        for transaction in transactions {
            switch transaction.transactionState {
            case .purchased:
                matchInAppPurchaseWithWindscribeData(transaction: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                logger.logD(InAppPurchaseManager.self, "Apple InApp Purchase successful.")

            case .failed:
                logger.logD(InAppPurchaseManager.self, "Failed to purchase")
                handleTransactionError(transaction: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)

            default:
                break
            }
        }
    }

    private func handleTransactionError(transaction: SKPaymentTransaction) {
            if let error = transaction.error as? SKError {
                switch error.code {
                case .paymentCancelled:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The user canceled the transaction.")
                    delegate?.failedCanceledByUser()
                case .clientInvalid:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The user is not allowed to make the payment.")
                    delegate?.failedToPurchase()
                case .paymentNotAllowed:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: Payments are disabled on this device.")
                    delegate?.failedToPurchase()
                case .paymentInvalid:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The purchase identifier was invalid.")
                    delegate?.failedToPurchase()
                case .storeProductNotAvailable:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The requested product is not available in the current storefront.")
                    delegate?.failedToPurchase()
                case .cloudServicePermissionDenied:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The user has not allowed access to cloud service information.")
                    delegate?.failedToPurchase()
                case .cloudServiceNetworkConnectionFailed:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: Cloud service network connection failed.")
                    delegate?.failedToPurchase()
                case .cloudServiceRevoked:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The user has revoked permission to use this cloud service.")
                    delegate?.failedToPurchase()
                case .privacyAcknowledgementRequired:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The user has not acknowledged Apple's privacy policy.")
                    delegate?.failedToPurchase()
                case .unauthorizedRequestData:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The app is attempting to use unauthorized request data.")
                    delegate?.failedToPurchase()
                case .invalidOfferIdentifier:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The specified promotional offer identifier is invalid.")
                    delegate?.failedToPurchase()
                case .invalidOfferPrice:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The specified promotional offer price is invalid.")
                    delegate?.failedToPurchase()
                case .overlayCancelled:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The user dismissed the overlay.")
                    delegate?.failedCanceledByUser()
                case .overlayTimeout:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The overlay did not load in time.")
                    delegate?.failedToPurchase()
                case .overlayPresentedInBackgroundScene:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The overlay was presented while the app was in the background.")
                    delegate?.failedToPurchase()
                case .unknown:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: An unknown error occurred.")
                    delegate?.failedToPurchase()
                default:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: \(error.localizedDescription)")
                    delegate?.failedToPurchase()
                }
            } else if let error = transaction.error as NSError?, error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorNotConnectedToInternet:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: No internet connection. Please check your connection and try again.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorNetworkConnectionLost:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: Network connection was lost. Please try again.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorTimedOut:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: The request timed out. Please check your connection and try again.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorCannotFindHost:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: Cannot find the server. Please check your internet connection.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorCannotConnectToHost:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: Unable to connect to the server. Try again later.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorDNSLookupFailed:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: DNS lookup failed. Check your network settings.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorHTTPTooManyRedirects:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: Too many redirects occurred. Try again later.")
                    delegate?.failedToPurchase()
                default:
                    logger.logD(InAppPurchaseManager.self, "Failed to purchase: \(error.localizedDescription)")
                    delegate?.failedToPurchase()
                }
            } else {
                logger.logD(InAppPurchaseManager.self, "Failed to purchase: An unexpected error occurred.")
                delegate?.failedToPurchase()
            }
        }
}
