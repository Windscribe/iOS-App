# M0 — Project Neo Guardrails

GitLab issue: TBD (file under milestone `Project Neo / 5.0`)

## Lands on

`main → neo-5.0`. All M0 work is forward-compatible:

- Docs and lint rules are purely additive.
- The LookAndFeel reference module ships behind `@available(iOS 17.0, *)` and runtime-branches against the existing legacy LookAndFeel — users on iOS 15/16 are unaffected.

## Goal

Make it cheaper for teammates — and their AI agents — to write Neo-shaped code than to copy a legacy pattern. Establishes the rules, the working examples, and the **shared context layer** *before* the rebuild begins.

**Why the shared context layer matters:** Project Neo is multi-contributor and multi-agent. Each teammate runs their own AI assistant, with its own private memory. The only context every agent shares is what's in the repo. So the per-issue plan files, the decision log, the execution state, and the rules all need to live **in tree** — not in any one person's private agent memory. M0 establishes this surface.

## PR breakdown

M0 is intentionally split across multiple PRs. Land them in order; each is independently reviewable and shippable.

| PR | Scope | Tasks |
|---|---|---|
| **PR 1: Shared context layer** | docs only — `docs/PROJECT_NEO.md`, `docs/neo/plans/`, `docs/neo/DECISIONS.md`, `docs/neo/STATE.md`, `AGENTS.md` onramp | T0.1–T0.5 |
| **PR 2: SwiftLint custom rules** | `.swiftlint.yml` `custom_rules:` blocks scoped to `Windscribe/Features/**` and `WindscribeTV/Features/**` | T0.6 |
| **PR 3: LookAndFeel reference module** | move + rebuild on Neo stack, `@available(iOS 17.0, *)`, protocols + adapters, environment values | T0.7–T0.9, T0.12, T0.13 |
| **PR 4: tvOS scaffolding + tvOS doc section** | `WindscribeTV/Features/` + `WindscribeTV/Services/Protocols/` skeletons, "Applying these patterns to tvOS" section | T0.10, T0.11 |

## Tasks

### Shared context layer (PR 1)

- [x] **T0.1** Draft `docs/PROJECT_NEO.md` — manifesto distilled to a 1–2 page contributor + AI-agent rule sheet, with explicit pointers to other Neo docs.
- [x] **T0.2** Create `docs/neo/plans/`. Copy umbrella roadmap as `00-roadmap.md` and the M0 plan as `M0-guardrails.md`. Convention: every issue with active work has its plan here.
- [x] **T0.3** Create `docs/neo/DECISIONS.md`, seed with the four decisions (main launchable / two-track landing; tvOS floor in M1 on neo-5.0; LookAndFeel reference; SwiftLint enforcement).
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

- [ ] **T0.7** Move `LookAndFeelSettingsView` + `LookAndFeelViewModel` to `Windscribe/Features/LookAndFeel/`. Rebuild on the Neo stack: `@Observable` `@MainActor` VM, protocol-injected services, SwiftUI view consuming `@Environment` values, `@available(iOS 17.0, *)`-gated. Keep behavior identical to the current screen for iOS 15/16 via a runtime branch to the legacy module.
- [ ] **T0.8** Stand up `Windscribe/Services/Protocols/` and seed the protocols this module needs (initial set likely: `PreferencesReading`, `LookAndFeelStoring`, `LocalizationProviding` — driven by what the current VM imports). Each protocol gets a thin adapter delegating to the existing Swinject-resolved impl, so the rest of the app is undisturbed.
- [ ] **T0.9** Create `Windscribe/App/Environment+Dependencies.swift` with `@Entry` values for the seeded protocols. Compose at the legacy seam where the LookAndFeel screen is presented.
- [ ] **T0.12** Wire one Swift Testing suite (`WindscribeTests/Features/LookAndFeelTests.swift`) for the reference module — first `import Testing` in the project — and ensure it runs on CI alongside XCTest.
- [ ] **T0.13** Update `AGENTS.md` "Modernization direction" section with a link to the reference module path and a "copy this when starting a new feature" pointer.

### tvOS scaffolding (PR 4)

- [ ] **T0.10** Stand up `WindscribeTV/Features/` and `WindscribeTV/Services/Protocols/` directories (empty placeholders + a brief `README.md` in each pointing at `docs/PROJECT_NEO.md` and the iOS reference module). Apply the same SwiftLint rules from T0.6 to these paths. Cost: minutes; payoff: tvOS contributors aren't blocked waiting for an iOS-side reference if their designs land first.
- [ ] **T0.11** Add an "Applying these patterns to tvOS" section to `docs/PROJECT_NEO.md` covering tvOS-specific affordances (focus engine, `TVNavigationViewStyle`, remote input) on top of the platform-shared Neo stack.

## Verification

- A teammate can copy `Windscribe/Features/LookAndFeel/` to start a new feature without making architectural decisions.
- A teammate's AI agent, given only the repo and no prior session context, can answer "what's Project Neo, what are the rules, what's done, what's next?" by reading `docs/PROJECT_NEO.md` → `docs/neo/DECISIONS.md` → `docs/neo/STATE.md` and the relevant issue plan in `docs/neo/plans/`.
- `fastlane lint` passes; new custom rules don't fire on existing legacy code.
- `fastlane test` passes; the new Swift Testing suite runs on CI alongside XCTest.
- LookAndFeel behaves identically to before on iOS 15/16; new path active on iOS 17+.

## Execution log

Append-only — each commit/merge gets one line. Format: `YYYY-MM-DD — branch — sha7 — summary; next: <what>`.

- 2026-04-30 — `aw/neo-m0-shared-context` — `9dfa0829` — PR 1 (T0.1–T0.5) opened as MR !1334 against `main`. Next: review + merge, then PR 2 (SwiftLint custom rules, T0.6).
- 2026-04-30 — `main` — `0f133586` — PR 1 merged.
- 2026-04-30 — `aw/neo-m0-swiftlint-rules` — `9aab3dc3` — PR 2 (T0.6) opened as MR !1335 against `main`. Next: review + merge, then PR 3 (LookAndFeel reference module).
