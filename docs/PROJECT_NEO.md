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

## Adding a new feature

The shape every Neo feature follows:

```
View (SwiftUI, @available(iOS 17.0, *))
  ⇄  ViewModel (@Observable, @MainActor, no SwiftUI imports)
    ⇄  Service protocol (Sendable, in Windscribe/Services/Protocols/)
      ⇄  Implementation (real impl + adapter to legacy Swinject services where applicable)
```

The canonical reference is **`Windscribe/Features/About/`** (lands as part of M0; see ND-005). Copy that module, change names. If you need to make architectural decisions to do so, that's a signal the reference needs refining — flag it on the M0 issue rather than diverging.

Tests live in `WindscribeTests/Features/<FeatureName>Tests.swift` using the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`). Each test injects mock service implementations directly into the VM constructor. No DI container needed.

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
