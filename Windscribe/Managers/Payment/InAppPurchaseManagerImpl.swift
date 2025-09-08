//
//  InAppPurchaseManagerImpl.swift
//  Windscribe
//
//  Created by Yalcin on 2019-02-27.
//  Copyright © 2019 Windscribe. All rights reserved.
//

import Foundation
import RxSwift
import StoreKit
import Combine

class InAppPurchaseManagerImpl: NSObject, InAppPurchaseManager, ModernInAppPurchaseManager {
    // MARK: - Modern Interface Publishers

    internal let purchaseStateSubject = CurrentValueSubject<IAPPurchaseState, Never>(.idle)
    internal let restoreStateSubject = CurrentValueSubject<IAPRestoreState, Never>(.idle)
    internal let availableProductsSubject = CurrentValueSubject<IAPProductsState, Never>(.idle)

    var purchaseState: AnyPublisher<IAPPurchaseState, Never> { purchaseStateSubject.eraseToAnyPublisher() }
    var restoreState: AnyPublisher<IAPRestoreState, Never> { restoreStateSubject.eraseToAnyPublisher() }
    var availableProducts: AnyPublisher<IAPProductsState, Never> { availableProductsSubject.eraseToAnyPublisher() }

    // MARK: - Legacy Properties

    weak var delegate: InAppPurchaseManagerDelegate?
    fileprivate var productsRequest = SKProductsRequest()
    var iapProducts = [WindscribeInAppProduct]()
    var isComingFromRestore: Bool = false
    var hasAddObserver: Bool = false
    var uncompletedTransactions: [UncompletedTransactions] = []
    let dispose = DisposeBag()

    // MARK: - Async Continuation Storage

    internal var purchaseContinuation: CheckedContinuation<PurchaseResult, Error>?
    internal var restoreContinuation: CheckedContinuation<Void, Error>?
    internal var productsFetchContinuation: CheckedContinuation<[WindscribeInAppProduct], Error>?

    // MARK: - Dependencies

    let apiManager: APIManager
    let preferences: Preferences
    let logger: FileLogger
    let localDatabase: LocalDatabase

    init(apiManager: APIManager, preferences: Preferences, logger: FileLogger, localDatabase: LocalDatabase) {
        self.apiManager = apiManager
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.logger = logger
        super.init()
    }

    // MARK: - Shared Utility Functions

    func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

    // MARK: - Legacy Interface Implementation

    func purchase(windscribeInAppProduct: WindscribeInAppProduct) {
        if canMakePurchases() && iapProducts.count > 0 {
            isComingFromRestore = false
            let payment = SKPayment(product: windscribeInAppProduct.product)
            if !hasAddObserver {
                SKPaymentQueue.default().add(self)
                hasAddObserver = true
            }
            SKPaymentQueue.default().add(payment)
        } else {
            delegate?.unableToMakePurchase()
        }
    }

    func restorePurchase() {
        isComingFromRestore = true
        if !hasAddObserver {
            SKPaymentQueue.default().add(self)
            hasAddObserver = true
        }
        logger.logI("InAppPurchaseManagerImpl", "Requesting completed transactions to be added to the queue.")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func fetchAvailableProducts(productIDs: [String]) {
        availableProductsSubject.send(.loading)
        let productIdentifiers = Set(productIDs)
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest.delegate = self
        productsRequest.start()
    }

    // MARK: - Modern Interface Implementation

    func purchase(windscribeInAppProduct: WindscribeInAppProduct) async throws -> PurchaseResult {
        guard canMakePurchases() else {
            throw InAppPurchaseError.cannotMakePurchases
        }

        guard iapProducts.count > 0 else {
            throw InAppPurchaseError.noProductsAvailable
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.purchaseContinuation = continuation
            self.isComingFromRestore = false

            self.purchaseStateSubject.send(.purchasing)

            let payment = SKPayment(product: windscribeInAppProduct.product)
            if !hasAddObserver {
                SKPaymentQueue.default().add(self)
                hasAddObserver = true
            }
            SKPaymentQueue.default().add(payment)
        }
    }

    func restorePurchases() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.restoreContinuation = continuation
            self.isComingFromRestore = true

            self.restoreStateSubject.send(.restoring)

            if !hasAddObserver {
                SKPaymentQueue.default().add(self)
                hasAddObserver = true
            }

            logger.logI("InAppPurchaseManagerImpl", "Requesting completed transactions to be restored.")
            SKPaymentQueue.default().restoreCompletedTransactions()
        }
    }

    func fetchAvailableProducts(productIDs: [String]) async throws -> [WindscribeInAppProduct] {
        return try await withCheckedThrowingContinuation { continuation in
            self.productsFetchContinuation = continuation

            self.availableProductsSubject.send(.loading)

            let productIdentifiers = Set(productIDs)
            self.productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
            self.productsRequest.delegate = self
            self.productsRequest.start()
        }
    }

    func matchInAppPurchaseWithWindscribeData(transaction: SKPaymentTransaction) {
        if let appleData = transaction.appleData,
           let transactionID = transaction.transactionIdentifier,
           let signature = transaction.signature {
            delegate?.purchasedSuccessfully(transaction: transaction,
                                            appleID: transactionID,
                                            appleData: appleData,
                                            appleSIG: signature)
        }
    }

    func verifyPendingTransaction() {
        // replace below code with SharedUserDefaults methods
        if let appleID = preferences.getActiveAppleID(),
           let appleData = preferences.getActiveAppleData(),
           let appleSIG = preferences.getActiveAppleSig() {
            apiManager.verifyApplePayment(appleID: appleID, appleData: appleData, appleSIG: appleSIG).subscribe(onSuccess: { _ in
                self.apiManager.getSession(nil).subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: self.dispose)
                self.logger.logI("InAppPurchaseManagerImpl", "Sending Apple purchase data successful.")
                // setting nil for successfull validation
                self.preferences.saveActiveAppleID(id: nil)
                self.preferences.saveActiveAppleSig(sig: nil)
                self.preferences.saveActiveAppleData(data: nil)
            }, onFailure: { error in
                if let error = error as? Errors {
                    self.logger.logE("InAppPurchaseManagerImpl", "\(error.description)")
                }
            }).disposed(by: dispose)
        }
    }

    func verifyPendingTransaction() async throws {
        guard let appleID = preferences.getActiveAppleID(),
              let appleData = preferences.getActiveAppleData(),
              let appleSIG = preferences.getActiveAppleSig() else {
            return
        }

        return try await withCheckedThrowingContinuation { continuation in
            apiManager.verifyApplePayment(appleID: appleID, appleData: appleData, appleSIG: appleSIG)
                .subscribe(
                    onSuccess: { _ in
                        self.apiManager.getSession(nil).subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: self.dispose)
                        self.logger.logI("InAppPurchaseManagerImpl", "Sending Apple purchase data successful.")

                        self.preferences.saveActiveAppleID(id: nil)
                        self.preferences.saveActiveAppleSig(sig: nil)
                        self.preferences.saveActiveAppleData(data: nil)

                        continuation.resume()
                    },
                    onFailure: { error in
                        if let error = error as? Errors {
                            self.logger.logE("InAppPurchaseManagerImpl", "\(error.description)")
                        }
                        continuation.resume(throwing: error)
                    }
                ).disposed(by: self.dispose)
        }
    }
}
