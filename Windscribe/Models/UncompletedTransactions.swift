//
//  UncompletedTransactions.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit

struct UncompletedTransactions: CustomStringConvertible {
    private let date: Date?
    let transaction: SKPaymentTransaction
    private let productID: String
    let appleData: String
    let transactionID: String
    let signature: String

    init?(transaction: SKPaymentTransaction) {
        self.transaction = transaction
        if let appleData = transaction.appleData, let signature = transaction.signature, let id = transaction.transactionIdentifier {
            self.appleData = appleData
            self.signature = signature
            transactionID = id
            date = transaction.transactionDate
            productID = transaction.payment.productIdentifier
        } else {
            return nil
        }
    }

    var description: String {
        return "Transaction ID: \(transactionID) ProductID: \(productID) Date: \(String(describing: date)))"
    }
}
