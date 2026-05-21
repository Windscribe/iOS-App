//
//  MockPatternTests.swift
//  WindscribeTests
//
//  Created by Anthony Wong on 2026-05-11.
//  Copyright © 2026 Windscribe. All rights reserved.
//
//  Worked examples for the two Neo mock patterns documented in
//  `docs/PROJECT_NEO.md`. See "## Testing mocks" for the rationale.
//
//  Pattern 1 — struct mock with stored callbacks:
//    See the per-feature mocks in WindscribeTests/Features/* (e.g.
//    StubPreferencesReading in GeneralTests.swift).
//
//  Pattern 2 — actor mock for state:
//    ActorMockCredentialStoring below is the canonical in-tree example.
//    Use this shape when a mock must track mutable state (call counts,
//    captured arguments) across concurrent callers without @unchecked Sendable.
//

import Testing
import Foundation
@testable import Windscribe

// MARK: - Pattern 2: Actor mock for state

/// `CredentialStoring` mock implemented as an `actor`.
/// Eliminates `@unchecked Sendable` — the actor serialises all accesses.
/// Use this shape when the mock must record mutable state (call log,
/// captured arguments) that would otherwise require manual locking.
actor ActorMockCredentialStoring: CredentialStoring {
    // `CredentialStoring` requires synchronous nonisolated getters here.
    // Declaring these `let` makes them implicitly nonisolated on the actor.
    let openVPNCredentials: ServerCredentialsModel?
    let ikev2Credentials: ServerCredentialsModel?

    // Mutable state stays actor-isolated — that's the whole point of the actor.
    private(set) var refreshCallCount = 0

    init(
        openVPN: ServerCredentialsModel? = nil,
        ikev2: ServerCredentialsModel? = nil
    ) {
        self.openVPNCredentials = openVPN
        self.ikev2Credentials = ikev2
    }

    func refreshOpenVPNCredentials() async throws { refreshCallCount += 1 }
    func refreshIKEv2Credentials() async throws { refreshCallCount += 1 }
}

// MARK: - Tests

@Suite("Mock pattern: actor mock for state")
struct ActorMockPatternTests {

    @Test("Actor mock records refresh calls without data races")
    func actorMock_recordsRefreshCalls() async throws {
        let mock = ActorMockCredentialStoring(
            openVPN: ServerCredentialsModel(username: "u", password: "p")
        )
        try await mock.refreshOpenVPNCredentials()
        try await mock.refreshIKEv2Credentials()
        let count = await mock.refreshCallCount
        #expect(count == 2)
    }
}
