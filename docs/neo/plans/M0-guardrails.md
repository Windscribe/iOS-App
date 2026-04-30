# M0 — Project Neo Guardrails

GitLab issue: [#1048](https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/1048) (milestone `Project Neo / 5.0`).

## Lands on

`main → neo-5.0`. All M0 work is forward-compatible:

- Docs and lint rules are purely additive.
- The About reference module ships behind `@available(iOS 17.0, *)` and runtime-branches against the existing legacy About — users on iOS 15/16 are unaffected.

## Goal

Make it cheaper for teammates — and their AI agents — to write Neo-shaped code than to copy a legacy pattern. Establishes the rules, the working examples, and the **shared context layer** *before* the rebuild begins.

**Why the shared context layer matters:** Project Neo is multi-contributor and multi-agent. Each teammate runs their own AI assistant, with its own private memory. The only context every agent shares is what's in the repo. So the per-issue plan files, the decision log, the execution state, and the rules all need to live **in tree** — not in any one person's private agent memory. M0 establishes this surface.

## PR breakdown

M0 is intentionally split across multiple PRs. Land them in order; each is independently reviewable and shippable.

| PR | Scope | Tasks |
|---|---|---|
| **PR 1: Shared context layer** | docs only — `docs/PROJECT_NEO.md`, `docs/neo/plans/`, `docs/neo/DECISIONS.md`, `docs/neo/STATE.md`, `AGENTS.md` onramp | T0.1–T0.5 |
| **PR 2: SwiftLint custom rules** | `.swiftlint.yml` `custom_rules:` blocks scoped to `Windscribe/Features/**` and `WindscribeTV/Features/**` | T0.6 |
| **PR 3: About reference module** | move + rebuild on Neo stack, `@available(iOS 17.0, *)`, protocols + adapters, environment values | T0.7–T0.9, T0.12, T0.13 |
| **PR 4: tvOS scaffolding + scheme wiring + tvOS doc section** | `WindscribeTV/Features/` + `WindscribeTV/Services/Protocols/` skeletons; app schemes (Windscribe-Debug/Staging/Release) wired to run `WindscribeTests` so cmd+U works from any scheme; "Applying these patterns to tvOS" section | T0.10, T0.11, T0.14 |

## Tasks

### Shared context layer (PR 1)

- [x] **T0.1** Draft `docs/PROJECT_NEO.md` — manifesto distilled to a 1–2 page contributor + AI-agent rule sheet, with explicit pointers to other Neo docs.
- [x] **T0.2** Create `docs/neo/plans/`. Copy umbrella roadmap as `00-roadmap.md` and the M0 plan as `M0-guardrails.md`. Convention: every issue with active work has its plan here.
- [x] **T0.3** Create `docs/neo/DECISIONS.md`, seed with the four decisions (main launchable / two-track landing; tvOS floor in M1 on neo-5.0; LookAndFeel reference — later superseded by ND-005 → About; SwiftLint enforcement).
- [x] **T0.4** Create `docs/neo/STATE.md` with first entry ("M0 in progress; foundation work landing on `main`").
- [x] **T0.5** Update `AGENTS.md` with an "AI agent onramp" section: read order is `PROJECT_NEO.md` → `DECISIONS.md` → `STATE.md` → relevant issue plan. Decisions and per-issue plans belong in tree, not in any agent's private memory.

### Lint enforcement (PR 2)

- [x] **T0.6** Add `custom_rules:` blocks to `.swiftlint.yml` scoped to `Windscribe/Features/**` and `WindscribeTV/Features/**`. Forbid:
  - `import Swinject` ✓
  - `import SnapKit` ✓ (legacy paths outside Features/ are unaffected by virtue of `included:` scoping)
  - `ObservableObject`, `@Published`, `@StateObject`, `@ObservedObject` ✓
  - `import RealmSwift` ✓ (`Data/Database/**` is unaffected by virtue of `included:` scoping)
  - `static let shared` (also matches `static var shared`) ✓
  - `import Combine` ✓
  - `class X: UIViewController` (subclass declarations) ✓

  Verified rules don't fire on existing legacy code (0 violations across the tree). Verified all 10 rules trigger on a probe file under `Windscribe/Features/__SmokeTest__/` (probe deleted; not committed).

### Reference module (PR 3)

- [x] **T0.7** `AboutView` + `AboutViewModel` added under `Windscribe/Features/About/`, `@available(iOS 17.0, *)`-gated. The legacy `AboutSettingsView` is preserved unchanged and remains the iOS 15/16 path; `PreferencesNavigationRouter` seam runtime-branches.
- [x] **T0.8** `Windscribe/Services/Protocols/LookAndFeelObserving.swift` added (protocol + `LegacyLookAndFeelObserver` adapter wrapping `LookAndFeelRepositoryType.isDarkModeSubject` as `AsyncStream<Bool>`). `LoggingService` deferred to a later feature: the legacy About VM held a `FileLogger` reference but never invoked it, so the migrated VM dropped the unused dep — it'll land with M7 or whichever feature genuinely needs logging.
- [x] **T0.9** `Windscribe/App/Environment+Dependencies.swift` added with `@Entry var lookAndFeel`, defaulting to the Swinject-resolved legacy adapter.
- [x] **T0.12** `WindscribeTests/Features/AboutTests.swift` — first Swift Testing suite in the project (6 tests, 13 parameterised cases). WindscribeTests deployment target bumped from iOS 15 to 17 (test-target only — production stays at 15) because Swift Testing's `@Suite`/`@Test` macros refuse to compose with stricter `@available` annotations.
- [x] **T0.13** `AGENTS.md` "Modernization direction" updated with a "Canonical reference module" callout pointing at `Windscribe/Features/About/`.

### tvOS scaffolding + scheme wiring (PR 4)

- [x] **T0.10** `WindscribeTV/Features/` and `WindscribeTV/Services/Protocols/` directories created with `README.md` files pointing at `docs/PROJECT_NEO.md` and the iOS About reference module. SwiftLint custom rules from T0.6 already match `(Windscribe|WindscribeTV)/Features/` so they apply automatically — verified by probe (`import Swinject`, `import Combine`, `: UIViewController` all flagged as expected).
- [x] **T0.11** "Applying these patterns to tvOS" section in `docs/PROJECT_NEO.md` updated with explicit pointers to the now-existing `WindscribeTV/Features/` and `WindscribeTV/Services/Protocols/` directories, covering focus engine, remote input, layout, and navigation affordances.
- [x] **T0.14** `Windscribe-Debug.xcscheme`, `Windscribe-Staging.xcscheme`, and `Windscribe-Release.xcscheme` each have `<TestPlans>` referencing `WindscribeUnitTests.xctestplan` plus a `<Testables>` block referencing `WindscribeTests.xctest`. Verified: `xcodebuild -showTestPlans` resolves `WindscribeUnitTests` on all three; `xcodebuild test -only-testing:WindscribeTests/EmergencyRepositoryTests` from `Windscribe-Debug` runs 9 tests as expected. (tvOS schemes are skipped — they need a separate tvOS test target first, which doesn't exist yet; that lands in M9 or its precursor work.)

## Verification

- A teammate can copy `Windscribe/Features/About/` to start a new feature without making architectural decisions.
- A teammate's AI agent, given only the repo and no prior session context, can answer "what's Project Neo, what are the rules, what's done, what's next?" by reading `docs/PROJECT_NEO.md` → `docs/neo/DECISIONS.md` → `docs/neo/STATE.md` and the relevant issue plan in `docs/neo/plans/`.
- `fastlane lint` passes; new custom rules don't fire on existing legacy code.
- `fastlane test` passes; the new Swift Testing suite runs on CI alongside XCTest.
- About behaves identically to before on iOS 15/16; new path active on iOS 17+.

## Execution log

Append-only — each commit/merge gets one line. Format: `YYYY-MM-DD — branch — sha7 — summary; next: <what>`.

- 2026-04-30 — `aw/neo-m0-shared-context` — `9dfa0829` — PR 1 (T0.1–T0.5) opened as MR !1334 against `main`. Next: review + merge, then PR 2 (SwiftLint custom rules, T0.6).
- 2026-04-30 — `main` — `0f133586` — PR 1 merged.
- 2026-04-30 — `aw/neo-m0-swiftlint-rules` — `9aab3dc3` — PR 2 (T0.6) opened as MR !1335 against `main`. Next: review + merge, then PR 3 (About reference module).
- 2026-04-30 — `main` — `6b9a6f09` — PR 2 merged.
- 2026-04-30 — `aw/neo-m0-about-reference` — `<staged>` — PR 3 in progress. Reference module switched LookAndFeel→About per ND-005 (LookAndFeel was 374 lines + 7 deps; too heavy for M0's "copy-paste template" goal — moves to M7 candidate). All in-tree docs, GitLab issue #1048, and Notion artifact synced.
- 2026-04-30 — `aw/neo-m0-about-reference` — `929bce27` — PR 3 (T0.7–T0.9, T0.12, T0.13) opened as MR !1337 against `main`. All 6 AboutViewModelTests pass on iPhone 17 simulator. Next: review + merge, then PR 4 (tvOS scaffolding, T0.10/T0.11).
