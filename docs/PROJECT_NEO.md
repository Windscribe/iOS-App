# Project Neo — Contributor & AI Agent Rule Sheet

> **You are reading the entry point.** If you're picking up Project Neo work — human or AI — read this first. Then read [`docs/neo/DECISIONS.md`](neo/DECISIONS.md), then [`docs/neo/STATE.md`](neo/STATE.md), then the relevant issue plan in [`docs/neo/plans/`](neo/plans/).

## What Project Neo is

Project Neo is the Windscribe iOS/tvOS modernization effort that ships as **version 5.0**.

**End state:**

- iOS 18 + tvOS 18 minimum deployment target.
- SwiftUI-only UI, with `@Observable` view models.
- `async/await` + `AsyncStream` everywhere new code touches concurrency.
- Constructor injection + SwiftUI `@Environment(@Entry)` for DI. Swinject retired.
- GRDB-backed persistence. Realm retired.
- Combine and SnapKit retired. RxSwift already gone.
- Swift 6 language mode across all targets, reached module-by-module.

The full per-issue roadmap lives in [`docs/neo/plans/00-roadmap.md`](neo/plans/00-roadmap.md). This doc is the rule sheet.

## How Project Neo lands

There are **two branches in play** during the v5.0 cycle:

- **`main`** — keeps shipping non-Neo fixes and minor features to current-floor users (iOS 15+). It must stay launchable at all times.
- **`neo-5.0`** — the v5.0 integration branch.

Every Neo PR is one of two flavors:

| Flavor | Where it opens | Why |
|---|---|---|
| **Main-safe** | PR against `main`; flows to `neo-5.0` via the periodic merge | Purely additive (new files, new lint rules scoped to new paths, new docs), pure behavior-preserving refactors, or new code gated with `@available(iOS 17.0, *)` so legacy users still get the legacy path |
| **`neo-5.0`-only** | PR against `neo-5.0` directly | Anything that lifts the deployment target, deletes legacy `#available` branches, removes targets/extensions current users still rely on, or otherwise commits the codebase to an iOS 18 / tvOS 18 floor |

**Never merge `neo-5.0 → main` until v5.0 ships.** `main → neo-5.0` runs at least weekly and after any non-trivial PR lands on `main`.

If you're unsure which flavor your PR is, default to "main-safe" and ask. The cost of asking is much lower than the cost of accidentally bricking a release-from-`main`.

## Non-negotiable rules for new code

Below applies to any code under `Windscribe/Features/**` and `WindscribeTV/Features/**`. SwiftLint custom rules enforce most of these — your PR will fail lint if you break them.

1. **No `import RxSwift`.** Already removed. Do not reintroduce.
2. **No `import Combine`.** Convert at Apple-API boundaries with `.values` to `AsyncSequence`.
3. **No new Swinject registrations.** Use constructor injection + `@Environment(@Entry)`-injected protocols.
4. **No `ObservableObject` / `@Published` / `@StateObject` / `@ObservedObject`.** Use `@Observable` + `@State` + `@Bindable`.
5. **No new UIKit screens.** SwiftUI first. UIKit wrapping only with a justification comment.
6. **No new Realm `Object` subclasses.** Persistence goes through a protocol-defined store; back it with GRDB.
7. **One tunnel configuration path.** Don't add `#available(iOS 16, *)` guards in new tunnel code.
8. **View models don't import SwiftUI.** They're plain Swift, `@MainActor` annotated, testable without a UI.
9. **No `static let shared` for services.** App-wide deps flow through the environment.
10. **All service dependencies are protocols.** No concrete types in view model constructors.
11. **Typed errors per domain.** No bare `Error` / `NSError` in new public APIs.

When editing legacy code, **match the surrounding style.** Don't rewrite a UIKit controller to SwiftUI mid-feature unless that rewrite *is* the task.

### Converting Combine to AsyncSequence

Neo features must not `import Combine`. The boundary adapters in `Windscribe/Services/Protocols/` and `Windscribe/API/WSNet Protocol/` are the only place Combine is allowed; everywhere else, work in `async/await` and `AsyncSequence`.

