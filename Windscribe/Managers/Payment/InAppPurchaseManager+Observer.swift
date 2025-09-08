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
    func request(_: SKRequest, didFailWithError error: Error) {
        availableProductsSubject.send(.failed(error: error))

        delegate?.failedToLoadProducts()

        if let continuation = productsFetchContinuation {
            productsFetchContinuation = nil
            continuation.resume(throwing: error)
        }
    }

    func productsRequest(_: SKProductsRequest, didReceive response: SKProductsResponse) {
        let products = response.products
        guard products.isEmpty == false else {
            let error = InAppPurchaseError.noProductsAvailable
            availableProductsSubject.send(.failed(error: error))

            delegate?.failedToLoadProducts()

            if let continuation = productsFetchContinuation {
                productsFetchContinuation = nil
                continuation.resume(throwing: error)
            }
            return
        }

        guard let plans = localDatabase.getMobilePlans() else {
            let error = InAppPurchaseError.productsFetchFailed("Failed to load mobile plans")
            availableProductsSubject.send(.failed(error: error))

            delegate?.failedToLoadProducts()

            if let continuation = productsFetchContinuation {
                productsFetchContinuation = nil
                continuation.resume(throwing: error)
            }
            return
        }

        let windscribeProducts = products.map { item in
            WindscribeInAppProduct(product: item, plans: Array(plans))
        }
        iapProducts = windscribeProducts

        availableProductsSubject.send(.loaded(windscribeProducts))

        delegate?.didFetchAvailableProducts(windscribeProducts: iapProducts)

        if let continuation = productsFetchContinuation {
            productsFetchContinuation = nil
            continuation.resume(returning: windscribeProducts)
        }
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
        logger.logI("InAppPurchaseManager", "Uncompleted transations: \(uncompletedTransactions)")

        restoreStateSubject.send(.success)

        verifyUncompletedTransactions(transactions: uncompletedTransactions)

        if let continuation = restoreContinuation {
            restoreContinuation = nil
            continuation.resume()
        }
    }

    func paymentQueue(_: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: Error) {
        restoreStateSubject.send(.failed(error: error))

        delegate?.unableToRestorePurchase(error: error)

        if let continuation = restoreContinuation {
            restoreContinuation = nil
            continuation.resume(throwing: error)
        }
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
                purchaseStateSubject.send(.success(transaction: transaction))

                matchInAppPurchaseWithWindscribeData(transaction: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)
                logger.logI("InAppPurchaseManager", "Apple InApp Purchase successful.")

                if let continuation = purchaseContinuation,
                   let appleData = transaction.appleData,
                   let transactionID = transaction.transactionIdentifier,
                   let signature = transaction.signature {
                    purchaseContinuation = nil
                    let result = PurchaseResult.success(
                        transaction: transaction,
                        appleID: transactionID,
                        appleData: appleData,
                        signature: signature
                    )
                    continuation.resume(returning: result)
                }

            case .failed:
                logger.logI("InAppPurchaseManager", "Failed to purchase")

                let error = transaction.error ?? InAppPurchaseError.transactionFailed("Unknown error")
                purchaseStateSubject.send(.failed(error: error))

                handleTransactionError(transaction: transaction)
                SKPaymentQueue.default().finishTransaction(transaction)

                if let continuation = purchaseContinuation {
                    purchaseContinuation = nil
                    if let skError = transaction.error as? SKError, skError.code == .paymentCancelled {
                        continuation.resume(returning: .cancelled)
                    } else {
                        continuation.resume(returning: .failed(error))
                    }
                }

            default:
                break
            }
        }
    }

    private func handleTransactionError(transaction: SKPaymentTransaction) {
            if let error = transaction.error as? SKError {
                switch error.code {
                case .paymentCancelled:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The user canceled the transaction.")
                    delegate?.failedCanceledByUser()
                case .clientInvalid:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The user is not allowed to make the payment.")
                    delegate?.failedToPurchase()
                case .paymentNotAllowed:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: Payments are disabled on this device.")
                    delegate?.failedToPurchase()
                case .paymentInvalid:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The purchase identifier was invalid.")
                    delegate?.failedToPurchase()
                case .storeProductNotAvailable:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The requested product is not available in the current storefront.")
                    delegate?.failedToPurchase()
                case .cloudServicePermissionDenied:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The user has not allowed access to cloud service information.")
                    delegate?.failedToPurchase()
                case .cloudServiceNetworkConnectionFailed:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: Cloud service network connection failed.")
                    delegate?.failedToPurchase()
                case .cloudServiceRevoked:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The user has revoked permission to use this cloud service.")
                    delegate?.failedToPurchase()
                case .privacyAcknowledgementRequired:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The user has not acknowledged Apple's privacy policy.")
                    delegate?.failedToPurchase()
                case .unauthorizedRequestData:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The app is attempting to use unauthorized request data.")
                    delegate?.failedToPurchase()
                case .invalidOfferIdentifier:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The specified promotional offer identifier is invalid.")
                    delegate?.failedToPurchase()
                case .invalidOfferPrice:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The specified promotional offer price is invalid.")
                    delegate?.failedToPurchase()
                case .overlayCancelled:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The user dismissed the overlay.")
                    delegate?.failedCanceledByUser()
                case .overlayTimeout:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The overlay did not load in time.")
                    delegate?.failedToPurchase()
                case .overlayPresentedInBackgroundScene:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The overlay was presented while the app was in the background.")
                    delegate?.failedToPurchase()
                case .unknown:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: An unknown error occurred.")
                    delegate?.failedToPurchase()
                default:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: \(error.localizedDescription)")
                    delegate?.failedToPurchase()
                }
            } else if let error = transaction.error as NSError?, error.domain == NSURLErrorDomain {
                switch error.code {
                case NSURLErrorNotConnectedToInternet:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: No internet connection. Please check your connection and try again.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorNetworkConnectionLost:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: Network connection was lost. Please try again.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorTimedOut:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: The request timed out. Please check your connection and try again.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorCannotFindHost:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: Cannot find the server. Please check your internet connection.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorCannotConnectToHost:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: Unable to connect to the server. Try again later.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorDNSLookupFailed:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: DNS lookup failed. Check your network settings.")
                    delegate?.failedDueToNetworkIssue()
                case NSURLErrorHTTPTooManyRedirects:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: Too many redirects occurred. Try again later.")
                    delegate?.failedToPurchase()
                default:
                    logger.logI("InAppPurchaseManager", "Failed to purchase: \(error.localizedDescription)")
                    delegate?.failedToPurchase()
                }
            } else {
                logger.logI("InAppPurchaseManager", "Failed to purchase: An unexpected error occurred.")
                delegate?.failedToPurchase()
            }
        }
}
