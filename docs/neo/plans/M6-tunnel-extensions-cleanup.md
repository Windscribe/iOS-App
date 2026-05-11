# M6 — Tunnel & Extensions Cleanup

GitLab issue: [#1054](https://gitlab.int.windscribe.com/ws/client/iosapp/-/issues/1054) (milestone `Project Neo / 5.0`).

## Lands on

Mixed.

- **T6.1 → `main → neo-5.0`.** Pure-cleanup deletion of dead code. Behavior unchanged on every build.
- **T6.2, T6.3 → `neo-5.0` only.** SiriIntents removal drops Shortcuts support for iOS 15 users (AppIntents requires iOS 16+); tunnel-guard cleanup deletes `#available` branches the legacy floor still needs. Both depend on M1's iOS 18 floor.

## Goal

Apply the iOS 18 floor's affordances to the tunnel code and retire the legacy SiriIntents extension. Each task is small and behavior-preserving — the wins are reduced surface area, fewer `#available` branches to maintain, and one fewer extension target in the project file.

## PR breakdown

Two PRs. They land on different target branches, so they have to be separate.

| PR | Lands on | Scope | Tasks |
|---|---|---|---|
| **PR 1** | `main → neo-5.0` | Delete orphaned `VPNManagerUtils+IKEV2Credentials.swift` — file is not in the Xcode project, has zero callers, and contains a typo (`userSettings.allowLane` — should be `allowLan`) that would have been a build error if it had ever been compiled. This *is* the IKEv2 consolidation: the file was a parallel-implementation draft never wired up; the live path through `IKEv2VPNConfiguration.buildProtocol` (in `VPNUserSettings.swift`) + the `VPNConfiguration` extension's `applySettings` is already a single consolidated assembly site. | T6.1 |
| **PR 2** | `neo-5.0` only | Delete the `SiriIntents` extension target, fold `ShowLocationIntentHandler` into `AppIntents/ShowLocation.swift` if needed, verify provisioning profiles + entitlements. Apply tunnel exclusion flags (`includeAllNetworks`, `excludeLocalNetworks`) unconditionally now that iOS 18 floor is set. | T6.2, T6.3 |

PR 2 depends on M1 (#1049) — the iOS 18 floor — which is already landed on `neo-5.0`. PR 1 has no dependencies and can land any time.

## Tasks

### PR 1 — IKEv2 dead-code deletion (T6.1)

- [ ] **T6.1** Delete `Windscribe/Managers/VPN/Utils/VPNManagerUtils+IKEV2Credentials.swift`. Rationale documented above. The roadmap's premise that this file is a live duplicate of `IKEv2VPNConfiguration.buildProtocol` is incorrect — `grep` for `VPNManagerUtils+IKEV2Credentials` in `Windscribe.xcodeproj/project.pbxproj` returns zero, so the file is not part of any target's compile sources, and `grep -rn "configureIKEV2WithSavedCredentials" Windscribe/` returns only the definition with no callers. Live IKEv2 setup goes through `ConfigurationsManager+config.swift` → `IKEv2VPNConfiguration` value type → `IKEv2VPNConfiguration.buildProtocol` → `applySettings` (the protocol-extension helper). That path stays untouched.

### PR 2 — SiriIntents removal + tunnel-guard cleanup (T6.2, T6.3) (`neo-5.0` only)

- [ ] **T6.2** Delete the `SiriIntents` extension from the Xcode project. `ShowLocationIntentHandler` is the only live handler there; `AppIntents/ShowLocation.swift` already covers the same surface for iOS 16+. The 3 dead files in `SiriIntents/VPN Managers/` go with it.
- [ ] **T6.3** Verify provisioning profiles + entitlements after target removal (no more `com.windscribe.vpn.SiriIntents` bundle ID). Apply tunnel exclusion flags (`includeAllNetworks`, `excludeLocalNetworks`) unconditionally — `#available(iOS 15.1, *)` and `#available(iOS 16.0, *)` guards around them in `VPNUserSettings.swift`'s `applySettings` can be dropped since the floor is now iOS 18. Smoke-test connect/disconnect/Shortcuts on physical hardware (OpenVPN + IKEv2 + WireGuard).

## Verification

- T6.1: `grep -rn "VPNManagerUtils+IKEV2Credentials" .` returns zero. Build and test suite green on every scheme.
- T6.2: `SiriIntents/` directory gone. Shortcuts that resolved through SiriIntents still resolve via AppIntents (smoke on Siri "Connect Windscribe" + "Show Location" on a device).
- T6.3: No `#available(iOS 15.x)` or `#available(iOS 16.x)` guards remain in tunnel-related files. Hardware smoke clean across all three tunnel protocols.

## Dependencies

- **M1** (#1049, iOS 18 floor on `neo-5.0`) — required for T6.2/T6.3.

## Execution log

Append-only — each commit/merge gets one line. Format: `YYYY-MM-DD — branch — sha7 — summary; next: <what>`.