There are two flavors of conversion, depending on what's on the legacy side:

**One-shot value (Combine `Future` / completion handler) → `async`:** wrap with `withCheckedThrowingContinuation`. Existing example: `WSNetBridgeAPIType.rotateIp()` in [`Windscribe/API/WSNet Protocol/WSNetBridgeAPIType.swift`](../Windscribe/API/WSNet Protocol/WSNetBridgeAPIType.swift) wraps a `WSNetCancelableCallback`-style call into an `async throws -> (Int32, String)`.

**Stream of values (Combine subject / `NotificationCenter`) → `AsyncStream`:** wrap with `AsyncStream { continuation in … }` and bridge each emitted value into the continuation. The canonical worked example is `LegacyLookAndFeelObserver` in [`Windscribe/Services/Protocols/LookAndFeelObserving.swift`](../Windscribe/Services/Protocols/LookAndFeelObserving.swift) — a `CurrentValueSubject` becomes an `AsyncStream<Theme>` that yields the current value first, then each subsequent emission. M3's `LegacyServerProvider` and `LegacySessionProvider` follow the same shape for `[LocationModel]` and `SessionModel?`.

The rules:

- **Never `import Combine` inside a Feature.** If a Feature seems to need it, the protocol surface is wrong — extend the protocol with an `AsyncStream` accessor at the boundary instead.
- **`AsyncStream` is the contract surface; the legacy subscription is hidden.** Adapters retain the Combine subscription (`AnyCancellable`) for the stream's lifetime via the continuation's `onTermination` handler — don't leak it into the protocol.
- **`.values` is fine for one-off Apple-API conversions** (e.g. `NotificationCenter.default.notifications(named: …)`) where you don't own the publisher. Use `AsyncStream { … }` when you're wrapping legacy code we control — it's clearer about the seam and easier to test.
- **Drop the first value if the consumer already has it.** A `CurrentValueSubject`-backed stream yields the seed value first; consumers that already read the synchronous accessor (`var locations: [LocationModel]`) typically want updates only. Drop in the consumer with `.dropFirst()` rather than baking the policy into the adapter.

## Adding a new feature

The shape every Neo feature follows:

```
Route (Hashable enum case, in the flow's NavigationStack root)
  ⇄  Screen (SwiftUI, @available(iOS 17.0, *), reads @Environment, constructs the VM)
    ⇄  View (SwiftUI, owns the VM as @State, renders the UI)
      ⇄  ViewModel (@Observable, @MainActor, no SwiftUI imports)
        ⇄  Service protocol (Sendable, in Windscribe/Services/Protocols/)
          ⇄  Implementation (real impl + adapter to legacy Swinject services where applicable)
```

The canonical reference is **`Windscribe/Features/About/`** (lands as part of M0; see ND-005). Copy that module, change names. If you need to make architectural decisions to do so, that's a signal the reference needs refining — flag it on the M0 issue rather than diverging.

