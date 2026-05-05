# Project Neo — Architectural Decision Log

> **Append-only.** Don't edit existing entries; supersede them with new entries that reference the prior ID. Every architectural decision lands here as part of the PR that implements it.
>
> See [`PROJECT_NEO.md`](../PROJECT_NEO.md) for the rule sheet and [`STATE.md`](STATE.md) for execution status.

---

## ND-001 — `main` stays launchable; two-track landing strategy

**Date:** 2026-04-30
**Status:** Active
**Context:** Project Neo is a multi-issue, multi-month effort. The team needs to keep shipping non-Neo fixes and minor features to current-floor users (iOS 15+) throughout, without dragging Neo work along.

**Decision:**

- `main` keeps shipping to current-floor users. Neo work lands on `main` **only if it is strictly forward-compatible** with the current app.
- Anything that lifts the deployment target, deletes legacy that current-floor users still need, or otherwise breaks the ability to release from `main` lives on `neo-5.0` until v5.0 ships.
- Two PR flavors:
  - **Main-safe** — opens against `main`; flows to `neo-5.0` via the periodic merge. Purely additive (new files / lint rules scoped to new paths / new docs), pure behavior-preserving refactors, or new code gated with `@available(iOS 17.0, *)`.
  - **`neo-5.0`-only** — opens against `neo-5.0` directly. Never merged back to `main` until v5.0 launch.
- **Cadence:** `main → neo-5.0` runs at least weekly and after any non-trivial PR lands on `main`. `neo-5.0 → main` runs only at v5.0 launch.

**Why:** Releases are infrequent — there is no fast-follow window. A multi-month long-lived branch with one big merge at the end is the standard recipe for both shippable-`main` outages and a painful final merge. The two-track approach lets most foundation work land continuously while reserving `neo-5.0` for the irreversible-forward-only changes.

**Alternatives considered:**

- **All Neo work on `neo-5.0` from day one.** Rejected: ~6+ months of divergence; foundation patterns wouldn't reach `main` until launch, blocking incidental adoption by team members not on Neo work.
- **All Neo work on `main` with feature flags.** Rejected: deployment-target lift can't be feature-flagged. The moment we bump `IPHONEOS_DEPLOYMENT_TARGET` on `main`, we cut off iOS 15/16/17 users from any future `main`-based release.

**Applies to:** every Neo issue. Each issue's plan file declares its landing branch explicitly.

---

## ND-002 — tvOS floor lifts to 18 in M1, on `neo-5.0` only

**Date:** 2026-04-30
**Status:** Active
**Context:** The Project Neo manifesto specifies an iOS 18 floor. tvOS is also part of v5.0 — the question was whether to lift `TVOS_DEPLOYMENT_TARGET` (currently 17.5) to 18 alongside iOS, and on which branch.

**Decision:** Lift `TVOS_DEPLOYMENT_TARGET` to 18.0 in M1, on `neo-5.0` only — paired with the iOS 18 lift. Same forward-compat rule applies (per ND-001): bumping the tvOS floor on `main` would block tvOS 17.5 users from any subsequent main-based release, so the lift happens once, on `neo-5.0`, when we're committed.

