# Project Neo / v5.0 — Roadmap

## GitLab structure

This roadmap maps directly onto our GitLab tracking:

- **GitLab Milestone:** `Project Neo / 5.0` — the umbrella that contains everything in this document. All issues for the v5.0 release are filed against this milestone.
- **GitLab Issues:** each `M0`–`M10` section below is an independent GitLab issue under the milestone above. The `M`-prefix is just a stable identifier; in GitLab they're issues, not milestones. Issues are independently scheduled, assigned, and shipped.
- **Tasks within an issue:** checklist items inside the issue's description.

## Context

Project Neo is the Windscribe iOS/tvOS modernization effort that lands as **version 5.0**. The end state: iOS 18 floor, full SwiftUI rebuild, `@Observable` + async/await, GRDB persistence, constructor DI, Swinject/Combine/Realm/SnapKit retired, Swift 6 language mode.

What's true today (April 2026):

- Working integration branch is `neo-5.0`.
- **No firm UI designs yet.** Major flows are stable in concept (Main + connect + server list + preferences), but pixel-level redesigns are pending.
- Releases are infrequent — every issue must ship clean on the first prod release; no fast-follow window.

Two pieces of modernization work are **already in flight** and are *not* re-planned here. They're tracked as parallel dependencies:

- **Keychain consolidation** — actively being worked on now.
- **Realm → GRDB migration** — drafted on `aw/realm-to-grdb`, parked behind the Keychain work. Has its own multi-step planning document; will move into [`docs/neo/plans/M2-grdb-migration.md`](M2-grdb-migration.md) when M2 work resumes.

