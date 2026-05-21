//
//  LookAndFeelObserving.swift
//  Windscribe
//
//  Created by Anthony Wong on 2026-04-30.
//  Copyright © 2026 Windscribe. All rights reserved.
//

import Foundation
@preconcurrency import Combine

/// Observes app-wide look-and-feel state. The Neo-side surface used by feature
/// modules; back this with a thin adapter over the legacy
/// `LookAndFeelRepositoryType` until that repository itself migrates.
///
/// Crosses isolation boundaries (consumed by `@MainActor` view models, fed by
/// non-isolated Combine subjects), so it's `Sendable`.
protocol LookAndFeelObserving: Sendable {
    /// Synchronous snapshot of the current dark-mode state. Useful for
    /// initialising view state without waiting for the first stream emission.
    var isDarkMode: Bool { get }

    /// Async stream of dark-mode updates. The first value emitted is the
    /// current value, so callers can drive UI directly off this stream.
    var darkModeUpdates: AsyncStream<Bool> { get }
}

/// Adapter that wraps the legacy `LookAndFeelRepositoryType` (Combine-based,
/// pre-Sendable) and exposes the Neo `LookAndFeelObserving` surface.
///
/// Lives at the Neo composition seam: created in
/// `Windscribe/App/Environment+Dependencies.swift`, never inside a feature module.
final class LegacyLookAndFeelObserver: LookAndFeelObserving, Sendable {
    private let repository: LookAndFeelRepositoryType

    init(repository: LookAndFeelRepositoryType) {
        self.repository = repository
    }

    var isDarkMode: Bool { repository.isDarkMode }

    var darkModeUpdates: AsyncStream<Bool> {
        let subject = repository.isDarkModeSubject
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
