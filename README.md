## Windscribe for iOS and tvOS

Windscribe for iOS and tvOS are native apps written in Swift. Features include support for multiple VPN protocols, per-network configuration, and On-Demand mode.

- [Download and install](#download-and-install)
- [Acknowledgements](#acknowledgements)
- [Build from source](#build-from-source)
    - [Requirements](#requirements)
    - [Development dependencies](#development-dependencies)
    - [Project dependencies](#project-dependencies)
    - [Build](#build)
    - [Troubleshoot](#troubleshoot)
- [Pull request](#pull-request)
- [Versioning](#versioning)

### Download and install

Windscribe iOS and tvOS app can be downloaded from the App Store:  
[Link](https://apps.apple.com/us/app/windscribe-vpn/id1129435228)

### Acknowledgements

Check our [Acknowledgements file](ACKNOWLEDGEMENTS.md) for a list of third-party libraries used in this project.

### Build from source

#### Requirements

- iOS 15.0+
- tvOS 17.0+
- Xcode 15.0+
- Swift 5.9+
- Go 1.16+

#### Development dependencies

- swiftlint
- go

#### Project dependencies

- [CocoaLumberjack/Swift](https://github.com/CocoaLumberjack/CocoaLumberjack)
- [Realm](https://github.com/realm/realm-swift)
- [RealmSwift](https://github.com/realm/realm-swift)
- [IQKeyboardManagerSwift](https://github.com/hackiftekhar/IQKeyboardManager)
- [ExpyTableView](https://github.com/okhanokbay/ExpyTableView)
- [SwipeCellKit](https://github.com/SwipeCellKit/SwipeCellKit)
- [AES256Encrypter](https://github.com/dhilowitz/AES256Encrypter)
- [OpenVPNAdapter](https://github.com/ss-abramchuk/OpenVPNAdapter)
- [RxSwift](https://github.com/ReactiveX/RxSwift)
- [RxGesture](https://github.com/RxSwiftCommunity/RxGesture)
- [RxDataSources](https://github.com/RxSwiftCommunity/RxDataSources)
- [Swinject](https://github.com/Swinject/Swinject)
- [RxRealm](https://github.com/RxSwiftCommunity/RxRealm)
- [SnapKit](https://github.com/SnapKit/SnapKit)

#### Build

1. Clone this repository
    ```sh
    git clone <repo-url>
    cd Windscribe
    ```

2. Open the project in Xcode
    ```sh
    open Windscribe.xcodeproj
    ```

3. In Xcode, go to **File > Packages > Add Package Dependencies** and ensure all required Swift packages are properly resolved.

4. Choose the correct scheme from the available options:
   - `Windscribe-Default` (release configuration with debug flags enabled)
   - `Windscribe-Release`
   - `Windscribe-Staging`
   - `Windscribe-tvOS` (for building and running on Apple TV devices)

5. Navigate to `Windscribe/Environments/Config.xcconfig` and set your:
    - `Team ID`
    - `App Bundle ID`

6. Set up code signing under `Targets > Signing & Capabilities` using your Apple Developer account.

7. Clean the project:
    - `Product > Clean Build Folder` (Cmd + Shift + K)

8. Resolve all packages:
    - `File > Packages > Resolve Package Versions`

9. Connect a real device (iPhone/iPad for iOS or Apple TV for tvOS) and run the app.
    > Simulators are supported, but VPN connections require physical hardware.

#### Troubleshoot

- If build fails or dependencies don't resolve:
    - Clear Derived Data: `Xcode > Settings > Locations > Derived Data`
    - Reopen the project and resolve packages again

### Pull request

- Fork this repository
- Create an issue first and describe your proposed changes or bug fix
- Submit a pull request referencing the issue number
- Ensure the code builds successfully and passes linting:
    ```sh
    swiftlint lint
    ```

### Versioning

This project uses [Semantic Versioning](https://semver.org):

`Major.Minor.Patch (BuildNumber)`

Example: `3.8.5 (22)` on TestFlight
