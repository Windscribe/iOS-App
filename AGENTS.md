# AGENTS.md

Operating notes for AI agents working in this repo. Humans want `README.md`.

## TL;DR

Windscribe iOS/tvOS VPN client. Multi-target Xcode project (no workspace, no Tuist). The codebase is **mid-migration**: UIKit+Combine+Swinject+Realm is the current shore, SwiftUI+async/await+constructor-injection+GRDB is the far shore. **When you touch existing code, match its style. When you write new code, steer toward the target state** — see [Modernization direction](#modernization-direction) below.

Do not mass-migrate existing screens. The UI is being rebuilt screen-by-screen; out-of-band rewrites create merge pain.

## Repository layout

```
iosapp/
├── Windscribe.xcodeproj/            # Single project, all targets live here
├── Windscribe/                      # Main iOS app target
│   ├── AppDelegate.swift            # @main, resolves services via Assembler.resolve
│   ├── SceneDelegate.swift
│   ├── Dependencies/                # Swinject DI wiring
│   │   ├── Assembler.swift          #   static `resolve<T>()` entry point
│   │   ├── CoreModule.swift         #   core services shared with extensions
│   │   ├── UserScope.swift          #   per-user (login-scoped) services
│   │   ├── WireguardModule.swift
│   │   └── AppModules/iOS/          #   iOS-specific registrations (VMs, routers, VCs)
│   ├── Router/                      # UIKit coordinator-style navigation
│   │   └── NavigationRouter/        #   SwiftUI navigation bridge (newer screens)
│   ├── ViewControllers/             # Legacy UIKit screens — MainViewController is the hub
│   ├── View/CustomViews/            # Shared UIKit subclasses (WSView, WSButton, etc.)
│   ├── Modules/                     # Newer, module-scoped features (SwiftUI-forward)
│   │   ├── Authentication/          #   Welcome, Login, SignUp, EmergencyConnect (SwiftUI + Combine VMs)
│   │   ├── News Feed/
│   │   ├── PlanUpgrade/
│   │   ├── Popup/
│   │   └── Preferences/             #   Settings surface, SwiftUI
│   ├── Managers/                    # Cross-cutting services (VPN, Session, Latency, …)
│   │   └── Protocols/               #   Manager protocols — inject these, not impls
│   ├── Repository/                  # Feature-scoped state/logic (one dir per domain)
│   ├── API/                         # Wrapper around the WSNet xcframework
│   │   ├── APIManager*.swift        #   public-facing async API surface
│   │   └── WSNet Protocol/          #   low-level wsnet bindings
│   ├── Data/
│   │   ├── Database/                #   Realm-backed LocalDatabase — target is GRDB
│   │   ├── FileDatabase/            #   on-disk blobs (server lists, logs)
│   │   ├── KeyChainDatabase/        #   credentials, session keys
│   │   └── Preferences/             #   UserDefaults wrapper (shared app group)
│   ├── Models/                      # Plain + Realm object models (mixed)
│   ├── Constants/                   # AppConstants, UIConstants, VPNProtocols, Enums, etc.
│   ├── Environments/
│   │   ├── Config.xcconfig          #   team ID, bundle IDs (override locally, don't commit)
│   │   └── Plists/                  #   Info.plist variants per scheme
│   └── Supporting Files/            # Assets, fonts, localization, Core Data model
├── WindscribeTV/                    # tvOS target — separate UI, shares Managers/Repo/API
├── PacketTunnel/                    # Network Extension: OpenVPN + IKEv2 provider
├── WireGuardTunnel/                 # Network Extension: WireGuard + AmneziaWG provider
│   └── Custom/                      #   amneziawg glue, x25519, bridging header
├── SiriIntents/                     # Legacy SiriKit intent handlers (Intents.framework)
├── AppIntents/                      # Modern AppIntents (iOS 16+) — Shortcuts entry points
├── HomeWidget/                      # WidgetKit extension (SwiftUI)
├── WindscribeTests/                 # XCTest unit tests + Mocks
├── libs/                            # Vendored xcframeworks
│   ├── WSNet.xcframework            #   core networking, written in C++ (scapix-bridged)
│   └── Proxy.xcframework
├── wstnet_tv.framework              # tvOS build of the networking core
├── wireguard-go-bridge/             # Go source for the WG user-space tunnel
├── build_wireguard_go_bridge.sh     # Xcode run-script that builds the bridge
├── HeaderPath/scapix/               # C++/Swift interop headers (scapix)
├── amz-wg-windscribe.patch          # Patch applied to the amneziawg package
├── fastlane/                        # lane definitions (lint, test, iOSBuild, iOSTestFlight, …)
├── .gitlab-ci.yml                   # GitLab runners (arm64, Xcode 26.3)
└── .swiftlint.yml
```

## Build & test

Build and test through Xcode or `xcodebuild` / `fastlane`. If you are running under a harness that exposes an Xcode MCP server (tool names like `BuildProject`, `RunAllTests`, `RunSomeTests`), prefer those — otherwise use the standard Xcode tooling. Schemes:

- `Windscribe-Debug` — main iOS scheme for development
- `Windscribe-Staging` / `Windscribe-Release` — staging/prod configurations
- `WindscribeTV-Debug` / `-Staging` / `-Release` — tvOS
- `WindscribeTests` — unit tests (CI runs on `iPhone 16 Pro`)

Signing lives in `Windscribe/Environments/Config.xcconfig`. Don't commit personal signing values — override locally.

## Core architectural facts

### Dependency injection — Swinject

Everything non-trivial is resolved through `Swinject`. Entry point is `Assembler.resolve(T.self)`.

- `CoreModule` → services shared with the Network Extensions (logger, WSNet, preferences, keychain)
- `UserScope` → rebuilt on login/logout
- `AppModules/iOS/` → iOS-app-only registrations (view models, routers, view controllers)
- Extensions (`PacketTunnel`, `WireGuardTunnel`) build their own `Container` and call `container.injectCore(ext: true)` — they cannot reach into the host app's DI graph at runtime.

When adding a new service: register in the correct module (is it shared with extensions? does it depend on session?), depend on the protocol, never on the impl.

### Persistence — Realm (today) / GRDB (target)

`Windscribe/Data/Database/LocalDatabase.swift` defines the app's DB contract. The impl wraps Realm and exposes `AnyPublisher<…>` streams for observation. Don't import `RealmSwift` outside of `Data/Database/` — views and VMs consume the `LocalDatabase` protocol so the storage engine can be swapped.

### Networking — WSNet

The API layer is a thin Swift wrapper over the vendored `WSNet.xcframework` (C++). Use `APIManager` / `APIManagerImpl+*` — they expose modern `async throws` methods and take care of retries, session refresh, and the Robert/Emergency/Bridge sub-APIs. `WSNet Protocol/` contains the low-level bindings; avoid reaching into them unless you're adding a new endpoint family.

### VPN stack

Three tunnel protocols, split across two Network Extension targets:

- `PacketTunnel/` — OpenVPN (via `OpenVPNAdapter`) and IKEv2 (via `NEVPNProtocolIKEv2`). Stealth and WStunnel are OpenVPN with obfuscation layers handled inside WSNet.
- `WireGuardTunnel/` — WireGuard and AmneziaWG, via `amneziawg-apple` (our fork) and the Go user-space bridge in `wireguard-go-bridge/`.

Tunnel selection and lifecycle live in `Managers/VPN/` and `Repository/VPN State/`. The `Managers/Protocols/` directory contains a small VPN-related protocol namespace — don't confuse it with Swift `protocol` files.

### Navigation

- Older UIKit screens use `Router/` coordinators (`HomeRouter`, `AccountRouter`, etc.) — each router wraps a `UINavigationController`.
- Newer SwiftUI screens use `Router/NavigationRouter/` which provides a `BaseNavigationRouter` + `NavigationRouterModifier` for `NavigationStack`-based flows.

### App extensions

| Target | Framework | Notes |
| --- | --- | --- |
| `HomeWidget` | WidgetKit (SwiftUI) | Imports `Swinject` + `ContainerResolver` to access app services |
| `AppIntents` | AppIntents (iOS 16+) | `ShortcutProvider` declares the public Shortcut phrases |
| `SiriIntents` | SiriKit (legacy) | Being phased out in favor of `AppIntents` |
| `PacketTunnel` | NetworkExtension | OpenVPN / IKEv2 |
| `WireGuardTunnel` | NetworkExtension | WireGuard / AmneziaWG |

All five share the `group.com.windscribe.vpn` App Group for IPC via `UserDefaults` and file storage.

### Localization

28 `.lproj` directories across the app, widget, and SiriIntents targets. Source strings live in `Windscribe/Supporting Files/Localization/`. Don't hard-code user-visible strings — add a key and localize it.

## Conventions

### Code style

- **Named constants over magic strings.** Use `Fields.Values.auto`, not `"Auto"`. Don't rewrite named constants into literals.
- **Images via the `ImagesAsset` enum** (`UIConstants+ImagesAsset.swift`). Never `Image("name")` or `UIImage(named: "name")` with a raw string.
- **Force-unwraps after nil checks are acceptable.** Don't over-guard.
- **Avoid SwiftUI `Group`** — use `@ViewBuilder` or the appropriate stack instead. The project is on Swift 5.9+, so there is no 10-view `@ViewBuilder` limit to worry about.
- **Place new constants at the end of their group**, not in the middle — keeps diffs clean.
- **SwiftLint** is authoritative; see `.swiftlint.yml` for the enabled ruleset. Don't disable rules without a review.
- **Release cadence is deliberate.** A migration or gated change must work on the first try in production — build runtime safety nets, don't rely on a quick follow-up release.

### MVVM + protocols (existing code)

```
UIKit VC or SwiftUI View  ⇄  ViewModel (ObservableObject / @Published)  ⇄  Service protocol  ⇄  Impl (registered in Swinject)
```

- View models are protocols; the impl is registered in `AppModulesViewModels.swift`.
- Services are protocols; impls are registered in `CoreModule.swift` or the relevant module.
- View models do not import SwiftUI. They should be testable as plain Swift.

### Testing

- Current tests use **XCTest** and live in `WindscribeTests/`. Mocks are hand-rolled in `WindscribeTests/Mocks/`.
- New tests may use the **Swift Testing** framework (`import Testing`, `@Test`, `#expect`). Prefer it for brand-new test files; don't rewrite existing XCTest files just to change framework.
- Do **not** mock the database in integration-style tests for DB-adjacent features. Mocked DB layers have historically diverged from real Realm/GRDB behavior, masking migration and threading bugs. Use a real in-memory or scratch DB instead.

## Modernization direction

The app is moving to an iOS 18 floor with a full UI rebuild. **When you write new code, write it in the modern style even if the surrounding code is legacy.** This keeps the eventual flip painless.

| Layer | Legacy (current, in tree) | Modern (target, for new code) |
| --- | --- | --- |
| UI | UIKit + SnapKit | SwiftUI; UIKit only with a documented reason |
| Async | Combine, completion handlers | `async/await`, `AsyncStream`, `TaskGroup` |
| DI | Swinject (`Assembler.resolve`) | Constructor injection + SwiftUI `@Environment` |
| Observation | `ObservableObject` + `@Published` | `@Observable` macro |
| Persistence | Realm (`RealmSwift`) | GRDB (`FetchableRecord` / `PersistableRecord` structs, `ValueObservation`) |
| Sync primitives | `DispatchQueue` for locking | `actor`; `Mutex` / `Atomic` from `Synchronization` where `await` isn't viable |
| Navigation | UIKit `Router` coordinators | `NavigationStack` + `NavigationPath` |
| Tests | XCTest | Swift Testing (`#expect`, `@Test`, parameterized) |
| Language mode | Swift 5 | Swift 5 with `StrictConcurrency = targeted` → module-by-module to Swift 6 |

**Swift 6-ready patterns, usable today in Swift 5:**

- `@MainActor` on view models explicitly (even under SwiftUI's implicit main isolation).
- Mark `Sendable` where a type crosses isolation boundaries. Avoid `@unchecked Sendable` — if forced, add a comment explaining why.
- Use `actor` for mutable shared state. No new `DispatchQueue`-based locking.
- Convert Combine publisher APIs at the boundary with `.values` to `AsyncSequence`.
- Typed error enums per domain; no bare `Error` / `NSError` in new public APIs.

**Hard rules for new code:**

1. No new `RxSwift` — already fully removed from the codebase. Do not reintroduce.
2. No new `Combine` usage. Convert at Apple-API boundaries with `.values`.
3. No new `Swinject` registrations in greenfield modules. Prefer init-injected protocols. (Existing modules stay on Swinject until rewritten.)
4. No new `ObservableObject` / `@Published` / `@StateObject` / `@ObservedObject`. Use `@Observable` + `@State` + `@Bindable`.
5. No new UIKit screens. SwiftUI first; UIKit wrapping only with a justification comment.
6. No new Realm `Object` subclasses. New persistence goes through a protocol-defined store; back it with GRDB.
7. One tunnel configuration path. Don't add `if #available(iOS 16, *)` guards in new tunnel code — the minimum deployment target is moving to iOS 18.
8. View models don't import SwiftUI.

**When editing legacy code:** match the surrounding style. Don't rewrite a UIKit controller to SwiftUI mid-feature unless that rewrite *is* the task.

## Agent workflow rules

- For UI tasks, **focus on View/ViewModel**. Skip API/wsnet exploration unless the task explicitly involves it.
- For SwiftUI errors, **research before fixing** — don't guess. The project uses modern Swift with no `@ViewBuilder` view-count limit.
- **Suggest least-invasive solutions first.** CI/build-time overrides beat project-file mutations. Only open `project.pbxproj` as a last resort.
- **Only implement what's asked.** Don't start "next phase" work proactively; surface it as a follow-up instead.
- **Build verification is cheap** — build the affected scheme after non-trivial changes. Don't claim a task is done without confirming it builds.

## Key files for orientation

| If you're looking for… | Start at |
| --- | --- |
| App entry & launch sequence | `Windscribe/AppDelegate.swift`, `Windscribe/SceneDelegate.swift` |
| Service registration | `Windscribe/Dependencies/CoreModule.swift`, `AppModules/iOS/*.swift` |
| DB schema / migrations | `Windscribe/Data/Database/LocalDatabaseImpl+Migration.swift` |
| VPN connect flow | `Windscribe/Managers/VPN/`, `Windscribe/Repository/VPN State/` |
| Tunnel entry points | `PacketTunnel/PacketTunnelProvider.swift`, `WireGuardTunnel/PacketTunnelProvider.swift` |
| Main screen | `Windscribe/ViewControllers/MainViewController/MainViewController.swift` |
| SwiftUI auth flow (modern example) | `Windscribe/Modules/Authentication/` |
| API endpoints | `Windscribe/API/APIManagerImpl+*.swift` |
| Constants / feature flags / enums | `Windscribe/Constants/` |
| Signing & bundle IDs | `Windscribe/Environments/Config.xcconfig` |

---

*This document is alive. Update it as the migration advances — especially the [Modernization direction](#modernization-direction) table as legacy layers get retired.*