Tests live in `WindscribeTests/Features/<FeatureName>Tests.swift` using the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`). Each test injects mock service implementations directly into the VM constructor. No DI container needed.

## Protocol naming

| Kind | Suffix | When | Examples |
|---|---|---|---|
| Capability protocol | `*ing` (verb-of-action) | A Neo protocol that names what something *does*. Single responsibility, lives in `Services/Protocols/`, consumed by feature view models via `@Environment(@Entry)`. | `VPNConnecting`, `ServerProviding`, `CredentialStoring`, `PreferencesReading`, `LookAndFeelObserving` |
| Legacy bridge mirror | `*Type` | A Swift protocol that mirrors the surface of a generated Obj-C class so it's mockable in tests. Reserved for bridges over types we don't own (WSNet xcframework, Apple frameworks where the underlying class is final/extension-hostile). | `WSNetServerAPIType`, `WSNetBridgeAPIType`, `WSNetPingManagerType` |

The split makes the seam visible: `*ing` reads as a Neo capability you can write a fresh impl for; `*Type` reads as a thin protocol-shaped slice through a fixed underlying type. Don't use `*Type` for new Neo capability protocols — `VPNConnectingType` is wrong. Don't use `*ing` for legacy bridge mirrors — `WSNetServerCalling` reads forced for a 40-method API surface.

## Routing

Neo navigation is value-based, on top of `NavigationStack` + `NavigationPath`. There's no `UINavigationController`, no router class that owns navigation state — flows are described as data, resolved to views by a pure function.

### Three-name convention

| Type     | Suffix      | Role                                                                 |
|----------|-------------|----------------------------------------------------------------------|
| Screen   | `*Screen`   | Top-level navigation destination. Reads `@Environment`, constructs the view model, hands it to the inner View. |
| View     | `*View`     | The actual rendering surface. Takes the VM via init, owns it as `@State`. Composes freely from smaller `*View` building blocks. |
| Route    | `*Route`    | `Hashable` enum of navigable destinations within a single flow. Cases name screens. |

Calling the env-reading DI hub a Screen reads honestly: the outer type IS what gets routed to, not just another view. Inner Views are just views.

### How a flow wires up

A flow's root owns a `NavigationStack` bound to a `NavigationPath`, and resolves its `Route` enum to a `Screen` via `.navigationDestination(for: SomeRoute.self) { route in … }`. That switch is the entire router — value in, view out, no state.

```swift
enum PreferencesRoute: Hashable {
    case about
    case general
}

struct PreferencesScreen: View {
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            PreferencesMenuView(path: $path)
                .navigationDestination(for: PreferencesRoute.self) { route in
                    switch route {
                    case .about:   AboutScreen()
                    case .general: GeneralScreen()
                    }
                }
        }
    }
}
```

### Why the Screen/View split exists

The Screen is the only place that can read `@Environment` and pass values into the VM's `init`. SwiftUI's `@State` doesn't expose env values to its default initializer, so the construction has to happen one view up — the Screen reads, the View owns the resulting `@State` via `init(initialValue:)`, and SwiftUI's "first init wins" semantics ensure the VM is retained across re-renders. See `Windscribe/Features/About/AboutScreen.swift` for the canonical shape.

### From legacy `Router`

`Router/NavigationRouter/BaseNavigationRouter` is a UIKit ⇄ SwiftUI bridge. As each flow goes Neo, it stops needing the bridge — the flow's root becomes a `NavigationStack`, its destinations become Screens, and the router class disappears. Until then, the legacy `Router/` and `BaseNavigationRouter` stay; new Screens are reachable from legacy routers via `AnyView(SomeScreen())`, the same way `AboutScreen` is wired in today.

## Testing mocks

Neo tests inject mock service implementations directly into the VM constructor — no DI container, no global state. All mocks live alongside the test that uses them (or in the same `Features/` file when reused across tests). There are two shapes to reach for.

### Struct mock with stored callbacks

Use when the protocol is stateless from the mock's perspective: the test seeds the return values up front and verifies results after the call. Seeded properties are `let`; call counters are `private(set) var`. The type conforms to `Sendable` directly (value semantics or actor-isolated state means no `@unchecked` needed).

**Canonical in-tree examples:** `MockCredentialStoring` and `MockPreferencesReading` in [`WindscribeTests/Features/M3ServiceProtocolMockabilityTests.swift`](../WindscribeTests/Features/M3ServiceProtocolMockabilityTests.swift).

```swift
final class MockCredentialStoring: CredentialStoring, @unchecked Sendable {
    let openVPNCredentials: ServerCredentialsModel?
    let ikev2Credentials: ServerCredentialsModel?
    private(set) var refreshCallCount = 0

    init(openVPN: ServerCredentialsModel?, ikev2: ServerCredentialsModel?) {
        self.openVPNCredentials = openVPN
        self.ikev2Credentials = ikev2
    }