This document is the umbrella roadmap. Each issue below should ultimately get its own plan file in `docs/neo/plans/` when work begins on it (M0's plan is at [`M0-guardrails.md`](M0-guardrails.md)).

## Strategy

The driving principle is **foundational work + guardrails for teammates.** That dictates the sequencing:

1. **Guardrails before code.** Lint rules + scaffolding + a canonical reference module *first*, so any contributor's next PR is automatically pulled toward the target architecture instead of away from it.
2. **Lift the floor early.** iOS 18 + tvOS 18 + Swift 6-ready settings unlock the manifesto's patterns and let us delete a lot of `#available` cruft.
3. **Strangler over big-bang.** Existing screens stay legacy until they're rebuilt. New modules use only the modern stack. We never mass-migrate.
4. **Track Realm→GRDB and Keychain as dependencies, not duplicates.** Their plans already exist; Neo pulls them in by reference.
5. **Defer UI rebuild issues until designs land.** Sketch the shape (M7–M9) so the path is visible, but don't commit detail.
6. **Platform-agnostic foundation.** M0–M6 are explicitly **not** iOS-first. The patterns they establish apply identically to iOS and tvOS — both use SwiftUI on the modern stack. The UI rebuilds in M8/M9 are **independently orderable**: whichever platform's designs land first goes first.

### Decisions (April 2026)

See [`../DECISIONS.md`](../DECISIONS.md) for the full architectural decision log. Headlines:

- **`main` stays launchable at all times.** Neo work lands on `main` only if strictly forward-compatible.
- **Two-track landing strategy** with explicit per-issue landing rules (table below).
- **tvOS floor lifts to 18 in M1, on `neo-5.0` only.**
- **Canonical reference module: `Windscribe/Features/About/`** (per ND-005, supersedes ND-003), `@available(iOS 17.0, *)`-gated.
- **Enforcement: custom SwiftLint regex rules** scoped to `Windscribe/Features/**` and `WindscribeTV/Features/**`.

#### Branching strategy at a glance

| Issue | Default landing | Why |
|---|---|---|
| M0 — Guardrails | `main → neo-5.0` | Docs + lint rules + `@available`-gated reference module. Purely additive. |
| M1 — iOS 18 floor | `neo-5.0` only | Deployment-target bump breaks shippability to current floor. |
| M2 — Persistence (Keychain + GRDB) | `main → neo-5.0` | Keychain + GRDB plans designed to ship from main on the existing floor. |
| M3 — DI modernization (shims) | `main → neo-5.0` | Adapter shims are additive; legacy DI graph untouched. |
| M4 — Async/Sendable boundaries | mixed (see issue) | T4.1, T4.2 are additive → `main`. T4.3 depends on M1 → `neo-5.0`. |
| M5 — Testing modernization | `main → neo-5.0` | Swift Testing runs alongside XCTest; additive. |
| M6 — Tunnel/extensions cleanup | mixed (see issue) | IKEv2 consolidation can land on `main` (no behavior change). Guard deletion + SiriIntents removal → `neo-5.0`. |
| M7 — Second rebuilt screen | `main → neo-5.0` | Same `@available` gating as M0 reference. |
| M8 — iOS UI rebuild | `neo-5.0` only | Replacement of legacy surface; relies on iOS 18 floor. |
| M9 — tvOS UI rebuild | `neo-5.0` only | Same as M8 for tvOS. |
| M10 — v5.0 launch | `neo-5.0 → main` (the merge) | The single moment we collapse the two branches. |

**Cadence:** `main → neo-5.0` merge runs at least weekly (or after any non-trivial PR lands on `main`). `neo-5.0 → main` runs **only at v5.0 launch.**

## Snapshot of current state (informs sizing)

| Dimension | Today | Target |
|---|---|---|
| iOS deployment target | 15.0 (one outlier at 16.0, one extension at 17.5) | 18.0 |
| tvOS deployment target | 17.5 | 18.0 |
| Swift version | 5.0 dominant; tests partially on 6.0 | 6.0 across all targets |
| `SWIFT_STRICT_CONCURRENCY` | Unset everywhere | `targeted` → `complete` per module |
| Swinject registrations | ~238 across iOS + tvOS modules | 0 (constructor injection + `@Environment`) |
| Realm-touching files | 48, leaked beyond `Data/Database/` | 0 |
| Combine-touching files | 204 | 0 (in new code; Apple-API boundaries converted with `.values`) |
| SnapKit files | 14 (mostly `Modules/PlanUpgrade/`) | 0 |
| RxSwift | 0 (already removed) | 0 |
| GRDB | not present | primary persistence |
| SwiftUI views in tree | ~89 (Auth, Preferences, Popups, News Feed, Widget) | all UI |
| Major UIKit hubs remaining | `MainViewController` (~5,200 lines), `PlanUpgrade` (~2,666 lines), tvOS (3,300+ lines) | rebuilt |
| `@Observable` view models | 0 (all 37+ existing VMs are `ObservableObject`) | all VMs |
| Test framework | XCTest (36 files); Swift Testing 0 | Swift Testing for new tests |

## Issues

Each issue below is one GitLab issue under the `Project Neo / 5.0` milestone. They are ordered by readiness — earlier issues unblock later ones. Tasks inside a single issue can usually run in parallel.

For the up-to-date task breakdown of any active issue, see its plan file in this directory. M0's plan is at [`M0-guardrails.md`](M0-guardrails.md).

---

### M0 — Project Neo Guardrails (unblocks team contribution)

**Lands on:** `main → neo-5.0`. All M0 work is forward-compatible. Docs and lint rules are purely additive. The About reference module ships behind `@available(iOS 17.0, *)` and runtime-branches against the existing legacy About — users on iOS 15/16 are unaffected.

**Goal:** Make it cheaper for teammates — and their AI agents — to write Neo-shaped code than to copy a legacy pattern. Establishes the rules, the working examples, and the **shared context layer** *before* the rebuild begins.

**Outcome:**

- Shared context layer in tree (this directory, [`../DECISIONS.md`](../DECISIONS.md), [`../STATE.md`](../STATE.md), [`../../PROJECT_NEO.md`](../../PROJECT_NEO.md)).
- SwiftLint custom rules forbidding the legacy patterns inside `Windscribe/Features/**` and `WindscribeTV/Features/**`.
- Canonical reference module `Windscribe/Features/About/` end-to-end Neo: `@Observable` `@MainActor` VM, protocol-injected services, SwiftUI view via `@Environment(@Entry)`, Swift Testing tests with mock services.
- `WindscribeTV/Features/` skeleton + tvOS-pattern doc section so tvOS isn't blocked if its designs land first.

For per-task detail, see [`M0-guardrails.md`](M0-guardrails.md).

---

### M1 — iOS 18 Floor + Swift 6-ready Build Settings

**Lands on:** `neo-5.0` only. Every task in M1 commits the codebase to a floor that current main-branch users haven't been migrated to yet. PRs open against `neo-5.0`.

**Goal:** Lift the foundation so the manifesto's patterns are unconditionally available, and so we shed `#available` cruft.

**Outcome:**

- All iOS targets at `IPHONEOS_DEPLOYMENT_TARGET = 18.0`. tvOS targets at `TVOS_DEPLOYMENT_TARGET = 18.0`.
- All targets at Swift 6 language mode *or* Swift 5 with `SWIFT_STRICT_CONCURRENCY = complete`. Per-target push: WindscribeTests → HomeWidget → AppIntents → SiriIntents → tunnel extensions → `Windscribe`.
- All `#available(iOS 15.x)` and `#available(iOS 16.x)` guards deleted (12 known sites in `VPNUserSettings.swift`, `VPNManagerUtils+IKEV2Credentials.swift`, `ConfigurationsManager+Connect.swift`).
- `legacyOS` (`<= 13`) branch in `configureIKEV2` deleted.
- `HomeWidget` `#available(iOSApplicationExtension 17.0)` fallbacks deleted; `PreviewProvider` replaced with `#Preview` macro.

**Verification:** All schemes build. Test suite passes. `grep -rn "#available(iOS 1[5-7]" Windscribe/ WindscribeTV/ PacketTunnel/ WireGuardTunnel/` returns zero.

---

### M2 — Persistence Track (parallel — not re-planned)

**Lands on:** `main → neo-5.0` for D2.1 (already merged) and D2.2. The Realm-removal PR (D2.4) lands on whichever branch is active when the long-tail soak window closes — see "Launch cadence" below.

**Goal:** Move sensitive state into the Keychain (done — !1323), then port the remaining `LocalDatabase`-resident state from Realm to GRDB, then ship a normalization pass, and finally retire Realm once `/CheckUpdate` force-upgrade has bedded in.

This issue is a **dependency tracker**, not a new plan. Source-of-truth plans:

- Keychain consolidation: ✅ merged to `main` as !1323 (#1040), 2026-05-01.
- Realm→GRDB migration: `aw/realm-to-grdb`, plan + execution log at `~/.claude/plans/we-ve-maybe-briefly-touched-delegated-pike.md`. Plan migrates into [`M2-grdb-migration.md`](M2-grdb-migration.md) once D2.2 is opened for review.

**Outcome:**

- D2.1 ✅ Keychain consolidation merged to `main` as !1323 (2026-05-01). Sessions, OldSession, OpenVPN/IKEv2 server credentials, custom-config credentials, and session auth hash now live in the Keychain via `SessionKeychainStore` / `Preferences+Keychain`. `LocalDatabase` gained three `clear*` methods used by `MigrationRepository` to wipe stale Realm rows post-port. `LocalDatabase.{saveSession, getSessionPublisher, saveOldSession, getOldSession, save{OpenVPN,IKEv2}ServerCredentials}` are gone.
- D2.2 ✅ GRDB Migration PR merged as !1311 (2026-05-05) on `main` (the **Pre-Neo release**). 14 entity families mirrored 1:1; sessions/credentials remain Keychain-resident. Realm + `RealmToGRDBMigrator` stay linked as the migration source + fallback. **M2 #1050 closed.**
- D2.3 → **#1065** (split out from #1050): pure GRDB v1→v2 migration covering the ~10 surviving normalization items (the original 12 minus the two moot'd by the Keychain move — flatten Session.alc / merge OpenVPN+IKEv2 credentials tables). Decoupled from D2.4; can ship as soon as one main release after D2.2.
- D2.4 → **#1066** (split out from #1050): Realm-removal PR ships **post-Neo + 3-month forced-upgrade soak** (see Launch cadence). Drops `LocalDatabaseImpl`, the `realm-swift` SPM packages, target linkage, the migrator, and the keychain `clear*` migration hooks.

**Launch cadence (gated by `/CheckUpdate` nag + force-upgrade):**

- **Phase 1 — "Pre-Neo" release (D2.2 ships):** GRDB migration goes live to `main`. Begin nag-to-update via `/CheckUpdate` for users below this version. Introduce the **force-upgrade** capability via `/CheckUpdate` (the mechanism, not yet enforced for this version). Goal: maximum natural-update soak time before Neo lands; ramp telemetry on the migrator (success rate, digest hits, fallback frequency).
- **Phase 2 — "Neo 5.0" launch (M10):** UI rebuild + iOS 18 floor + the bulk of Neo. Continue nagging users below Neo via `/CheckUpdate`; **don't force-upgrade them** — Neo is a bigger jump and users get to choose their moment. **Realm + `RealmToGRDBMigrator` must still ship in Neo** — anyone upgrading from a pre-Pre-Neo build directly to Neo still needs the migrator to run before their custom configs are lost.
- **Phase 3 — "Post-Neo" cleanup:** ≥3 months after Neo ships, flip `/CheckUpdate` to **force-upgrade everyone below Pre-Neo** (target = "at least Pre-Neo," not Neo itself, so iOS 15-17 users still on Pre-Neo are unaffected; only stragglers below Pre-Neo get pushed). Once that's bedded in (every active user has run the migrator at least once), ship #1066 (D2.4 — Realm removal).

The 3-month gate is the explicit soak window. The forced-upgrade-to-Pre-Neo (not to Neo) preserves the iOS-floor separation set up in M0/M1's branching strategy: iOS 15-17 users stay on Pre-Neo indefinitely with Realm linked; only iOS 18+ users see Neo.

Once GRDB is in tree (post D2.2 step 2), `Windscribe/App/Environment+Dependencies.swift` should expose persistence stores via `@Entry` so the M0 reference module switches to consuming GRDB through these.

---

### M3 — DI Modernization (strangler pattern)

**Lands on:** `main → neo-5.0`. Adapter shims are additive — they live alongside the existing Swinject graph and don't change legacy behavior.

**Goal:** Stop adding to the Swinject graph. New modules use constructor injection + `@Environment` only. Existing 238 registrations decay as features migrate; we don't proactively rewrite legacy DI.

**Outcome:**

- A documented **boundary policy**: the Swinject `Assembler.resolve` site for a Neo feature is at the *composition seam* only. Inside the feature, DI is constructor + environment.
- Adapter shims for the 5–10 most-used legacy services. Initial set: `VPNConnecting`, `ServerProviding`, `CredentialStoring`, `PreferencesReading`, `SessionProviding`. Each: protocol + adapter holding `let legacy: LegacyType` resolved once via Swinject at the seam.
- `@Entry` values added to `EnvironmentValues`.
- SwiftLint rule forbidding `Assembler.resolve` calls in `Windscribe/Features/**` and `WindscribeTV/Features/**`.

**Verification:** `grep -rn "Assembler.resolve" Windscribe/Features/ WindscribeTV/Features/` returns zero. M0 reference module has no Swinject reference anywhere in its files.

---

### M4 — Async/Sendable Boundaries

**Lands on:** mixed.

- **T4.1, T4.2 → `main → neo-5.0`.** Wrapping concrete types in protocols and adding an `AsyncStream` surface alongside the existing Combine surface is purely additive.
- **T4.3 → `neo-5.0` only.** The async overrides for `startTunnel`/`stopTunnel`/`sleep`/`handleAppMessage` only become available with iOS 18 lifecycle changes from M1.

**Goal:** Convert the Apple-API boundaries that new Neo code will consume — wrap them so feature code never sees Combine or completion handlers.

**Outcome:**

- T4.1: Swift protocols wrapping `WSNetServerAPI` and `WSNetPingManager` (parallel to existing `WSNetBridgeAPIType`). DI sites updated in `Managers/VPN/ControlPlane.swift` and `Managers/Latency/LocalPingManager.swift`. Mockable for tests.
- T4.2: `VPNConnecting.status: AsyncStream<ConnectionStatus>` wrapping `NEVPNStatusDidChange`.
- T4.3: `async`-style overrides for `startTunnel` / `stopTunnel` / `sleep` / `handleAppMessage` in both `PacketTunnel/PacketTunnelProvider.swift` and `WireGuardTunnel/PacketTunnelProvider.swift`.
- T4.4: "Combine → AsyncSequence" conversion guideline appended to [`../../PROJECT_NEO.md`](../../PROJECT_NEO.md).
- T4.5 *(main → neo-5.0)*: Retire M3's narrow `@unchecked Sendable` exemption (per ND-006). M3 introduced `@unchecked Sendable` on six legacy-adapter classes and four retroactive struct conformances; M4 replaces them with proper Sendability:
  - Mark these legacy protocols `Sendable` directly: `VPNManager`, `LocationListRepository`, `CredentialsRepository`, `Preferences`, `UserSessionRepository`, `LookAndFeelRepositoryType` — and drop `@unchecked` from `LegacyVPNConnector`, `LegacyServerProvider`, `LegacyCredentialStore`, `LegacyPreferencesReader`, `LegacySessionProvider`, and M0's `LegacyLookAndFeelObserver`.
  - Move the retroactive `@unchecked Sendable` extensions on `LocationModel`, `DatacenterModel`, `SessionModel`, `ServerCredentialsModel` (currently at the bottom of the M3 protocol files in `Windscribe/Services/Protocols/`) to direct `Sendable` conformance on each type's definition.
  - Delete the "@unchecked Sendable is allowed at the legacy-adapter seam" subsection from [`../../PROJECT_NEO.md`](../../PROJECT_NEO.md) once the workarounds are gone.

**Verification:** A new feature module can subscribe to VPN status with `for await status in vpn.status` without `import Combine`. Tunnel logs show no behavior regression on physical hardware. T4.5: `grep -rn "@unchecked Sendable" Windscribe/Services/Protocols/` returns zero.

---

### M5 — Testing Modernization

**Lands on:** `main → neo-5.0`. Swift Testing runs alongside XCTest in the existing test target — purely additive.

**Goal:** Adopt Swift Testing for new tests; preserve XCTest for legacy.

**Outcome:**

- M0's reference module has a Swift Testing suite (delivered as part of M0).
- Mock guidance documented: how to write a `MockX: ProtocolX` instead of mocking concrete impls. Two worked examples (struct mock with stored callbacks, actor mock for state) live alongside the reference module.
- GRDB in-memory `DatabaseQueue` test fixture pattern documented (depends on M2 D2.2).
- CI's `fastlane test` collects Swift Testing results (XCResult parsing) alongside XCTest.

---

### M6 — Tunnel & Extensions Cleanup

**Lands on:** mixed.

- **T6.1 → `main → neo-5.0`.** Consolidating the two IKEv2 assembly sites into one (without deleting any `#available` branches) is a pure refactor.
- **T6.2, T6.3 → `neo-5.0` only.** Deleting the `SiriIntents` extension drops Shortcuts support for iOS 15 users (AppIntents requires iOS 16+).

**Goal:** Apply the iOS 18 floor benefits to the tunnel code. Consolidate duplication.

Depends on **M1** (for T6.2/T6.3).

**Outcome:**

- T6.1: Single IKEv2 protocol-assembly site. Currently duplicated between `IKEv2VPNConfiguration.buildProtocol` and `configureIKEV2WithSavedCredentials`. `#available` branches preserved on this PR.
- T6.2: `SiriIntents` extension deleted. `ShowLocationIntentHandler` folded into `AppIntents/ShowLocation.swift`. The 3 dead files in `SiriIntents/VPN Managers/` go with it.
- T6.3: Provisioning profiles + entitlements verified after target removal.
- Tunnel exclusion flags applied unconditionally (`includeAllNetworks`, `excludeLocalNetworks`) — guards removed in M1; this is the cleanup pass.

**Verification:** Connect/disconnect on hardware, IKEv2 + WG + OpenVPN. Shortcuts that used SiriIntents still resolve via AppIntents.

---

### M7 — Second Rebuilt Screen (recipe validation)

**Lands on:** `main → neo-5.0`. Same `@available(iOS 17.0, *)` gating as M0's reference module.

**Goal:** Prove the M0 reference module is truly copy-able. M0 ships About; M7 picks a sibling Preferences leaf (candidates: `GeneralSettings` or `LookAndFeel` — the latter is intentionally heavier and serves as a stress test of the recipe) and applies the recipe verbatim.

Depends on **M0** (About reference) and **M3** (DI shims established).

**Outcome:**

- A second migrated screen — candidate: `GeneralSettingsView` + `GeneralSettingsViewModel` moved to `Windscribe/Features/General/`.
- Migration recipe documented in [`../../PROJECT_NEO.md`](../../PROJECT_NEO.md): "How to convert an `ObservableObject` view model to `@Observable` in this codebase." Steps, gotchas, before/after diff.
- Swift Testing tests for the migrated VM.

If the recipe required *any* judgment calls beyond mechanical transformation, that's a signal to refine the M0 scaffolding before scaling.

**Verification:** Screen behaves identically to before, ships in a release. Recipe doc is concrete enough that a teammate can apply it to the next preferences leaf without help.

---

### M8 — iOS UI Rebuild (gated on iOS designs)

**Lands on:** `neo-5.0` only. Major-flow rebuilds replace existing legacy surface and rely on the iOS 18 floor from M1.

**Goal:** Rebuild the major iOS flows — **Main + connect**, **server list**, **preferences hub**, **PlanUpgrade**.

Cannot start in detail until iOS UI designs land. This issue is a **placeholder** in this plan; each flow gets its own sub-issue (and plan file in `docs/neo/plans/`) when designs are ready.

**M8 and M9 are independently orderable.** Either can go first based on which platform's designs land first. Both depend on the same foundation (M0–M6).

**Sketch of scope:**

- **Server list** — likely the easiest to rebuild against existing data; depends on GRDB (`ValueObservation`).
- **Main / Connect / Status** — biggest single legacy hub (~5,200 lines across `MainViewController/`). Will likely be subdivided into Connect, Status, and Quick-Connect sub-features.
- **Remaining Preferences VMs** — ~15 view models to migrate from `ObservableObject` → `@Observable` (M7's recipe applied repeatedly; About is done as M0's reference, M7's pick is the next). Views are already SwiftUI.
- **PlanUpgrade** — full UIKit + SnapKit rebuild as SwiftUI. Retires the SnapKit dependency.
- **Popups** — 13 view models to migrate (views already SwiftUI).
- **Authentication VMs** — 5 view models to migrate (views already SwiftUI).

Each sub-rebuild ships behind whatever feature flag / staged rollout the designs dictate.

---

### M9 — tvOS UI Rebuild (gated on tvOS designs)

**Lands on:** `neo-5.0` only. Same reasoning as M8 — major rebuild relies on the tvOS 18 floor from M1.

**Goal:** Bring tvOS to the same modern stack. tvOS UI is currently 100% UIKit (3,300+ lines, 13 view controllers, 5 routers).

Cannot start in detail until tvOS UI designs land. This issue gets its own plan file in `docs/neo/plans/` when designs are ready.

**M8 and M9 are independently orderable.** If tvOS designs land first, M9 runs first — the foundation (M0–M6) serves both platforms equally, and `WindscribeTV/Features/` is set up at M0 specifically so tvOS isn't blocked on an iOS reference module. The only sequencing constraints are GRDB (M2) for any rebuild that consumes persistence, and M1's tvOS 18 lift before any tvOS Neo screen.

**Sketch of scope:**

- All 13 tvOS view controllers rebuilt as SwiftUI views with `@Observable` view models in `WindscribeTV/Features/`.
- All 5 tvOS routers replaced with `NavigationStack`-based flows.
- The first rebuilt tvOS screen plays the same role for tvOS that About does for iOS — it's the canonical reference once it lands.
- DI shims (M3) reused; the Swinject graph in `WindscribeTV/Dependencies/` decays as features migrate.

---

### M10 — v5.0 Launch

**Lands on:** `neo-5.0 → main` (the merge). This is the single moment we collapse the two branches: `neo-5.0` merges back to `main`, the v5.0 tag is cut from the merge commit, and the team's working branch becomes `main` again. From this point on, `main` is the iOS 18 / tvOS 18 / Neo-only branch.

**Goal:** Ship Project Neo as Windscribe iOS/tvOS 5.0.

**Outcome:**

- App Store metadata refresh.
- Versioning bump in `Config.xcconfig` and Info.plists.
- Release-notes draft surfacing user-visible changes.
- Final verification on physical hardware across all three tunnel protocols and both platforms.
- Realm fallback retention plan: even after the GRDB migration ships, we keep the Realm reader linked for one release — per the persistence plan's "infrequent release" safety net.

---

## Critical files for orientation

| Concern | File |
|---|---|
| Contributor + AI-agent rules | [`../../PROJECT_NEO.md`](../../PROJECT_NEO.md) |
| Architectural decision log | [`../DECISIONS.md`](../DECISIONS.md) |
| Execution log | [`../STATE.md`](../STATE.md) |
| Current contributor guidance | [`../../../AGENTS.md`](../../../AGENTS.md) |
| Current build settings | `Windscribe.xcodeproj/project.pbxproj`, `Windscribe/Environments/Config.xcconfig` |
| Lint config (extend in M0) | `.swiftlint.yml` |
| Current DI graph | `Windscribe/Dependencies/AppModules/iOS/AppModulesCommon.swift`, `AppModulesViewModels.swift`, `AppModulesViewController.swift`, `AppModulesRouters.swift`, `AppModulesManagers.swift` |
| Realm scope | `Windscribe/Data/Database/`, `Windscribe/Models/` |
| Tunnel paths | `Windscribe/Managers/VPN/Utils/ConfigurationsManager.swift`, `VPNUserSettings.swift`, `VPNManagerUtils+IKEV2Credentials.swift` |
| Legacy hub to rebuild later | `Windscribe/ViewControllers/MainViewController/` |

## Verification (across the whole roadmap)

- Each issue ships independently — none of the `main → neo-5.0` issues depend on the v5 release. They land on `main`, ship in a normal release, and flow to `neo-5.0` via the periodic merge.
- Each issue has a "ship it" gate: build clean on all schemes, `fastlane test` passes, lint passes, and where physical hardware testing applies (M1, M4, M6) the three tunnel protocols connect/disconnect cleanly.
- [`../../PROJECT_NEO.md`](../../PROJECT_NEO.md) and [`../../../AGENTS.md`](../../../AGENTS.md) are updated as each issue changes the rules or ships work.
- **Branch hygiene:** `main → neo-5.0` runs at least weekly and after any non-trivial PR lands on `main`. `neo-5.0 → main` runs only at v5.0 launch. A merge that takes more than 30 minutes to resolve is a signal that something Neo-only landed on `main` by mistake — investigate before merging.
- **Cross-agent alignment** is maintained by this in-tree doc surface. Every PR that closes a task updates [`../STATE.md`](../STATE.md) (including which branch it landed on). Every architectural decision is logged in [`../DECISIONS.md`](../DECISIONS.md) as part of the PR that implements it. Private agent memory is for in-flight thinking only — anything another teammate would need is in the repo.
