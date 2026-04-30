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
**Status:** Active
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
