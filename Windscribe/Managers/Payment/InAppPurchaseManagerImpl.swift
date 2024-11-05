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

class InAppPurchaseManagerImpl: NSObject, InAppPurchaseManager {
    // MARK: properties

    weak var delegate: InAppPurchaseManagerDelegate?
    fileprivate var productsRequest = SKProductsRequest()
    var iapProducts = [WindscribeInAppProduct]()
    var isComingFromRestore: Bool = false
    var hasAddObserver: Bool = false
    var uncompletedTransactions: [UncompletedTransactions] = []
    let dispose = DisposeBag()

    // MARK: dependecies

    let apiManager: APIManager
    let preferences: Preferences
    let logger: FileLogger
    let localDatabase: LocalDatabase

    init(apiManager: APIManager, preferences: Preferences, logger: FileLogger, localDatabase: LocalDatabase) {
        self.apiManager = apiManager
        self.preferences = preferences
        self.localDatabase = localDatabase
        self.logger = logger
    }

    // MARK: Utility functions

    func canMakePurchases() -> Bool {
        return SKPaymentQueue.canMakePayments()
    }

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
        logger.logD(self, "Requesting completed transactions to be added to the queue.")
        SKPaymentQueue.default().restoreCompletedTransactions()
    }

    func fetchAvailableProducts(productIDs: [String]) {
        let productIdentifiers = Set(productIDs)
        productsRequest = SKProductsRequest(productIdentifiers: productIdentifiers)
        productsRequest.delegate = self
        productsRequest.start()
    }

    func matchInAppPurchaseWithWindscribeData(transaction: SKPaymentTransaction) {
        if let appleData = transaction.appleData,
           let transactionID = transaction.transactionIdentifier,
           let signature = transaction.signature
        {
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
           let appleSIG = preferences.getActiveAppleSig()
        {
            apiManager.verifyApplePayment(appleID: appleID, appleData: appleData, appleSIG: appleSIG).subscribe(onSuccess: { _ in
                self.apiManager.getSession(nil).subscribe(onSuccess: { _ in }, onFailure: { _ in }).disposed(by: self.dispose)
                self.logger.logD(self, "Sending Apple purchase data successful.")
                // setting nil for successfull validation
                self.preferences.saveActiveAppleID(id: nil)
                self.preferences.saveActiveAppleSig(sig: nil)
                self.preferences.saveActiveAppleData(data: nil)
            }, onFailure: { error in
                if let error = error as? Errors {
                    self.logger.logE(self, "\(error.description)")
                }
            }).disposed(by: dispose)
        }
    }
}
