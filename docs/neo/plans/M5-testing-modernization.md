# M5 — Testing Modernization

GitLab issue: [#1053](https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/1053) (milestone `Project Neo / 5.0`).

## Lands on

`main → neo-5.0`. Swift Testing runs alongside XCTest in the existing `WindscribeTests` target — purely additive. No legacy test rewrites.

## Goal

Make new Neo tests as cheap to write as legacy tests — adopt Swift Testing for new suites, document the small set of mock patterns and the GRDB in-memory fixture pattern that Neo features will reach for, and verify CI surfaces both XCTest and Swift Testing results.

## PR breakdown

Single PR bundling T5.1–T5.3. The work is all purely additive doc/test content — splitting buys nothing and creates merge-conflict surface on `docs/PROJECT_NEO.md`, the plan file, and `docs/neo/STATE.md`.

## Tasks

- [x] **T5.1** Verified CI's `fastlane test` lane collects Swift Testing results alongside XCTest. `lane :test` calls `scan` with `output_types: "junit"`; under Xcode 26.3 `xcodebuild` treats `@Test` suites as first-class XCResult and `fail_build: true` exits non-zero on any Swift Testing failure. The `WindscribeUnitTests.xctestplan` includes the `WindscribeTests` target with no filter excluding `Features/`, so `AboutTests.swift`, `AdapterStreamEquivalenceTests.swift`, `M3ServiceProtocolMockabilityTests.swift`, and the new `MockPatternTests.swift` all run. The GitLab `UnitTest` job relies on the Fastlane exit code for pass/fail. No code change needed.
- [x] **T5.2** `## Testing mocks` section added to `docs/PROJECT_NEO.md` covering the two mock patterns:
  1. **Struct mock with stored callbacks** — cite `MockCredentialStoring` / `MockPreferencesReading` in `WindscribeTests/Features/M3ServiceProtocolMockabilityTests.swift`.
  2. **Actor mock for state** — cite the new `ActorMockCredentialStoring` in `WindscribeTests/Features/MockPatternTests.swift` (added in this PR because no actor mock existed in tree before).
- [x] **T5.3** `## GRDB test fixtures` section added to `docs/PROJECT_NEO.md` documenting the in-memory `DatabaseQueue` pattern. Cites `WindscribeTests/Data/RecordTests/PingDataRecordTests.swift` (record-level) and `WindscribeTests/Data/GRDBLocalDatabaseParityTests.swift` (full-store) as canonical fixtures from M2 D2.2 (!1311). No new test code — the pattern is already established; the doc just makes it discoverable.

## Verification

- Adding a new Swift Testing suite to `WindscribeTests/` shows up in CI's test report alongside XCTest results (T5.1).
- A teammate writing a new Neo feature can read `docs/PROJECT_NEO.md` and write a mock in either pattern by copying the documented shape (T5.2).
- A teammate writing a new GRDB-backed store can read `docs/PROJECT_NEO.md` and stand up an in-memory test fixture by copying the documented pattern (T5.3).
- `swiftlint lint` clean. `fastlane test` green.

## Dependencies

- **M0** (#1048) — Swift Testing suite (`AboutTests.swift`) and the `Windscribe/Features/About/` reference module that the worked mock examples live alongside.
- **M2** (#1050, D2.2) — GRDB in tree (T5.3's worked example).

## Execution log

Append-only — each commit/merge gets one line. Format: `YYYY-MM-DD — branch — sha7 — summary; next: <what>`.

- 2026-05-11 — `aw/neo-m5` — `fd93b530` — Single bundled PR (T5.1 + T5.2 + T5.3) opened as MR !1387 against `main`. Replaces parallel-attempt MRs !1382/!1383/!1384/!1385 (closed as superseded).
- 2026-05-11 — `aw/neo-m5` — `6ca871a3` — Post-push fix: actor mock declared `private(set) var` for the credential properties, which is actor-isolated and can't satisfy `CredentialStoring`'s sync nonisolated getter requirements. CI's test-target build caught it; local `BuildProject` missed it because the Debug scheme's BuildAction excludes `WindscribeTests`. Fix: `let` for immutable properties (implicitly nonisolated on actors); `private(set) var` retained only for `refreshCallCount`. Doc snippet in PROJECT_NEO.md updated with the rule.
- 2026-05-11 — `main` — `d8be3a9e` — !1387 merged. **M5 closed (#1053).** All three tasks landed. Next: M6 (#1054) — tunnel cleanup.
