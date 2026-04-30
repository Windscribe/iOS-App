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

- **Active issue:** M0 — Project Neo Guardrails
- **Active branch:** `aw/neo-m0-shared-context` (PRs against `main`)
- **Blocked on:** —
- **Up next after M0 PR 1 merges:** M0 PR 2 (SwiftLint custom rules)

## Log

- 2026-04-30 — M0 — `aw/neo-m0-shared-context` — `9dfa0829` — PR 1 opened (MR !1334): shared-context layer (T0.1–T0.5). Adds `docs/PROJECT_NEO.md`, `docs/neo/plans/{00-roadmap,M0-guardrails}.md`, `docs/neo/DECISIONS.md`, `docs/neo/STATE.md`, AGENTS.md onramp section. Lands on `main`. Next: review + merge, then PR 2 (SwiftLint custom rules, T0.6).
