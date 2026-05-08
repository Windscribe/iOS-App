//
//  SessionProviding.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-05-06.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
import Combine

/// Read access to the active user session. Backed by a thin adapter over
/// the legacy `UserSessionRepository`.
///
/// **Scope note:** session mutation, sync, and pro-location access checks
/// stay on the legacy interface for now. Add to this protocol when a Neo
/// feature genuinely needs them.
protocol SessionProviding: Sendable {
    /// Synchronous snapshot of the current session, or nil if logged out.
    var session: SessionModel? { get }

    /// Async stream of session updates. The first value emitted is the
    /// current value, so callers can drive UI directly off this stream.
    var sessionUpdates: AsyncStream<SessionModel?> { get }
}

/// Adapter wrapping the legacy `UserSessionRepository`.
final class LegacySessionProvider: SessionProviding, Sendable {
    private let legacy: UserSessionRepository

    init(legacy: UserSessionRepository) {
        self.legacy = legacy
    }

    var session: SessionModel? { legacy.sessionModel }

    var sessionUpdates: AsyncStream<SessionModel?> {
        let subject = legacy.sessionModelSubject
        return AsyncStream { continuation in
            let cancellable = subject.sink { value in
                continuation.yield(value)
            }
            continuation.onTermination = { _ in
                cancellable.cancel()
            }
        }
    }
}
