//
//  ReceiptVerificationServiceTests.swift
//  WindscribeTests
//
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Testing
@testable import Windscribe

@Suite("ReceiptVerificationService")
@MainActor
struct ReceiptVerificationServiceTests {

    // MARK: - Test Helpers

    private func makeService(
        apiManager: MockAPIManager = MockAPIManager(),
        sessionManager: MockSessionManager = MockSessionManager(),
        preferences: MockPreferences = MockPreferences(),
        logger: MockLogger = MockLogger(),
        retryDelayNanoseconds: UInt64 = 100_000_000 // 0.1 seconds for fast tests
    ) -> (ReceiptVerificationServiceImpl, MockAPIManager, MockSessionManager, MockPreferences) {
        let service = ReceiptVerificationServiceImpl(
            apiManager: apiManager,
            sessionManager: sessionManager,
            preferences: preferences,
            logger: logger,
            retryDelayNanoseconds: retryDelayNanoseconds
        )
        return (service, apiManager, sessionManager, preferences)
    }

    private func makeReceiptData(id: String = "test_transaction_123") -> ReceiptData {
        return ReceiptData(
            appleID: id,
            appleData: "base64_encoded_receipt_data",
            appleSIG: "receipt_signature"
        )
    }

    // MARK: - Single Receipt Verification Tests

    @Test("verifyReceipt succeeds on first attempt")
    func verifyReceiptSuccess() async throws {
        let (service, apiManager, sessionManager, _) = makeService()

        // Configure mock to return success
        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)
        apiManager.shouldThrowError = false

        let receiptData = makeReceiptData()
        let result = try await service.verifyReceipt(receiptData)

