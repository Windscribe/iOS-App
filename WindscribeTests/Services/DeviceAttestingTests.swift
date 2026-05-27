//
//  DeviceAttestingTests.swift
//  WindscribeTests
//
//  Created by Anthony Wong on 2026-05-25.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Testing
import Foundation
@testable import Windscribe

@Suite("DeviceAttesting")
struct DeviceAttestingTests {

    // MARK: - Fake token generation

    @Test("generateToken returns the configured base64 string on success")
    func generateToken_returnsExpectedString() async throws {
        let fake = FakeDeviceAttesting(isSupported: true, result: .success("dGVzdA=="))
        let token = try await fake.generateToken()
        #expect(token == "dGVzdA==")
    }

    // MARK: - Unsupported device

    @Test("generateToken throws .unsupported when device is not supported")
    func generateToken_throwsUnsupported() async {
        let fake = FakeDeviceAttesting(isSupported: false, result: .failure(.unsupported))
        await #expect(throws: DeviceAttestationError.self) {
            _ = try await fake.generateToken()
        }
        do {
            _ = try await fake.generateToken()
            Issue.record("Expected DeviceAttestationError.unsupported to be thrown")
        } catch DeviceAttestationError.unsupported {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Generation failure

    @Test("generateToken propagates .generationFailed from underlying error")
    func generateToken_propagatesGenerationFailed() async {
        let underlying = NSError(domain: "test", code: 42)
        let fake = FakeDeviceAttesting(isSupported: true, result: .failure(.generationFailed(underlying)))
        do {
            _ = try await fake.generateToken()
            Issue.record("Expected DeviceAttestationError.generationFailed to be thrown")
        } catch DeviceAttestationError.generationFailed {
            // expected
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - Production wrapper smoke test (compile + link only)

    @Test("DCDeviceAttestation.isSupported is accessible (value is platform-dependent)")
    func dcDeviceAttestation_isSupportedAccessible() {
        let impl = DCDeviceAttestation()
        // We don't assert a specific value — simulators return false, devices return true.
        _ = impl.isSupported
    }
}

// MARK: - Fake

final class FakeDeviceAttesting: DeviceAttesting, @unchecked Sendable {
    let isSupported: Bool
    private let result: Result<String, DeviceAttestationError>

    init(isSupported: Bool, result: Result<String, DeviceAttestationError>) {
        self.isSupported = isSupported
        self.result = result
    }

    func generateToken() async throws -> String {
        switch result {
        case .success(let token):
            return token
        case .failure(let error):
            throw error
        }
    }
}