**Why:** Same floor across platforms means the same `@available` cleanup, the same Neo patterns (manifesto's modern stack works identically on tvOS 18), and a single composition story across iOS and tvOS in v5.0. No reason to keep tvOS one major behind.

**Alternatives considered:**

- **Hold tvOS at 17.5 until M9.** Rejected: most of the foundation work (M0–M6) is platform-shared; lifting the tvOS floor only at M9 would force us to gate Neo patterns with tvOS-specific availability checks for months, then delete them.

**Applies to:** M1, M9.

---

## ND-003 — Canonical reference module is `LookAndFeel`, `@available(iOS 17.0, *)`-gated

**Date:** 2026-04-30
**Status:** Superseded by ND-005 (2026-04-30) — see below.
**Context:** M0 needs one canonical, real, end-to-end Neo example so that "add a new screen" is a copy-paste-and-rename exercise rather than an architectural decision. The candidate set was Preferences leaves (already SwiftUI views, small scope) — `LookAndFeel`, `General`, etc.

**Decision:** Use `LookAndFeelSettingsView` + `LookAndFeelViewModel`, moved to `Windscribe/Features/LookAndFeel/`. The new module is `@available(iOS 17.0, *)`-gated and runs alongside the existing legacy LookAndFeel — users on iOS 15/16 keep the legacy code path. `General` becomes M7's recipe-validation candidate.

**Why:** Real user surface, self-contained, view is already SwiftUI. Migrating from `ObservableObject` → `@Observable` + protocol services + Swift Testing exercises the full Neo pattern with low blast radius. The `@available` gating is what makes the reference module main-safe (per ND-001).

**Alternatives considered:**

- **`General` first.** Rejected (close call): touches preferences storage in slightly more places. `LookAndFeel` is more self-contained, so it's the better first cut. `General` becomes M7's recipe-validation target instead.
- **Greenfield example with no real user surface.** Rejected: lower verification value. A real screen has real edge cases; a toy module would let real edge cases slip past M0.

**Applies to:** M0 (PR 3), M7.

---

## ND-004 — Architectural rules enforced via SwiftLint custom rules scoped to new paths

**Date:** 2026-04-30
**Status:** Active
**Context:** The Neo "Hard rules for new code" need automated enforcement so that violations are caught at MR review without manual policing. Lint already runs on every MR via fastlane.

**Decision:** Add `custom_rules:` blocks to `.swiftlint.yml` scoped to `Windscribe/Features/**` and `WindscribeTV/Features/**`. The rules forbid the legacy patterns inside those paths only — existing legacy code under `ViewControllers/`, `Modules/`, etc. is unaffected.

Rule set:

- `import Swinject`
- `import SnapKit` (with legacy allowlist for `Modules/PlanUpgrade/**`, `WindscribeTV/UI/**`)
- `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject`
- `import RealmSwift` (allowlist: `Windscribe/Data/Database/**`)
- `static let shared`
- `import Combine`
- `class.*: UIViewController`

**Why:** No new tooling. Existing CI catches violations. Path-scoping means we don't generate noise on legacy code that isn't under migration yet. Self-enforcing — the moment `Windscribe/Features/X/` exists, the rules apply.

**Alternatives considered:**

- **Separate CI grep step.** Rejected: second source of truth, less discoverable than the existing lint config.
- **Documentation + code review only.** Rejected: too easy to drift, especially for AI-generated PRs that may not have read the docs.

**Applies to:** M0 (PR 2), M3 (adds `Assembler.resolve` to the rule set).

---

## ND-005 — Canonical reference module is `About` (supersedes ND-003)

**Date:** 2026-04-30
**Status:** Active
**Supersedes:** ND-003

**Context:** ND-003 picked `LookAndFeel` as the M0 canonical reference based on a high-level read ("self-contained Preferences leaf, view already SwiftUI"). When PR 3 implementation began, reading the actual code revealed `LookAndFeelSettingsViewModel` is a 374-line class with 7 dependencies, inherits from `PreferencesBaseViewModelImpl`, drives a sub-router for app-icon selection, and handles file import/export for custom locations + backgrounds + sounds. Migrating it would force many judgment calls (router-in-VM, file-pickers-as-services, multi-step Combine chains, multi-protocol injection) and produce a >1,000-line PR that's neither easy to review nor easy to copy as a template — exactly what ND-003's "if the recipe required *any* judgment calls beyond mechanical transformation, refine the scaffolding" guard was protecting against.

**Decision:** Switch the M0 canonical reference to `AboutSettingsView` + `AboutSettingsViewModel`, moved to `Windscribe/Features/About/`. Keep the `@available(iOS 17.0, *)` gating principle from ND-003. `LookAndFeel` becomes a candidate for M7's "second rebuilt screen" or M8's broader Preferences VM migration — its complexity is exactly what makes it the right *recipe-validation* test rather than the recipe-defining one.

**Why About:**

- 57-line VM, 48-line View. Reasonable PR size.
- 2 dependencies (`FileLogger`, `LookAndFeelRepositoryType`). Realistic but minimal protocol surface to seed `Windscribe/Services/Protocols/`.
- One Combine binding (the dark-mode subject) — demonstrates the `Combine .values → AsyncStream` conversion at a manageable scale.
- Sheet presentation (`SafariView`) — demonstrates simple stateful UI without router complexity.
- No file I/O, no inheritance, no sub-routes, no async chains.

**Alternatives considered:**

- **Push through with `LookAndFeel`.** Rejected — would produce a >1,000-line PR; the resulting "reference" wouldn't be a copy-paste template, defeating M0's goal.
- **Thin slice of `LookAndFeel` (just the appearance entry).** Rejected — leaves half the screen on the legacy path and half on Neo, creates a confusing mid-state inside one feature.
- **`General` or `Robert`.** Both are smaller than LookAndFeel but larger than About. About is the cleanest first cut.

**Applies to:** M0 (PR 3), M7 (recipe-validation target — likely `General`, possibly `LookAndFeel`).


## ND-006 — Per-target Swift 6 push fallback (Swift 5 + STRICT_CONCURRENCY=complete)

**Date:** 2026-05-01
**Status:** Active
**Context:** M1's recipe was "lift each target to `SWIFT_VERSION = 6.0` with `SWIFT_STRICT_CONCURRENCY = complete`." Warming up on `WindscribeTests` (the smallest target) surfaced ~24 build errors and ~170 warnings the moment `SWIFT_VERSION` flipped to 6.0 — most of them were rooted in production-code Sendability gaps (Combine subjects crossing isolation boundaries, non-Sendable manager protocols, `@unchecked Sendable` workarounds we'd want to eliminate rather than spread). Shipping that on `neo-5.0` would have couple Swift-6-mode work to M1 indefinitely.

