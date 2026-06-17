//
//  ReceiptVerificationService.swift
//  Windscribe

//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Represents Apple receipt data for server verification
struct ReceiptData {
    /// Apple transaction identifier
    let appleID: String

    /// Base64-encoded receipt data
    let appleData: String

    /// Receipt signature
    let appleSIG: String
}

/// Result of a receipt verification attempt
struct ReceiptVerificationResult {
    let transactionID: String
    let success: Bool
    let error: Error?
}

/// Service responsible for verifying receipts with the server
/// Ensures deduplication and sequential processing of verification requests
protocol ReceiptVerificationService {
    /// Verify a single receipt with the server
    /// - Parameter receiptData: Receipt data containing transaction ID, data, and signature
    /// - Returns: Verification result
    func verifyReceipt(_ receiptData: ReceiptData) async throws -> ReceiptVerificationResult

    /// Verify multiple receipts sequentially
    /// - Parameter receipts: Array of receipt data
    /// - Returns: Array of verification results
    func verifyReceipts(_ receipts: [ReceiptData]) async -> [ReceiptVerificationResult]

    /// Verify pending receipt stored in preferences (if any)
    /// Returns immediately and performs verification in the background
    /// Automatically deduplicates - multiple calls while verification is in progress are ignored
    func verifyPendingReceipt()
}
