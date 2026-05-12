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

- [x] **T6.1** Deleted `Windscribe/Managers/VPN/Utils/VPNManagerUtils+IKEV2Credentials.swift` (!1390, `26b4005d`). The roadmap's premise that this file was a live duplicate of `IKEv2VPNConfiguration.buildProtocol` was incorrect — file was not in `project.pbxproj`'s compile sources, had zero callers, and contained a `userSettings.allowLane` typo (the property is `allowLan`) that would have been a build error if it had ever compiled. Live IKEv2 setup goes through `ConfigurationsManager+config.swift` → `IKEv2VPNConfiguration` → `IKEv2VPNConfiguration.buildProtocol` → `applySettings` (already a single consolidated assembly site).

### PR 2 — SiriIntents target removal (T6.2) (`neo-5.0` only)

- [x] **T6.2** Deleted the `SiriIntents` extension target + its Swift code, `Info.plist`, and entitlements file (!1392, `47eb946d`). The extension's only purpose was hosting `ShowLocationIntentHandler` (SiriKit); `AppIntents/Intents/ShowLocation.swift` already covers the same surface for iOS 16+ via `CustomIntentMigratedAppIntent` (Apple's documented migration seam). **Kept:** `SiriIntents/SiriIntents.xcstrings` and `SiriIntents/{locale}.lproj/SiriOldIntents.*` — these are referenced by the **main app target** for the AppIntents migration (the `.intentdefinition` is compiled by `intentbuilderc` to generate migration class names that `CustomIntentMigratedAppIntent` looks up at runtime). The `SiriIntents/` directory survives as a data-only container; no executable code, no target. pbxproj surgery used the Ruby `xcodeproj` gem after the Python `pbxproj` library mangled 14 unrelated quoted IDs. Team follow-up: regenerate provisioning profiles to drop the `com.windscribe.SiriIntents` bundle ID.

### PR 3 — `#available` cleanup in tunnel code (T6.3) (`neo-5.0` only)

- [x] **T6.3** Verified the cleanup was already done (!1391, `c9d8adf3`). All 7 `#available(iOS 1[5-7]` guards originally targeted (in `VPNManager+ConnectionStatus.swift`, `VPNUserSettings.swift`, `ConfigurationsManager+Connect.swift`) were already removed by M1 PR2 (`fbfa74df`) when the iOS/tvOS deployment floor was lifted to 18. `grep -rn "#available" Windscribe/Managers/VPN/` returns zero. The remaining work was tracking-only — docs-closed via this PR. **Lesson logged:** surveys for `neo-5.0`-only work must run on `neo-5.0`, not `main` — the floor differs.

## Verification

- T6.1: `grep -rn "VPNManagerUtils+IKEV2Credentials" .` returns zero. Build and test suite green on every scheme.
- T6.2: `SiriIntents/` directory gone. Shortcuts that resolved through SiriIntents still resolve via AppIntents (smoke on Siri "Connect Windscribe" + "Show Location" on a device).
- T6.3: No `#available(iOS 15.x)` or `#available(iOS 16.x)` guards remain in tunnel-related files. Hardware smoke clean across all three tunnel protocols.

## Dependencies

- **M1** (#1049, iOS 18 floor on `neo-5.0`) — required for T6.2/T6.3.

## Execution log

Append-only — each commit/merge gets one line. Format: `YYYY-MM-DD — branch — sha7 — summary; next: <what>`.

- 2026-05-11 — `main` — `26b4005d` — PR 1 merged (MR !1390): T6.1. Orphaned `VPNManagerUtils+IKEV2Credentials.swift` deleted; live IKEv2 path through `IKEv2VPNConfiguration.buildProtocol` + `applySettings` confirmed as the single consolidated assembly site. Plan file added with the scope-cut finding documented.
- 2026-05-11 — `neo-5.0` — `ae79ab03` — `main → neo-5.0` periodic merge after T6.1 landed. Three conflicts resolved: orphaned file deletion confirmed, STATE.md status snapshot taken from `main` (M4/M5 closed), M4 plan log kept both `PR 4 opened` and `PR 4 merged` entries.
- 2026-05-11 — `neo-5.0` — `47eb946d` — PR 2 merged (MR !1392): T6.2. SiriIntents extension target deleted via Ruby `xcodeproj` gem (Python `pbxproj` lib mangled 14 unrelated quoted IDs on round-trip — reverted to gem). Removed: PBXNativeTarget + 3 build configs + XCConfigurationList + build phases + 70 build-file refs + Handlers/* + VPN Managers/* + Info.plist + entitlements + main app's dependency + Embed Foundation Extensions reference. Kept: `SiriIntents/SiriIntents.xcstrings` + per-locale `SiriOldIntents.intentdefinition`/`.strings` (needed by the AppIntents migration seam in the main app target). pbxproj SiriIntents refs: 37 → 11. Build clean.
- 2026-05-12 — `neo-5.0` — `c9d8adf3` — PR 3 merged (MR !1391): T6.3. Docs-only — all 7 `#available(iOS 1[5-7]` guards already removed by M1 PR2 (`fbfa74df`) when the iOS/tvOS floor was lifted to 18. Rebased on post-T6.2 `neo-5.0` to drop overlap with PR 2's plan-file edits. **M6 closed (#1054).**