    func refreshOpenVPNCredentials() async throws { refreshCallCount += 1 }
    func refreshIKEv2Credentials() async throws { refreshCallCount += 1 }
}
```

Use `@unchecked Sendable` on `final class` only when the mutable state (`refreshCallCount`) is test-local and single-threaded. For mocks that receive concurrent calls, use the actor shape below.

### Actor mock for state

Use when the mock must record mutable state (call log, captured arguments, emitted values) that could be read or written from multiple isolation contexts. Declare the type as `actor` — the actor serialises all access, so `@unchecked Sendable` is not needed.

**Canonical in-tree example:** `ActorMockCredentialStoring` in [`WindscribeTests/Features/MockPatternTests.swift`](../WindscribeTests/Features/MockPatternTests.swift).

```swift
actor ActorMockCredentialStoring: CredentialStoring {
    // Protocol requires sync nonisolated getters; `let` is implicitly
    // nonisolated on an actor.
    let openVPNCredentials: ServerCredentialsModel?
    let ikev2Credentials: ServerCredentialsModel?

    // Mutable state stays actor-isolated.
    private(set) var refreshCallCount = 0

    init(openVPN: ServerCredentialsModel? = nil, ikev2: ServerCredentialsModel? = nil) {
        self.openVPNCredentials = openVPN
        self.ikev2Credentials = ikev2
    }

    func refreshOpenVPNCredentials() async throws { refreshCallCount += 1 }
    func refreshIKEv2Credentials() async throws { refreshCallCount += 1 }
}

// Reading state from the test:
let count = await mock.refreshCallCount
```

The rule: protocol requirements that are **sync nonisolated** (read-only properties on a `Sendable` protocol) need either immutable `let` storage on the actor, or `nonisolated` accessors backed by `Sendable` state. Don't reach for `nonisolated(unsafe)` — if you need mutable nonisolated state, the actor's the wrong tool.

**When to pick which:**

| Situation | Shape |
|---|---|
| Mock returns canned values; test is single-threaded | `final class … @unchecked Sendable` |
| Mock tracks call history; VM calls it from `@MainActor` or a `Task` | `actor` |
| Mock drives an `AsyncStream` (e.g. `MockServerProviding`) | `final class … @unchecked Sendable` — the stream's `Continuation` is the serialisation boundary |

## GRDB test fixtures

New GRDB-backed stores are tested against an **in-memory `DatabaseQueue`** — no file I/O, clean state per test, no teardown required.

### The canonical pattern

Every store test follows the same three-step setup: create an in-memory queue, apply the **production migrator** (`GRDBSchema.makeMigrator()`), and inject the queue into the store under test via constructor injection.

Canonical reference: [`WindscribeTests/Data/RecordTests/PingDataRecordTests.swift`](../WindscribeTests/Data/RecordTests/PingDataRecordTests.swift) (record-level) and [`WindscribeTests/Data/GRDBLocalDatabaseParityTests.swift`](../WindscribeTests/Data/GRDBLocalDatabaseParityTests.swift) (full-store level, from M2 D2.2 / !1311).

**Record-level test (copy this for a single `FetchableRecord`/`PersistableRecord`):**

```swift
import Testing
import GRDB
@testable import Windscribe

@Suite struct PingDataRecordTests {
    private func makeDB() throws -> DatabaseQueue {
        let queue = try DatabaseQueue()          // in-memory, no path
        try GRDBSchema.makeMigrator().migrate(queue)
        return queue
    }