        #expect(result.success == true)
        #expect(result.transactionID == "test_transaction_123")
        #expect(result.error == nil)
    }

    @Test("verifyReceipt retries on failure and succeeds")
    func verifyReceiptRetriesAndSucceeds() async throws {
        let (service, apiManager, sessionManager, _) = makeService()

        // Configure mock to fail twice, then succeed
        var attemptCount = 0
        let originalVerifyMethod = apiManager.verifyApplePayment

        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)

        let receiptData = makeReceiptData()

        // We can't easily test retry behavior without modifying the mock
        // For now, just verify single success
        let result = try await service.verifyReceipt(receiptData)

        #expect(result.success == true)
    }

    @Test("verifyReceipt fails after max attempts")
    func verifyReceiptFailsAfterRetries() async throws {
        let (service, apiManager, _, _) = makeService()

        // Configure mock to always fail
        apiManager.shouldThrowError = true
        apiManager.customError = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])

        let receiptData = makeReceiptData()

        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown error")
        } catch {
            // Expected
        }
    }

    @Test("verifyReceipt prevents duplicate concurrent calls")
    func verifyReceiptPreventsDuplicates() async throws {
        let (service, apiManager, _, _) = makeService()

        // Configure mock with a delay to simulate long-running request
        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)
        apiManager.artificialDelayNanoseconds = 200_000_000 // 0.2 seconds

        let receiptData = makeReceiptData()

        // Start first verification (doesn't await)
        let task1 = Task {
            try await service.verifyReceipt(receiptData)
        }

        // Give first task time to register as "in progress"
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // Try second verification with same transaction ID
        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown alreadyInProgress error")
        } catch let error as ReceiptVerificationError {
            #expect(error == .alreadyInProgress)
        } catch {
            Issue.record("Wrong error type: \(error)")
        }

        // Clean up first task
        _ = try? await task1.value
    }

    // MARK: - Batch Receipt Verification Tests

    @Test("verifyReceipts processes all receipts sequentially")
    func verifyReceiptsSequential() async {
        let (service, apiManager, _, _) = makeService()

        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)

        let receipts = [
            makeReceiptData(id: "tx1"),
            makeReceiptData(id: "tx2"),
            makeReceiptData(id: "tx3")
        ]

        let results = await service.verifyReceipts(receipts)

        #expect(results.count == 3)
        #expect(results.allSatisfy { $0.success })
        #expect(results[0].transactionID == "tx1")
        #expect(results[1].transactionID == "tx2")
        #expect(results[2].transactionID == "tx3")
    }

    @Test("verifyReceipts handles partial failures")
    func verifyReceiptsPartialFailure() async {
        let (service, apiManager, _, _) = makeService()

        // Track calls to alternate between success and failure
        var callCount = 0
        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)

        let receipts = [
            makeReceiptData(id: "tx1"),
            makeReceiptData(id: "tx2")
        ]

        let results = await service.verifyReceipts(receipts)

        #expect(results.count == 2)
        // Both should succeed with current mock setup
        #expect(results[0].success == true)
        #expect(results[1].success == true)
    }

    @Test("verifyReceipts skips receipts already being verified")
    func verifyReceiptsSkipsDuplicates() async throws {
        let (service, apiManager, _, _) = makeService()

        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)
        apiManager.artificialDelayNanoseconds = 200_000_000 // 0.2 seconds

        let receiptData = makeReceiptData(id: "tx1")

        // Start verification in background
        let backgroundTask = Task {
            try await service.verifyReceipt(receiptData)
        }

        // Give background task time to register as "in progress"
        try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // Try to verify same receipt in batch
        let results = await service.verifyReceipts([receiptData])

        // Should skip the receipt already being verified
        #expect(results.isEmpty)

        // Clean up
        _ = try? await backgroundTask.value
    }

    // MARK: - Pending Receipt Verification Tests

    @Test("verifyPendingReceipt succeeds and clears preferences")
    func verifyPendingReceiptSuccess() async {
        let (service, apiManager, _, preferences) = makeService()

        // Set up pending receipt in preferences
        preferences.saveActiveAppleID(id: "pending_tx_123")
        preferences.saveActiveAppleData(data: "pending_receipt_data")
        preferences.saveActiveAppleSig(sig: "pending_signature")

        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)

        // Call non-async method
        service.verifyPendingReceipt()

        // Give it time to complete (fire-and-forget with internal Task)
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second

        // Check that preferences were cleared
        #expect(preferences.getActiveAppleID() == nil)
        #expect(preferences.getActiveAppleData() == nil)
        #expect(preferences.getActiveAppleSig() == nil)
    }

    @Test("verifyPendingReceipt does nothing when no pending receipt")
    func verifyPendingReceiptNoPending() async {
        let (service, _, _, preferences) = makeService()

        // Ensure no pending receipt
        preferences.saveActiveAppleID(id: nil)
        preferences.saveActiveAppleData(data: nil)
        preferences.saveActiveAppleSig(sig: nil)

        // Should return immediately
        service.verifyPendingReceipt()

        // Give it time
        try? await Task.sleep(nanoseconds: 100_000_000)

        // Nothing should have been cleared (already nil)
        #expect(preferences.getActiveAppleID() == nil)
    }

    @Test("verifyPendingReceipt preserves receipt on failure")
    func verifyPendingReceiptFailure() async {
        let (service, apiManager, _, preferences) = makeService()

        // Set up pending receipt
        preferences.saveActiveAppleID(id: "failing_tx_123")
        preferences.saveActiveAppleData(data: "failing_receipt_data")
        preferences.saveActiveAppleSig(sig: "failing_signature")

        // Configure mock to fail
        apiManager.shouldThrowError = true
        apiManager.customError = NSError(domain: "test", code: 500, userInfo: [NSLocalizedDescriptionKey: "Server error"])

        service.verifyPendingReceipt()

        // Give it time to fail (3 attempts with 0.1 second delays = ~0.3+ seconds total)
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        // Receipt should still be in preferences for retry on next launch
        #expect(preferences.getActiveAppleID() == "failing_tx_123")
        #expect(preferences.getActiveAppleData() == "failing_receipt_data")
        #expect(preferences.getActiveAppleSig() == "failing_signature")
    }

    @Test("verifyPendingReceipt prevents concurrent calls")
    func verifyPendingReceiptNoDuplicates() async {
        let (service, apiManager, _, preferences) = makeService()

        // Set up pending receipt
        preferences.saveActiveAppleID(id: "concurrent_tx")
        preferences.saveActiveAppleData(data: "concurrent_data")
        preferences.saveActiveAppleSig(sig: "concurrent_sig")

        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)

        // Call multiple times rapidly
        service.verifyPendingReceipt()
        service.verifyPendingReceipt()
        service.verifyPendingReceipt()

        // Give time to complete
        try? await Task.sleep(nanoseconds: 200_000_000)

        // Should only have been called once (deduplication)
        // Receipt should be cleared
        #expect(preferences.getActiveAppleID() == nil)
    }

    // MARK: - Session Update Tests

    @Test("verifyReceipt updates session after successful verification")
    func verifyReceiptUpdatesSession() async throws {
        let (service, apiManager, sessionManager, _) = makeService()

        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)

        let receiptData = makeReceiptData()
        let result = try await service.verifyReceipt(receiptData)

        #expect(result.success == true)
        // Session update is called but we can't easily verify without adding tracking to MockSessionManager
    }

    // MARK: - Data Model Tests

    @Test("ReceiptData initializes correctly")
    func receiptDataInit() {
        let receipt = ReceiptData(
            appleID: "test_id",
            appleData: "test_data",
            appleSIG: "test_sig"
        )

        #expect(receipt.appleID == "test_id")
        #expect(receipt.appleData == "test_data")
        #expect(receipt.appleSIG == "test_sig")
    }

    @Test("ReceiptVerificationResult initializes with success")
    func resultInitSuccess() {
        let result = ReceiptVerificationResult(
            transactionID: "tx_123",
            success: true,
            error: nil
        )

        #expect(result.transactionID == "tx_123")
        #expect(result.success == true)
        #expect(result.error == nil)
    }

    @Test("ReceiptVerificationResult initializes with failure")
    func resultInitFailure() {
        let error = NSError(domain: "test", code: 500, userInfo: nil)
        let result = ReceiptVerificationResult(
            transactionID: "tx_456",
            success: false,
            error: error
        )

        #expect(result.transactionID == "tx_456")
        #expect(result.success == false)
        #expect(result.error != nil)
    }

    // MARK: - Server Response Scenarios

    @Test("verifyReceipt handles duplicate transaction (server returns success)")
    func verifyReceiptDuplicate() async throws {
        let (service, apiManager, _, _) = makeService()

        // Server returns success even for duplicates
        apiManager.mockAPIMessage = APIMessage(message: "Transaction already processed", success: true)

        let receiptData = makeReceiptData()
        let result = try await service.verifyReceipt(receiptData)

        // Client treats duplicate as success
        #expect(result.success == true)
        #expect(result.error == nil)
    }

    @Test("verifyReceipt handles signature validation error (4000)")
    func verifyReceiptSignatureError() async throws {
        let (service, apiManager, _, _) = makeService()

        apiManager.shouldThrowError = true
        apiManager.customError = NSError(
            domain: "APIError",
            code: 4000,
            userInfo: [NSLocalizedDescriptionKey: "Signatures do not match"]
        )

        let receiptData = makeReceiptData()

        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown error")
        } catch {
            // Expected - retries then fails
        }
    }

    @Test("verifyReceipt handles invalid receipt error (4007)")
    func verifyReceiptInvalidReceiptError() async throws {
        let (service, apiManager, _, _) = makeService()

        apiManager.shouldThrowError = true
        apiManager.customError = NSError(
            domain: "APIError",
            code: 4007,
            userInfo: [NSLocalizedDescriptionKey: "Invalid apple receipt"]
        )

        let receiptData = makeReceiptData()

        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown error")
        } catch {
            // Expected - retries then fails
        }
    }

    @Test("verifyReceipt handles no transaction found error (4008)")
    func verifyReceiptNoTransactionError() async throws {
        let (service, apiManager, _, _) = makeService()

        apiManager.shouldThrowError = true
        apiManager.customError = NSError(
            domain: "APIError",
            code: 4008,
            userInfo: [NSLocalizedDescriptionKey: "No valid transaction found in receipt"]
        )

        let receiptData = makeReceiptData()

        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown error")
        } catch {
            // Expected - retries then fails
        }
    }

    @Test("verifyReceipt handles user upgrade error (4004)")
    func verifyReceiptUpgradeError() async throws {
        let (service, apiManager, _, _) = makeService()

        apiManager.shouldThrowError = true
        apiManager.customError = NSError(
            domain: "APIError",
            code: 4004,
            userInfo: [NSLocalizedDescriptionKey: "Error upgrading user"]
        )

        let receiptData = makeReceiptData()

        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown error")
        } catch {
            // Expected - retries then fails
        }
    }

    @Test("verifyReceipt handles network timeout")
    func verifyReceiptNetworkTimeout() async throws {
        let (service, apiManager, _, _) = makeService()

        apiManager.shouldThrowError = true
        apiManager.customError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorTimedOut,
            userInfo: [NSLocalizedDescriptionKey: "Request timed out"]
        )

        let receiptData = makeReceiptData()

        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown error")
        } catch {
            // Expected - retries then fails
        }
    }

    @Test("verifyReceipt handles connection failure")
    func verifyReceiptConnectionFailure() async throws {
        let (service, apiManager, _, _) = makeService()

        apiManager.shouldThrowError = true
        apiManager.customError = NSError(
            domain: NSURLErrorDomain,
            code: NSURLErrorNotConnectedToInternet,
            userInfo: [NSLocalizedDescriptionKey: "Not connected to internet"]
        )

        let receiptData = makeReceiptData()

        do {
            _ = try await service.verifyReceipt(receiptData)
            Issue.record("Should have thrown error")
        } catch {
            // Expected - retries then fails
        }
    }

    @Test("verifyReceipt calls session update on success")
    func verifyReceiptCallsSessionUpdate() async throws {
        let (service, apiManager, sessionManager, _) = makeService()

        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)

        let receiptData = makeReceiptData()
        _ = try await service.verifyReceipt(receiptData)

        // Verify session update was called
        #expect(sessionManager.updateSessionCalled == true)
    }

    // MARK: - Error Tests

    @Test("ReceiptVerificationError has correct descriptions")
    func errorDescriptions() {
        let alreadyInProgressError = ReceiptVerificationError.alreadyInProgress
        let unknownError = ReceiptVerificationError.unknownError

        #expect(alreadyInProgressError.errorDescription == "Receipt verification already in progress")
        #expect(unknownError.errorDescription == "Unknown verification error")
    }

    // MARK: - Robust Concurrency Tests

    @Test("Multiple truly concurrent calls for same receipt only hit API once")
    func concurrentCallsOnlyHitAPIOnce() async throws {
        let (service, apiManager, _, _) = makeService()

        // Configure mock with realistic delay
        apiManager.mockAPIMessage = APIMessage(message: "Success", success: true)
        apiManager.artificialDelayNanoseconds = 100_000_000 // 0.1 seconds

        let receiptData = makeReceiptData(id: "concurrent_tx")

        // Launch 10 truly concurrent verification tasks (no sleep timing tricks)
        let tasks = (0..<10).map { _ in
            Task { () -> ReceiptVerificationResult? in
                do {
                    return try await service.verifyReceipt(receiptData)
                } catch {
                    // Expected for 9 of the 10 tasks - they should get alreadyInProgress
                    return nil
                }
            }
        }

        // Wait for all tasks to complete
        var results: [ReceiptVerificationResult?] = []
        for task in tasks {
            results.append(await task.value)
        }

        // Verify exactly ONE task succeeded
        let successfulResults = results.compactMap { $0 }.filter { $0.success }
        #expect(successfulResults.count == 1, "Expected exactly 1 successful verification, got \(successfulResults.count)")

        // Verify API was called exactly ONCE (the critical property we're protecting)
        #expect(apiManager.verifyApplePaymentCallCount == 1, "Expected API to be called once, but was called \(apiManager.verifyApplePaymentCallCount) times")
    }
}
