//
//  InAppPurchaseManager.swift
//  Windscribe
//
//  Created by Ginder Singh on 2024-01-11.
//  Copyright © 2024 Windscribe. All rights reserved.
//

import Foundation
import StoreKit
import Combine

// MARK: - Modern State Types

enum IAPPurchaseState: Equatable {
    case idle
    case purchasing
    case success(transaction: SKPaymentTransaction)
    case failed(error: Error)

    static func == (lhs: IAPPurchaseState, rhs: IAPPurchaseState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.purchasing, .purchasing):
            return true
        case (.success(let lhsTransaction), .success(let rhsTransaction)):
            return lhsTransaction.transactionIdentifier == rhsTransaction.transactionIdentifier
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

enum IAPRestoreState: Equatable {
    case idle
    case restoring
    case success
    case failed(error: Error)

    static func == (lhs: IAPRestoreState, rhs: IAPRestoreState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.restoring, .restoring), (.success, .success):
            return true
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

enum IAPProductsState: Equatable {
    case idle
    case loading
    case loaded([WindscribeInAppProduct])
    case failed(error: Error)

    static func == (lhs: IAPProductsState, rhs: IAPProductsState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loading, .loading):
            return true
        case (.loaded(let lhsProducts), .loaded(let rhsProducts)):
            return lhsProducts.count == rhsProducts.count
        case (.failed(let lhsError), .failed(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

enum InAppPurchaseError: Error, LocalizedError {
    case cannotMakePurchases
    case noProductsAvailable
    case transactionFailed(String)
    case restoreFailed(String)
    case productsFetchFailed(String)

    var errorDescription: String? {
        switch self {
        case .cannotMakePurchases:
            return "Cannot make purchases on this device"
        case .noProductsAvailable:
            return "No products available for purchase"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        case .restoreFailed(let message):
            return "Restore failed: \(message)"
        case .productsFetchFailed(let message):
            return "Failed to fetch products: \(message)"
        }
    }
}

// MARK: - Purchase Result

enum PurchaseResult {
    case success(transaction: SKPaymentTransaction, appleID: String, appleData: String, signature: String)
    case cancelled
    case failed(Error)
}

// MARK: - Legacy Protocol (for backward compatibility)

protocol InAppPurchaseManager {
    func canMakePurchases() -> Bool
    func purchase(windscribeInAppProduct: WindscribeInAppProduct)
    func restorePurchase()
    func fetchAvailableProducts(productIDs: [String])
    func matchInAppPurchaseWithWindscribeData(transaction: SKPaymentTransaction)
    func verifyPendingTransaction()
    var delegate: InAppPurchaseManagerDelegate? { get set }
}

// MARK: - Modern Protocol (SwiftUI + Combine + async/await)

protocol ModernInAppPurchaseManager {
    var purchaseState: AnyPublisher<IAPPurchaseState, Never> { get }
    var restoreState: AnyPublisher<IAPRestoreState, Never> { get }
    var availableProducts: AnyPublisher<IAPProductsState, Never> { get }

    func canMakePurchases() -> Bool
    func purchase(windscribeInAppProduct: WindscribeInAppProduct) async throws -> PurchaseResult
    func restorePurchases() async throws
    func fetchAvailableProducts(productIDs: [String]) async throws -> [WindscribeInAppProduct]
    func verifyPendingTransaction() async throws
}
