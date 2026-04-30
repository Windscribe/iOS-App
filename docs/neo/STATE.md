# Project Neo — Execution Log

> **Append-only.** One line per merge, newest at the bottom. Format:
>
> ```
> YYYY-MM-DD — M<N> — <branch> — <sha7> — <one-line summary>; next: <what's next>
> ```
>
> A fresh contributor (or AI agent) reading from the bottom of this file can answer "where are we?" without needing chat history. See [`PROJECT_NEO.md`](../PROJECT_NEO.md) for rules and [`plans/00-roadmap.md`](plans/00-roadmap.md) for the issue list.

---

## Status snapshot

- **Active issue:** M0 — Project Neo Guardrails (#1048)
- **Active branch:** `aw/neo-m0-tvos-scaffolding` (PR 4 in flight)
- **Blocked on:** —
- **Up next after M0 PR 4 merges:** M0 closed; M1 (iOS 18 / tvOS 18 floor + Swift 6-ready settings) lands on `neo-5.0` only.

## Log

- 2026-04-30 — M0 — `aw/neo-m0-shared-context` — `9dfa0829` — PR 1 opened (MR !1334): shared-context layer (T0.1–T0.5). Adds `docs/PROJECT_NEO.md`, `docs/neo/plans/{00-roadmap,M0-guardrails}.md`, `docs/neo/DECISIONS.md`, `docs/neo/STATE.md`, AGENTS.md onramp section. Lands on `main`. Next: review + merge, then PR 2 (SwiftLint custom rules, T0.6).
- 2026-04-30 — M0 — `main` — `0f133586` — PR 1 merged. Foundation context layer in tree.
- 2026-04-30 — M0 — `aw/neo-m0-swiftlint-rules` — `9aab3dc3` — PR 2 opened (MR !1335): SwiftLint custom rules (T0.6). Adds 10 `custom_rules:` to `.swiftlint.yml` scoped to `Windscribe/Features/**` and `WindscribeTV/Features/**`. Verified zero violations on existing code; all 10 rules fire on a probe file (since deleted). Lands on `main`. Next: review + merge, then PR 3.
- 2026-04-30 — M0 — `main` — `6b9a6f09` — PR 2 merged.
- 2026-04-30 — M0 — decision change — ND-005 supersedes ND-003: M0's canonical reference module switches from LookAndFeel to About. Reading the actual LookAndFeel code revealed it was much heavier than the planning doc assumed (374-line VM, 7 deps, sub-router, file I/O); About (57+48 lines, 2 deps, one Combine binding, sheet presentation) better fits M0's "low blast radius, copy-paste-ready template" goal. LookAndFeel becomes a candidate for M7's recipe-validation. M0 plan, PROJECT_NEO.md, 00-roadmap.md, DECISIONS.md, GitLab issue #1048, and the Notion artifact all updated in the same change.
- 2026-04-30 — M0 — `aw/neo-m0-about-reference` — `929bce27` — PR 3 opened (MR !1337): About reference module (T0.7, T0.8, T0.9, T0.12, T0.13). Adds `Windscribe/Features/About/{AboutView,AboutViewModel}.swift`, `Windscribe/Services/Protocols/LookAndFeelObserving.swift`, `Windscribe/App/Environment+Dependencies.swift`, `WindscribeTests/Features/AboutTests.swift` (first Swift Testing suite). Seam: `PreferencesNavigationRouter` runtime-branches `if #available(iOS 17.0, *)`. WindscribeTests deployment target bumped 15.0→17.0 (test-target only). All 6 new tests + 13 parameterised cases pass on iPhone 17 simulator. Lands on `main`. Next: review + merge, then PR 4 (tvOS scaffolding, T0.10/T0.11).
- 2026-04-30 — M0 — `main` — `b87bf180` — PR 3 merged.
- 2026-04-30 — M0 — `aw/neo-m0-tvos-scaffolding` — `<staged>` — PR 4 in progress: tvOS scaffolding + tvOS doc section + scheme wiring (T0.10, T0.11, T0.14). Adds `WindscribeTV/Features/` and `WindscribeTV/Services/Protocols/` with `README.md` placeholders pointing at `docs/PROJECT_NEO.md` and the iOS About reference. SwiftLint custom rules already match `(Windscribe|WindscribeTV)/Features/.*\.swift` so they apply automatically — verified by probe. `docs/PROJECT_NEO.md` "Applying these patterns to tvOS" section now has explicit pointers to the new directories. `Windscribe-Debug.xcscheme`, `Windscribe-Staging.xcscheme`, `Windscribe-Release.xcscheme` each get a populated `<TestAction>` (TestPlans + Testables) so cmd+U works from any scheme. Lands on `main`. Next: open MR + review + merge → close M0.
