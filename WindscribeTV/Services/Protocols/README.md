# WindscribeTV/Services/Protocols/

Protocol-defined capability surfaces that tvOS Neo features depend on. Each
protocol is paired with a thin adapter that delegates to the existing
Swinject-resolved legacy implementation, so features never see Swinject and
the legacy graph stays unchanged.

The pattern mirrors [`Windscribe/Services/Protocols/`](../../../Windscribe/Services/Protocols/)
on iOS — see [`LookAndFeelObserving.swift`](../../../Windscribe/Services/Protocols/LookAndFeelObserving.swift)
for the canonical shape (protocol + `Sendable` adapter + `AsyncStream` over a
Combine subject at the boundary).

**Read first:** [`docs/PROJECT_NEO.md`](../../../docs/PROJECT_NEO.md).