    @Test func roundTrip() throws {
        let model  = PingDataModel(ip: "10.0.0.1", latency: 42)
        let record = PingDataRecord(from: model)
        let queue  = try makeDB()
        try queue.write { db in try record.save(db) }
        let fetched = try queue.read { db in try PingDataRecord.fetchOne(db, key: record.ip) }
        #expect(fetched == record)
        #expect(fetched?.toModel() == model)
    }
}
```

**Full-store test (copy this to exercise a `LocalDatabase` implementation):**

```swift
// GRDBLocalDatabaseParityTests.swift — in-memory store wired into the contract suite
final class GRDBLocalDatabaseParityTests: LocalDatabaseContractTests {
    override func makeLocalDatabase() -> LocalDatabase? {
        do {
            let queue = try DatabaseQueue()
            try GRDBSchema.makeMigrator().migrate(queue)
            return GRDBLocalDatabaseImpl(
                logger: MockLogger(),
                preferences: MockPreferences(),
                dbQueue: queue
            )
        } catch {
            XCTFail("Failed to set up in-memory DB: \(error)")
            return nil
        }
    }
}
```

### Rules

- **One `makeDB()` call per test function.** Never share a `DatabaseQueue` across tests — isolation is the only thing in-memory buys you over a file-backed DB.
- **Use the production migrator, not a hand-rolled schema.** `GRDBSchema.makeMigrator().migrate(queue)` applies the same migration sequence production does. A test-only schema diverges silently and defeats the purpose of the test.
- **Constructor-inject `DatabaseQueue`.** `GRDBLocalDatabaseImpl` accepts `dbQueue:` at init. Don't subclass or use a global.
- **New tests use Swift Testing** (`import Testing`, `@Test`, `#expect`). The XCTest `makeDB()` shape above is shown because the existing in-tree examples predate M5; new suites should use `@Suite` + `@Test`.

## Applying these patterns to tvOS

Project Neo is **platform-symmetric**. Everything above applies identically to [`WindscribeTV/Features/`](../WindscribeTV/Features/). New tvOS work goes in that directory; legacy tvOS UIKit screens stay in `WindscribeTV/UI/` until they are rebuilt. Capability protocols and adapters live in [`WindscribeTV/Services/Protocols/`](../WindscribeTV/Services/Protocols/), mirroring the iOS layout. SwiftLint custom rules apply to both Features paths automatically.

The `@Observable` `@MainActor` view model, `@Environment(@Entry)`-injected protocol services, and `AsyncStream`-over-Combine boundary patterns from `Windscribe/Features/About/` are platform-agnostic — copy them as-is. Only the SwiftUI surface and the affordances below change.

tvOS-specific affordances to layer on top:

- **Focus engine**: SwiftUI handles focus automatically with `.focusable()`, `.focused()`, and the standard list/grid containers. Don't reach for UIKit's `UIFocusGuide` unless you've exhausted SwiftUI options.
- **Remote input**: `onPlayPauseCommand`, `onExitCommand`, etc. for hardware-button handlers. Avoid `UITapGestureRecognizer`-style patterns from the legacy tvOS code.
- **Layout**: prefer `LazyVGrid` / `HStack` over `UICollectionViewCompositionalLayout`-style designs from the legacy `WindscribeTV/UI/` controllers.
- **Navigation**: `NavigationStack` with focus-engine-aware modifiers; the iOS `NavigationRouter/` modifier may need a thin tvOS variant.

If tvOS designs land before iOS, the first rebuilt tvOS screen plays the role About plays for iOS — it becomes the canonical tvOS reference and the README pointers in `WindscribeTV/Features/` should be updated to link it directly.

## Where to find things

| Concern | File |
|---|---|
| Roadmap (what's planned, what's done) | [`docs/neo/plans/00-roadmap.md`](neo/plans/00-roadmap.md) |
| Architectural decision log | [`docs/neo/DECISIONS.md`](neo/DECISIONS.md) |
| Execution log (what shipped, when, on which branch) | [`docs/neo/STATE.md`](neo/STATE.md) |
| Per-issue plans (one file per active issue) | [`docs/neo/plans/M*.md`](neo/plans/) |
| Repo conventions, build instructions, target layout | [`AGENTS.md`](../AGENTS.md) |
| Lint config (custom rules enforce rules above) | [`.swiftlint.yml`](../.swiftlint.yml) |

## When you finish a Neo task

- Append a one-line entry to [`docs/neo/STATE.md`](neo/STATE.md): date, issue, branch, commit SHA, what shipped, what's next.
- If the task settled an architectural question that wasn't already recorded, append an entry to [`docs/neo/DECISIONS.md`](neo/DECISIONS.md): decision, why, alternatives considered.
- Don't rely on private agent memory or chat history. Anything another teammate or another agent would need is **in the repo or it doesn't exist**.

---

*This is a living document. Update it as Neo patterns evolve.*
