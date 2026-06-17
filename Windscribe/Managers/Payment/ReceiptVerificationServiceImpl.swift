//
//  ReceiptVerificationServiceImpl.swift
//  Windscribe
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation

/// Implementation of receipt verification service with deduplication and sequential processing
final class ReceiptVerificationServiceImpl: ReceiptVerificationService {

    // MARK: - Dependencies

    private let apiManager: APIManager
    private let sessionManager: SessionManager
    private let preferences: Preferences
    private let logger: FileLogger

    // MARK: - Configuration

    private let retryDelayNanoseconds: UInt64

    // MARK: - State

    private let verificationActor = VerificationActor()

    // MARK: - Initialization

    init(
        apiManager: APIManager,
        sessionManager: SessionManager,
        preferences: Preferences,
        logger: FileLogger,
        retryDelayNanoseconds: UInt64 = 5_000_000_000 // 5 seconds default
    ) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
        self.preferences = preferences
        self.logger = logger
        self.retryDelayNanoseconds = retryDelayNanoseconds
    }

    // MARK: - ReceiptVerificationService

    func verifyReceipt(_ receiptData: ReceiptData) async throws -> ReceiptVerificationResult {
        // Atomically check and start verification
        guard await verificationActor.tryStartVerification(transactionID: receiptData.appleID) else {
            logger.logD("ReceiptVerificationService", "Verification already in progress for transaction \(receiptData.appleID)")
            throw ReceiptVerificationError.alreadyInProgress
        }

        do {
            let result = try await performVerification(receiptData: receiptData, maxAttempts: 3, throwOnFailure: true)
            await verificationActor.endVerification(transactionID: receiptData.appleID)
            return result
        } catch {
            await verificationActor.endVerification(transactionID: receiptData.appleID)
            throw error
        }
    }

    func verifyReceipts(_ receipts: [ReceiptData]) async -> [ReceiptVerificationResult] {
        logger.logD("ReceiptVerificationService", "Verifying \(receipts.count) receipts sequentially")

        var results: [ReceiptVerificationResult] = []

        for receiptData in receipts {
            // Atomically check and start verification
            guard await verificationActor.tryStartVerification(transactionID: receiptData.appleID) else {
                logger.logD("ReceiptVerificationService", "Skipping transaction \(receiptData.appleID) - already in progress")
                continue
            }

            let result: ReceiptVerificationResult
            do {
                result = try await performVerification(
                    receiptData: receiptData,
                    maxAttempts: 1, // For batch operations, don't retry - user can manually retry
                    throwOnFailure: false // Return results, don't throw
                )
            } catch {
                // Should not happen since throwOnFailure is false, but handle just in case
                result = ReceiptVerificationResult(
                    transactionID: receiptData.appleID,
                    success: false,
                    error: error
                )
            }

            results.append(result)
            await verificationActor.endVerification(transactionID: receiptData.appleID)
        }

        logger.logD("ReceiptVerificationService", "Verified \(results.filter { $0.success }.count)/\(receipts.count) receipts successfully")

        return results
    }

    func verifyPendingReceipt() {
        Task {
            // Check if there's a pending receipt
            guard let appleID = preferences.getActiveAppleID(),
                  let appleData = preferences.getActiveAppleData(),
                  let appleSIG = preferences.getActiveAppleSig() else {
                logger.logD("ReceiptVerificationService", "No pending receipt to verify")
                return
            }

            // Atomically check and start pending verification
            guard await verificationActor.tryStartPendingVerification() else {
                logger.logD("ReceiptVerificationService", "Pending receipt verification already in progress")
                return
            }

            logger.logI("ReceiptVerificationService", "Verifying pending receipt for transaction \(appleID)")

            let receiptData = ReceiptData(appleID: appleID, appleData: appleData, appleSIG: appleSIG)

            do {
                let result = try await performVerification(receiptData: receiptData, maxAttempts: 3, throwOnFailure: false)

                if result.success {
                    // Clear pending receipt on success
                    preferences.saveActiveAppleID(id: nil)
                    preferences.saveActiveAppleSig(sig: nil)
                    preferences.saveActiveAppleData(data: nil)
                    logger.logI("ReceiptVerificationService", "Pending receipt verified and cleared")
                } else {
                    logger.logE("ReceiptVerificationService", "Failed to verify pending receipt: \(result.error?.localizedDescription ?? "unknown error")")
                }
                await verificationActor.endPendingVerification()
            } catch {
                // Should not happen since throwOnFailure is false, but handle just in case
                logger.logE("ReceiptVerificationService", "Unexpected error verifying pending receipt: \(error.localizedDescription)")
                await verificationActor.endPendingVerification()
            }
        }
    }

    // MARK: - Private Helpers

    private func performVerification(
        receiptData: ReceiptData,
        maxAttempts: Int,
        throwOnFailure: Bool
    ) async throws -> ReceiptVerificationResult {
        var lastError: Error?

        for attempt in 0..<maxAttempts {
            do {
                _ = try await apiManager.verifyApplePayment(
                    appleID: receiptData.appleID,
                    appleData: receiptData.appleData,
                    appleSIG: receiptData.appleSIG
                )

                // Update session after successful verification
                try? await sessionManager.updateSession()

                logger.logI("ReceiptVerificationService", "Successfully verified transaction \(receiptData.appleID) on attempt \(attempt + 1)")

                return ReceiptVerificationResult(
                    transactionID: receiptData.appleID,
                    success: true,
                    error: nil
                )

            } catch {
                lastError = error
                logger.logE("ReceiptVerificationService", "Verification attempt \(attempt + 1) failed for \(receiptData.appleID): \(error)")

                // If not last attempt, wait before retrying
                if attempt < maxAttempts - 1 {
                    let delaySeconds = Double(retryDelayNanoseconds) / 1_000_000_000
                    logger.logD("ReceiptVerificationService", "Retrying in \(Int(delaySeconds)) seconds...")
                    try? await Task.sleep(nanoseconds: retryDelayNanoseconds)
                }
            }
        }

        // All attempts exhausted
        if throwOnFailure {
            throw lastError ?? ReceiptVerificationError.unknownError
        } else {
            return ReceiptVerificationResult(
                transactionID: receiptData.appleID,
                success: false,
                error: lastError
            )
        }
    }
}

// MARK: - Verification Actor

/// Actor to ensure thread-safe access to verification state
private actor VerificationActor {
    private var activeVerifications: Set<String> = []
    private var isPendingVerificationActive = false

    /// Atomically check if verification can start and mark it as started
    /// - Returns: true if verification was started, false if already in progress
    func tryStartVerification(transactionID: String) -> Bool {
        guard !activeVerifications.contains(transactionID) else {
            return false
        }
        activeVerifications.insert(transactionID)
        return true
    }

    func endVerification(transactionID: String) {
        activeVerifications.remove(transactionID)
    }

    /// Atomically check if pending verification can start and mark it as started
    /// - Returns: true if verification was started, false if already in progress
    func tryStartPendingVerification() -> Bool {
        guard !isPendingVerificationActive else {
            return false
        }
        isPendingVerificationActive = true
        return true
    }

    func endPendingVerification() {
        isPendingVerificationActive = false
    }
}

// MARK: - Errors

enum ReceiptVerificationError: Error, LocalizedError {
    case alreadyInProgress
    case unknownError

    var errorDescription: String? {
        switch self {
        case .alreadyInProgress:
            return "Receipt verification already in progress"
        case .unknownError:
            return "Unknown verification error"
        }
    }
}
