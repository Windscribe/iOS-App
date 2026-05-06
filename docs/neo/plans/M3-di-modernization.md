# M3 — DI Modernization (constructor injection + `@Environment` shims)

GitLab issue: [#1051](https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/1051) (milestone `Project Neo / 5.0`).

## Lands on

`main → neo-5.0`. All M3 work is forward-compatible:

- The new SwiftLint rule is scoped to `Windscribe/Features/**` and `WindscribeTV/Features/**`, so it only fires inside Neo paths. Legacy code is unaffected.
- The new protocol + adapter shims sit alongside the existing 238-registration Swinject graph. The legacy graph is unchanged; nothing in legacy paths starts importing the new protocols.

## Goal

Stop adding to the Swinject graph. New Neo features consume legacy services via constructor injection + `@Environment(@Entry)`-injected protocols. The composition seam — the one place a feature's protocol is bound to its legacy implementation — lives in `Windscribe/App/Environment+Dependencies.swift`. Inside a Feature module, `Assembler.resolve` is forbidden by lint and unnecessary.

The five protocols this issue seeds (`VPNConnecting`, `ServerProviding`, `CredentialStoring`, `PreferencesReading`, `SessionProviding`) are intentionally **minimal**. They cover the surface Neo features are likely to consume in M7–M9, not the full surface of the legacy types they wrap. Each protocol grows lazily — when a feature needs another method, the feature's PR adds it.

## Boundary policy

The pattern, restated for the protocols this issue introduces:

```
Feature/<Name>/View.swift           ← @Environment(\.someService) var service
Feature/<Name>/ViewModel.swift      ← init(someService: any SomeServicing)
Services/Protocols/SomeServicing.swift   ← protocol + Legacy<Some> adapter (thin)
App/Environment+Dependencies.swift  ← @Entry var someService: any SomeServicing
                                       = Legacy<Some>(legacy: Assembler.resolve(LegacyType.self))
```

- Adapters are **delegation only**. No business logic, no caching, no ordering changes. If you find yourself adding logic to an adapter, the protocol surface is wrong — refine it instead.
- Adapters live next to the protocol they implement (single file: `Services/Protocols/<Name>ing.swift`).
- The `@unchecked Sendable` escape hatch is allowed for adapters whose underlying legacy service isn't yet `Sendable`-marked. Annotate with the same comment shape as `LegacyLookAndFeelObserver` (link to the underlying legacy type, note when the unchecked annotation can be dropped).
- Combine subjects on the legacy side become `AsyncStream` on the Neo side (the M0 `LookAndFeelObserving` adapter is the reference for this conversion).

## PR breakdown

Single PR. Everything in M3 is small and additive — the lint rule, the five protocol files, the `Environment+Dependencies.swift` expansion, and the adapter tests all hang together as one reviewable unit. Splitting was considered (lint rule first, seam second) but rejected: the lint rule has zero violations to fix, the seam has no behavioral risk, and the M0 work already established the pattern, so a teammate reviewing one half without the other adds friction without reducing risk.

## Tasks

### Lint rule

- [x] **T3.4** Add `custom_rules.neo_no_assembler_resolve` to `.swiftlint.yml`. Regex: `\bAssembler\s*\.\s*resolve\b`. Scope: `Windscribe/Features/**` and `WindscribeTV/Features/**`. Severity: error. Verify with a probe file under `Windscribe/Features/__SmokeTest__/` that the rule fires; verify zero violations in current `Features/**` tree.

  Note: `import Swinject` is already forbidden in `Features/**` (M0 PR 2). The new rule is belt-and-braces — it catches the case where someone re-exports `Assembler` through a non-Swinject import or a `typealias`, and gives a more specific error message pointing at the right migration path.

### Service protocol seam

- [x] **T3.1** Confirm the legacy types each protocol wraps (already mapped during planning):

  | Neo protocol | Legacy type | Source file |
  |---|---|---|
  | `VPNConnecting` | `VPNManager` | `Windscribe/Managers/VPN/VPNManager.swift` |
  | `ServerProviding` | `LocationListRepository` | `Windscribe/Repository/Locations and Servers/LocationListRepository.swift` |
  | `CredentialStoring` | `CredentialsRepository` | `Windscribe/Repository/Credentials/CredentialsRepository.swift` |
  | `PreferencesReading` | `Preferences` | `Windscribe/Data/Preferences/Preferences.swift` |
  | `SessionProviding` | `UserSessionRepository` | `Windscribe/Repository/User/UserSessionRepository.swift` |

- [x] **T3.2** Write protocol + adapter for each, in the order above. Initial surfaces (deliberately minimal — grow per-feature):

  ```swift
  protocol VPNConnecting: Sendable {
      func connect(locationId: String, proto: ProtocolPort) async throws
      func disconnect() async throws
  }
  // Status-stream surface lives in M4 (T4.2 — AsyncStream over NEVPNStatusDidChange).

  protocol ServerProviding: Sendable {
      var locations: [LocationModel] { get }
      var locationUpdates: AsyncStream<[LocationModel]> { get }
  }

  protocol CredentialStoring: Sendable {
      var openVPNCredentials: ServerCredentialsModel? { get }
      var ikev2Credentials: ServerCredentialsModel? { get }
      func refreshCredentials() async throws
  }

  protocol PreferencesReading: Sendable {
      var killSwitchEnabled: Bool { get }
      var allowLAN: Bool { get }
      var selectedProtocol: String? { get }
      var selectedPort: String? { get }
  }

  protocol SessionProviding: Sendable {
      var session: SessionModel? { get }
      var sessionUpdates: AsyncStream<SessionModel?> { get }
  }
  ```

  Each adapter:
  - Holds `let legacy: <LegacyType>`.
  - Delegates synchronously where possible.
  - Wraps `CurrentValueSubject` / `PassthroughSubject` with the same `AsyncStream { continuation in legacy.subject.sink { … } }` shape as `LegacyLookAndFeelObserver`.
  - Is `@unchecked Sendable` only if the underlying legacy type isn't `Sendable`. Document the reason inline, mirroring `LegacyLookAndFeelObserver`.

- [x] **T3.3** Add five `@Entry` slots to `Windscribe/App/Environment+Dependencies.swift`, each defaulting to the corresponding `Legacy*` adapter resolved through `Assembler.resolve`. The composition seam (`Windscribe/App/`) is outside `Features/**` and is the only place `Assembler.resolve` should appear in Neo code.

- [x] **T3.5** Swift Testing coverage in `WindscribeTests/Features/`:
  - One test per Combine→AsyncStream conversion: feed a value into a fake legacy publisher, confirm the adapter's `AsyncStream` yields it.
  - Mock-injection sanity for one VM: verify a feature can be constructed with mock implementations of all five protocols and exercise its observable surface without touching `Assembler`.

  This is calibration as much as coverage — if writing the test for an adapter feels mechanical, the protocol surface is right; if it feels awkward, the surface is wrong and we refine before merging.

## Verification

- `grep -rn "Assembler.resolve" Windscribe/Features/ WindscribeTV/Features/` returns zero.
- `grep -rn "import Swinject" Windscribe/Features/ WindscribeTV/Features/` returns zero (already enforced; reverify post-PR-2).
- M0 reference module (`Windscribe/Features/About/`) has no Swinject reference anywhere in its files (already true; reverify).
- `fastlane lint` passes; new `neo_no_assembler_resolve` rule fires on a probe file (deleted before commit), doesn't fire on real `Features/**` content.
- `fastlane test` passes; new Swift Testing suites for the adapters' Combine→AsyncStream wrappers land green.
- Each protocol's adapter is ≤50 lines; if any exceeds that, audit for delegation-only-ness.

## Execution log

Append-only — each commit/merge gets one line. Format: `YYYY-MM-DD — branch — sha7 — summary; next: <what>`.

- 2026-05-06 — `aw/neo-m3-di-shims` — `a29f935a` — Single PR landing T3.1–T3.5 opened as MR !1361 against `main`: lint rule `neo_no_assembler_resolve`, five protocols + adapters in `Windscribe/Services/Protocols/`, five `@Entry` slots in `Environment+Dependencies.swift`, `M3ServiceProtocolMockabilityTests` (5 tests), general `@unchecked Sendable` rationale documented in `docs/PROJECT_NEO.md`. Build clean; 18/18 tests pass (5 new + 13 M0 About). Lint clean. Acceptance grep: zero `Assembler.resolve` and zero `import Swinject` in `Features/**`. Next: review + merge → close M3.
- 2026-05-06 — `main` — `ba1c1bee` — !1361 merged. **M3 closed (#1051).** Five service-protocol shims live; `Assembler.resolve` lint-forbidden in `Features/**`. PR also folded in: M0/M3 file-header normalization, `## Routing` section in `docs/PROJECT_NEO.md` (Screen/View/Route convention), rename `AboutView` → `AboutScreen` + inner View rename, M4 cleanup tracked as T4.5 in #1052 / Notion. Next: M4 (#1052).
