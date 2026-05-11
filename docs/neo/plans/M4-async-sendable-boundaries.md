# M4 — Async/Sendable Boundaries

GitLab issue: [#1052](https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/1052) (milestone `Project Neo / 5.0`).

## Lands on

Mixed.

- **T4.1, T4.2, T4.4, T4.5 → `main → neo-5.0`.** Wrapping concrete types in protocols, adding an `AsyncStream` surface alongside the existing Combine surface, documenting the conversion guideline, and replacing `@unchecked Sendable` workarounds with proper conformance are all forward-compatible.
- **T4.3 → `neo-5.0` only.** The async overrides for `startTunnel` / `stopTunnel` / `sleep` / `handleAppMessage` only become available with iOS 18 lifecycle changes from M1; landing them on `main` would break tunnel compilation against the iOS 15 floor.

## Goal

Convert the Apple-API and WSNet boundaries that Neo features will consume so feature code never sees Combine or completion handlers. By the end of M4, a feature module can `for await status in vpn.status` and `for await locations in servers.locationUpdates` without `import Combine`, mock the WSNet types in tests via protocols, and trust that the legacy-adapter `@unchecked Sendable` workarounds M3 introduced have been retired.

## PR breakdown

Four PRs. T4.1 + T4.4 ride together because the doc guideline and the first WSNet protocol-wrap are mutually reinforcing — the wrap exemplifies the guideline, and the guideline names the wrap.

| PR | Lands on | Scope | Tasks |
|---|---|---|---|
| **PR 1** | `main → neo-5.0` | WSNet protocol wrappers (`WSNetServerAPI`, `WSNetPingManager`) + DI site updates + the `Combine → AsyncSequence` doc guideline | T4.1, T4.4 |
| **PR 2** | `main → neo-5.0` | `VPNConnecting.statusUpdates: AsyncStream<VPNConnectionState>` wrapping `NEVPNStatusDidChange` | T4.2 |
| **PR 3** | `main → neo-5.0` | Retire the M3 `@unchecked Sendable` exemption — proper Sendability on the six legacy protocols + four legacy value-type structs; remove the retroactive extensions and the `docs/PROJECT_NEO.md` subsection | T4.5 |
| **PR 4** | `neo-5.0` only | Tunnel async lifecycle overrides (`startTunnel` / `stopTunnel` / `sleep` / `handleAppMessage`) in `PacketTunnel` and `WireGuardTunnel` | T4.3 |

PR 3 (Sendability cleanup) can land in any order relative to PR 1 / PR 2; it's an independent track. PR 4 (`neo-5.0` only) waits on whichever of PR 1–3 are pre-requisites in practice — none are strict dependencies, but landing the `main`-track PRs first means the periodic `main → neo-5.0` merge keeps the integration branch in sync without conflicts.

## Tasks

### PR 1 — WSNet protocol wrappers + Combine→AsyncSequence guideline

- [x] **T4.1** Wrap `WSNetServerAPI` and `WSNetPingManager` in Swift protocols, parallel to the existing `WSNetBridgeAPIType`. Update DI sites in `Managers/VPN/ControlPlane.swift` and `Managers/Latency/LocalPingManager.swift`. Concrete impls remain on the legacy types; tests get mocks.
- [x] **T4.4** Append a "Converting Combine to AsyncSequence" section to `docs/PROJECT_NEO.md` covering: when to use `.values`, the `AsyncStream { continuation in subject.sink { yield } }` pattern (M0's `LegacyLookAndFeelObserver` is the worked example), and the rule for where Combine is allowed (boundary adapters in `Services/Protocols/`, never inside a Feature).

### PR 2 — VPN status AsyncStream

- [x] **T4.2** Add `var statusUpdates: AsyncStream<VPNConnectionState> { get }` to `VPNConnecting` (M3 introduced the protocol commands-only on purpose). Adapter wraps `NEVPNStatusDidChange` notifications + the legacy `VPNManager`'s connection-state surface. Verify a feature can subscribe via `for await status in vpn.statusUpdates` without `import Combine`.

### PR 3 — Retire M3's `@unchecked Sendable` exemption

- [x] **T4.5** Replace the M3 stopgap with proper Sendability. Concrete steps:
  - Mark these legacy protocols `Sendable` directly: `VPNManager`, `LocationListRepository`, `CredentialsRepository`, `Preferences`, `UserSessionRepository`, `LookAndFeelRepositoryType`. Drop `@unchecked` from `LegacyVPNConnector`, `LegacyServerProvider`, `LegacyCredentialStore`, `LegacyPreferencesReader`, `LegacySessionProvider`, and M0's `LegacyLookAndFeelObserver`.
  - Move retroactive `@unchecked Sendable` extensions on `LocationModel`, `DatacenterModel`, `SessionModel`, `ServerCredentialsModel` (currently at the bottom of the M3 protocol files in `Windscribe/Services/Protocols/`) to direct `Sendable` conformance on each type's definition file.
  - Delete the "@unchecked Sendable is allowed at the legacy-adapter seam" subsection from `docs/PROJECT_NEO.md` once the workarounds are gone.
  - Each legacy protocol/struct may surface its own Sendability gaps when marked `Sendable` directly (non-Sendable stored properties, etc.). Fix in-place per type — don't introduce new `@unchecked` workarounds. If a fix needs an `actor` boundary, that's M4 work, not deferred.

### PR 4 — Tunnel async lifecycle (`neo-5.0` only)

- [x] **T4.3** Convert `startTunnel(options:completionHandler:)`, `stopTunnel(with:completionHandler:)`, `sleep(completionHandler:)`, and `handleAppMessage(_:completionHandler:)` to async overrides in both `PacketTunnel/PacketTunnelProvider.swift` and `WireGuardTunnel/PacketTunnelProvider.swift`. Smoke-test on physical hardware: connect / disconnect / sleep on each of the three tunnel protocols (OpenVPN, IKEv2, WireGuard).

## Verification

- A Neo feature module can `for await status in vpn.statusUpdates` without `import Combine` (T4.2).
- A Neo feature module can `for await locations in servers.locationUpdates` and `for await session in session.sessionUpdates` without `import Combine` — already true from M3, reverified after PR 3.
- WSNet types are mockable in tests via the new protocols (T4.1).
- `grep -rn "@unchecked Sendable" Windscribe/Services/Protocols/` returns zero (T4.5).
- Tunnel logs show no behavior regression on physical hardware across all three tunnel protocols (T4.3).
- `swiftlint lint` clean. `fastlane test` green.

## Dependencies

- **M0** (canonical reference module + `LegacyLookAndFeelObserver` whose `@unchecked Sendable` is dropped in T4.5).
- **M1** (iOS 18 floor — required for T4.3's tunnel async overrides).
- **M3** (#1051) (the five protocol shims whose `@unchecked Sendable` markers are dropped in T4.5; `VPNConnecting` is extended in T4.2).

## Execution log

Append-only — each commit/merge gets one line. Format: `YYYY-MM-DD — branch — sha7 — summary; next: <what>`.

- 2026-05-07 — `aw/neo-m4-wsnet-wrappers` — `e614ddcc` — PR 1 opened (MR !1365): T4.1 + T4.4. `WSNetServerAPIType` (40 methods) + `WSNetPingManagerType` (1 method) protocols added in `Windscribe/API/WSNet Protocol/`; concrete classes conform via empty extension. All consumers (`APIManagerImpl`, `WireguardAPIManagerImpl`, `ControlPlane`, `LocalPingManagerImpl`, `PacketTunnel`/`WireGuardTunnel` providers, `ContainerResolver`, `ShowLocationIntentHandler`) and DI sites (`CoreModule`, `WireguardModule`, `AppModulesCommon`) updated. `docs/PROJECT_NEO.md` gains the "Converting Combine to AsyncSequence" guideline and codifies the protocol-naming convention (`*ing` for capability, `*Type` for legacy Obj-C bridge mirrors only). Build clean; 18/18 Neo tests pass. Lands on `main`. Next: review + merge → PR 2 (T4.2 — `VPNConnecting.statusUpdates` AsyncStream).
- 2026-05-07 — `main` — `507d8c01` — PR 2 merged (MR !1371): T4.2. `VPNConnecting` grows `var statusUpdates: AsyncStream<VPNConnectionState>` sourced from `VPNStateRepository.vpnInfo` (the legacy `CurrentValueSubject` fed by `NEVPNStatusDidChange` notifications). `LegacyVPNConnector` takes `stateRepository: VPNStateRepository` at composition; `Environment+Dependencies.swift` resolves it. `AdapterStreamEquivalenceTests` extended with 3 VPN tests (initial-when-nil, initial-when-seeded, ordered updates), mutation-verified. `.swiftlint.yml` `.claude` exclusion folded in to keep agent worktrees out of lint scope. Build clean; 28/28 Neo tests pass.
- 2026-05-08 — `main` — `e1c86ba5` — PR 3 merged (MR !1369): T4.5. `@unchecked Sendable` retired from all 6 `Legacy*` adapters; 7 legacy protocols (`LookAndFeelRepositoryType`, `Preferences`, `CredentialsRepository`, `VPNManager`, `LocationListRepository`, `UserSessionRepository`, `VPNStateRepository`) now `Sendable` directly; 4 retroactive value-type conformances moved to definition files; `@unchecked Sendable` doc subsection deleted from `docs/PROJECT_NEO.md`. `grep -rn "@unchecked Sendable" Windscribe/Services/Protocols/` returns zero. **M4 PR1–PR3 all on `main`.** Remaining: PR 4 (T4.3 — tunnel async lifecycle, `neo-5.0` only).
- 2026-05-11 — `neo-5.0` — `e5259595` — PR 4 merged (MR !1379): T4.3. `startTunnel` / `stopTunnel` / `sleep` / `handleAppMessage` converted to async overrides in both `PacketTunnel/PacketTunnelProvider.swift` and `WireGuardTunnel/PacketTunnelProvider.swift`. PacketTunnel start/stop bridge via `withCheckedThrowingContinuation` to private `*Internal` helpers, preserving the existing delegate-driven completion flow. Vestigial `stopHandler` property + paired `.disconnected` branch dropped (existed only to absorb pre-existing duplicate `completionHandler()` call). WireGuardTunnel: same continuation-wrap pattern; dead `#if os(macOS) exit(0)` template hack removed. Hardware smoke test passed across OpenVPN, IKEv2, WireGuard. **M4 closed (#1052).** All five M4 tasks (T4.1–T4.5) landed: PRs 1–3 on `main`, PR 4 on `neo-5.0`. Next: M5 (#1053) — Testing modernization (Swift Testing adoption + mock patterns), `main → neo-5.0`.
