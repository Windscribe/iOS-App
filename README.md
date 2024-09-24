## Windscribe for iOS and tvOS

Windscribe for iOS and tvOS are native apps written in Swift language. Some features include multiple protocols, per network configuration, On-Demand mode.

- [Download and install](README.md#download-and-install)
- [Acknowledgements](README.md#acknowledgements)
- [Build from source](README.md#build-from-source)
    - [Requirements](README.md#requirements)
    - [Development dependencies](README.md#development-dependencies)
    - [Project dependencies](README.md#install-dependencies)
    - [Build](README.md#build)
    - [Troubleshoot](README.md#troubleshoot)
        - [pod install](README.md#pod-install)
        - [Wireguard-bridge](README.md#wireguard-bridge)
- [Pull request](README.md#pull-request)
- [Versioning](README.md#versioning)

### Download and install

Windscribe iOS and tvOS app can be downloaded from App Store
[Link](https://apps.apple.com/us/app/windscribe-vpn/id1129435228)

### Acknowledgements
Check our [Acknowledgements file](ACKNOWLEDGEMENTS.md) for the list of third parties libraries we use in this project

### Build from source

#### Requirements
- iOS 12.0+
- tvOS 17.0+
- Xcode 15.0+
- Swift 5.0+
- CocoaPods 1.15.2+
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
 - [MockingbirdFramework](https://github.com/typealiased/mockingbird)

#### Build
- Make sure following dependencies are installed
- Run all the following installations on the terminal
- Install Swift Lint
```sh
brew install swiftlint go
```
- Install Cocoa Pods
```sh
gem install cocoapods
```

```
- clone this repository
- `$ cd` into the project root directory
- open the pode file '$ open podfile' make sure the flag `is_tvos` is correct for the platform you are running 
  (`false` if you are trying to run for iOS and `true` if you are trying to run for tvOS)
- Run pod install to pull project dependencies
```sh
pod install 
```
- Open 'Windscribe.xcworkspace' in Xcode
- Select 'Windscribe-Default' scheme
- Open Windscribe > Enviroments > Config.xcconfig. Set your Team ID, App Bundle ID.
- Setup signing with an Apple paid developer account(Windscribe > Target > Signing and capabilities)
- Clean project (Product > clean Build folder - Cmd+Shift+K)
- Click File > Packages > Resolve package versions.
- Connect to a device, iphone/iPad for iOS, and apple tv for tvOS and run - Simulators are now supported in the default scheme, but you will not be able to connect to a VPN

#### Troubleshoot
##### pod install
- Check the the flag `is_tvos` on the podfile
- Clean Build
- Clear Xcode derived data (File > Workspace settings)
- Clear pod cache
```sh
rm -rf "${HOME}/Library/Caches/CocoaPods"
rm -rf "`pwd`/Pods/"
pod update
```

### Pull request
- fork this repository
- follow build instructions
- fix linter warnings and errors before submitting
```sh
swiftlint lint
```

### Versioning
The project is using Semantic Versioning ([SemVer](https://semver.org)) for creating release versions.

`Major.Minor.Patch`