**Decision:** For M1, land each target at `SWIFT_VERSION = 5.0` with `SWIFT_STRICT_CONCURRENCY = complete`. Catalog the resulting warnings as the explicit Swift 6 chase list. The full `SWIFT_VERSION = 6.0` flip happens per-target in M3/M4 once production-protocol Sendability is cleaned up. Net: 4 active targets on Swift 5 + complete in M1; warning catalog (170 + 0 + 14 + 1194 = 1378 warnings) hands off to M3/M4.

**Why:** Strict-concurrency + complete is the most aggressive checking Swift 5 offers; flipping SWIFT_VERSION on top is mostly a syntactic gate (the diagnostics largely already fire under "complete"). Decoupling the language-mode flip from M1 lets M1 ship clean and lets M3/M4 fix the underlying Sendability gaps once, where they belong, instead of spreading `@preconcurrency` and `@unchecked Sendable` workarounds across M1.

**Alternatives considered:**

- **Push every target to Swift 6 in M1.** Rejected — would have required ~24 production-code fixes (most of them touching protocol boundaries scheduled for M4) plus ~170 warning-suppressing annotations, all to land in M1 before M3/M4 had a chance to clean them up properly.
- **Skip strict-concurrency entirely until M3/M4.** Rejected — `complete` mode is what surfaces the warning catalog. Without it the chase list wouldn't exist as a build-time signal.

**Applies to:** M1 (all 4 active targets), M3 (production-protocol Sendability cleanup), M4 (async-boundary wrappers + protocol Sendability).

---

## ND-007 — M2 launch cadence: 3-phase Pre-Neo / Neo / Post-Neo, gated by `/CheckUpdate`

**Date:** 2026-05-01
**Status:** Active
**Context:** The Realm→GRDB migration is one-way per device — once `didMigrateRealmToGRDB` flips, that user's data lives in GRDB. The migration code (Realm reader + `RealmToGRDBMigrator`) must stay in the binary until every active user has run it at least once. The original GRDB plan said "delete Realm one release after migration ships" which is far too aggressive for iOS update reality (long-tail upgraders skip releases; pre-migration users opening the app months later would see fresh-install behavior and lose custom configs / favorites / Wi-Fi prefs). The `/CheckUpdate` endpoint already provides a soft-nag-and-force-upgrade mechanism — using it lets us bound the long tail.

**Decision:** The M2 work ships across three phases, with `/CheckUpdate` driving the upgrade gate at each transition:

- **Phase 1 — Pre-Neo release:** D2.2 (the GRDB migration MR) ships to `main`. Begin nag-to-update via `/CheckUpdate` for users below this version. Ship the **force-upgrade** capability via `/CheckUpdate` (the mechanism, not yet enforced for this version).
- **Phase 2 — Neo 5.0:** UI rebuild + iOS 18 floor. Continue nagging users below Neo, do **not** force-upgrade them (Neo is a bigger jump). Realm + `RealmToGRDBMigrator` must still ship in Neo so anyone upgrading from a pre-Pre-Neo build directly to Neo still gets their custom configs ported.
- **Phase 3 — Post-Neo cleanup:** ≥3 months after Neo ships, flip `/CheckUpdate` to **force-upgrade everyone below Pre-Neo** (target = "at least Pre-Neo," not Neo — iOS 15-17 users can't take Neo and stay on Pre-Neo with Realm linked). Once force-upgrade has bedded in (every active user has run the migrator at least once), ship D2.4 (the Realm-removal PR).

The 3-month gate is the explicit soak window. Force-upgrade-to-Pre-Neo (rather than to Neo) preserves the iOS-floor separation set up in M0/M1's branching strategy.

**Why:** The bounded-soak-then-force-upgrade approach turns "we can never delete Realm without writing off long-tail users" into "we can delete Realm after a defined, monitored window in which `/CheckUpdate` migrates the long tail to a binary that has the migrator." It exploits an existing mechanism (`/CheckUpdate`) that we control. Custom configs are user-uploaded `.ovpn`/`.conf` files — losing them would be the worst long-tail failure mode; this path eliminates it.

**Alternatives considered:**

- **Delete Realm one main release after D2.2 ships.** Rejected — long-tail users skipping releases would lose custom configs.
- **Keep Realm linked indefinitely.** Rejected — keeps Realm + `realm-core` in the binary forever (~10–14 MB) for diminishing returns once force-upgrade can shrink the active long-tail population to zero.
- **Separate "pre-removal" PR for keychain-orphaned Realm classes (Session/OldSession/OpenVPN/IKEv2).** Considered (2026-05-01 strategy session). Rejected for now — failure mode is re-login, not data loss, but folding the deletion into D2.4 is cleaner than carrying a separate PR. Revisit if the keychain MR's soak telemetry warrants an earlier sweep.

**Applies to:** M2 (D2.2 / D2.3 / D2.4 sequencing), M10 (Neo launch must include Realm + migrator), and any post-Neo cleanup work that depends on `/CheckUpdate` force-upgrade telemetry.
