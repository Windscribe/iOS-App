## Windscribe for iOS and tvOS

Native Swift apps for iPhone, iPad, and Apple TV. Supports multiple VPN protocols (WireGuard, AmneziaWG, OpenVPN, IKEv2, Stealth, WStunnel), per-Wi-Fi configuration, On-Demand mode, Siri/Shortcuts integration, and a home-screen widget.

- [Install from the App Store](#install-from-the-app-store)
- [Build from source](#build-from-source)
    - [Requirements](#requirements)
    - [First-time setup](#first-time-setup)
    - [Build & run](#build--run)
    - [Schemes](#schemes)
    - [Troubleshooting](#troubleshooting)
- [Testing](#testing)
- [Linting](#linting)
- [Contributing](#contributing)
- [Versioning](#versioning)
- [Acknowledgements](#acknowledgements)

### Install from the App Store

[apps.apple.com/us/app/windscribe-vpn/id1129435228](https://apps.apple.com/us/app/windscribe-vpn/id1129435228)

### Build from source

#### Requirements

| Tool | Version |
| --- | --- |
| Xcode | 26.3 (pinned in CI) |
| iOS deployment target | 15.0 (iOS 18 minimum coming in the next major rebuild) |
| tvOS deployment target | 17.5 |
| Swift | 5.0 / 6.0 (mixed — targets are migrating) |
| Go | 1.22+ (for the WireGuard-go bridge) |
| Ruby | for `fastlane` (see `Gemfile`) |
| swiftlint | for lint checks |

Physical iOS/tvOS hardware is required to actually run a tunnel. Simulators build and launch, but cannot bring up a Network Extension.

#### First-time setup

1. Clone and open the project:
    ```sh
    git clone <repo-url> iosapp
    cd iosapp
    open Windscribe.xcodeproj
    ```

2. Override `Windscribe/Environments/Config.xcconfig` with your own signing values. The default file points at Windscribe's team / bundle IDs:
    ```
    APP_TEAM_ID = <your Apple Developer team ID>
    APP_BUNDLE_ID = <your reverse-DNS bundle ID>
    ```
    The extension bundle IDs (`PacketTunnel`, `WireGuardTunnel`, `SiriIntents`, `HomeWidget`) are derived from `APP_BUNDLE_ID` automatically.

3. In each target's **Signing & Capabilities** tab, select your Apple Developer team. All five app-group-sharing targets must be signed with the same team.

4. Let Xcode resolve Swift packages (**File → Packages → Resolve Package Versions**).

#### Build & run

Pick a scheme, pick a device, hit ⌘R. The `build_wireguard_go_bridge.sh` run script builds the WireGuard-Go bridge the first time you build (and re-runs when the SDK root changes). It needs `go` on your `PATH` or it will download a toolchain to a temp dir.

#### Schemes

| Scheme | Purpose |
| --- | --- |
| `Windscribe-Debug` | Day-to-day development, points at production API |
| `Windscribe-Staging` | Staging API endpoints |
| `Windscribe-Release` | Release build, production API |
| `WindscribeTV-Debug` / `-Staging` / `-Release` | tvOS equivalents |
| `WindscribeTests` | Unit test target (runs on `iPhone 16 Pro` in CI) |
| `HomeWidgetExtension` | Build just the widget extension |

#### Troubleshooting

- **Packages fail to resolve** → Xcode → Settings → Locations → Derived Data → delete, then **File → Packages → Reset Package Caches**.
- **WireGuard-go build fails** → install Go (`brew install go`) and rebuild. The script caches by SDK root, so `Product → Clean Build Folder` also clears it.
- **Code signing errors on extensions** → make sure every target uses the same team and that your provisioning profiles include the Network Extensions entitlement.
- **Realm migration errors on first run after pulling main** → delete the app from the device; schema migrations are handled at launch but only for versions we've shipped.

### Testing

```sh
fastlane test           # runs WindscribeTests on iPhone 16 Pro
```

Or from Xcode: select the `WindscribeTests` scheme and ⌘U.

### Linting

```sh
swiftlint lint          # or: fastlane lint
```

Config lives in `.swiftlint.yml`. Pull/merge requests are gated on lint passing.

### Contributing

1. Fork the repo and open an issue describing the change.
2. Branch off `main` (`feature/<slug>` or `fix/<slug>`).
3. Keep commits focused; ensure lint + tests pass locally.
4. Open a pull request (or merge request, if working on the GitLab source) referencing the issue.

New code follows the patterns in [`AGENTS.md`](AGENTS.md). In short: SwiftUI + `@Observable` + async/await for anything new; existing UIKit/Combine/Swinject/Realm stays until it's rewritten.

### Versioning

Semantic Versioning — `Major.Minor.Patch (BuildNumber)`, e.g. `3.10.1 (22)` on TestFlight.

### Acknowledgements

Third-party licenses: [`ACKNOWLEDGEMENTS.md`](ACKNOWLEDGEMENTS.md).
License: [`LICENCE.md`](LICENCE.md).
