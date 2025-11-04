# Windscribe iOS Application - Comprehensive Memory File

## Project Overview
Windscribe is a VPN (Virtual Private Network) application for iOS and tvOS platforms. This is a native iOS application written in Swift that provides comprehensive VPN functionality with multiple protocol support, per-network configuration, and On-Demand mode capabilities.

**Project Type:** iOS/tvOS VPN Application  
**Language:** Swift  
**Minimum iOS Version:** 15.0+  
**Minimum tvOS Version:** 17.0+  
**Xcode Version:** 15.0+  
**Swift Version:** 5.9+  

## Core Architecture

### Architecture Pattern
The application follows a clean architecture pattern with:
- **MVVM (Model-View-ViewModel)** for UI components
- **Repository Pattern** for data access
- **Dependency Injection** using Swinject
- **Reactive Programming** with RxSwift
- **Modular Design** with feature-based modules

### Key Components

#### 1. App Structure
```
Windscribe/
├── AppDelegate.swift - Main application delegate
├── API/ - Network layer and API management
├── Constants/ - Application constants and enums
├── Data/ - Data layer (Database, FileDatabase, KeyChain, Preferences)
├── Dependencies/ - Dependency injection configuration
├── Managers/ - Business logic managers
├── Models/ - Data models
├── Modules/ - Feature modules (Authentication, PlanUpgrade, Preferences)
├── Repository/ - Data access layer
├── Router/ - Navigation and routing
├── Util/ - Utility functions and helpers
├── View/ - Custom UI components
└── ViewControllers/ - Main view controllers
```

#### 2. VPN Core Functionality
- **VPNManager**: Core VPN management (`VPNManager.swift`)
- **ConfigurationsManager**: VPN configuration management
- **ProtocolManager**: Protocol switching and management
- **WireGuard Integration**: Custom WireGuard implementation
- **OpenVPN Support**: OpenVPN protocol support
- **IKEv2 Support**: IKEv2 protocol support

#### 3. Network Layer
- **APIManager**: Main API interface for server communication
- **WSNet Framework**: Custom networking framework
- **Emergency Connect**: Emergency connection capabilities
- **Latency Management**: Server latency testing and optimization

## Key Features

### 1. VPN Protocols
- **WireGuard**: Modern, high-performance VPN protocol
- **OpenVPN**: Traditional, widely-supported protocol
- **IKEv2**: Native iOS VPN protocol
- **Protocol Switching**: Automatic failover between protocols

### 2. Connection Management
- **Auto-Connect**: Automatic connection based on network conditions
- **Per-Network Configuration**: Different settings per WiFi network
- **On-Demand Rules**: iOS On-Demand VPN activation
- **Kill Switch**: Network blocking when VPN is disconnected

### 3. Server Management
- **Global Server Network**: Multiple server locations worldwide
- **Static IP**: Premium static IP addresses
- **Server Selection**: Manual and automatic server selection
- **Latency Testing**: Real-time server performance monitoring

### 4. Advanced Features
- **Robert (Ad Blocker)**: DNS-level ad and malware blocking
- **Firewall**: Application-level firewall rules
- **Split Tunneling**: Selective VPN routing
- **Custom Configs**: Import custom VPN configurations
- **Emergency Connect**: Failsafe connection method

## Data Management

### 1. Database Layer
- **LocalDatabase**: Realm-based local data storage
- **FileDatabase**: File-based configuration storage
- **KeyChainDatabase**: Secure credential storage
- **Preferences**: User settings and preferences

### 2. Key Data Models
- **Session**: User session management
- **ServerCredentials**: VPN server credentials
- **VPNConnection**: Connection state and history
- **User**: User account information
- **CustomConfig**: Custom VPN configurations

### 3. Repositories
- **ServerRepository**: Server data management
- **UserSessionRepository**: User data management
- **CredentialsRepository**: Credential management
- **LatencyRepository**: Server latency data
- **CustomConfigRepository**: Custom configuration management

## UI Architecture

### 1. Main Modules
- **Authentication**: Login/Signup flows
- **Home**: Main connection interface
- **Preferences**: Settings and configuration
- **Plan Upgrade**: Premium plan management
- **News Feed**: In-app news and updates

### 2. Custom UI Components
- **WSButton**: Custom button implementations
- **WSTextField**: Custom text field
- **WSView**: Base view with theming
- **NavigationController**: Custom navigation
- **LoadingSplashView**: Loading screens

### 3. Theming System
- **LookAndFeelRepository**: Theme management
- **Dark/Light Mode**: Automatic theme switching
- **Custom Backgrounds**: User-customizable backgrounds
- **Sound Effects**: Custom notification sounds

## Security & Privacy

### 1. Encryption
- **WireGuard Encryption**: Modern cryptographic protocols
- **OpenVPN Encryption**: Traditional VPN encryption
- **Keychain Storage**: Secure credential storage
- **Certificate Pinning**: API security

### 2. Network Security
- **DNS Leak Protection**: Prevent DNS leaks
- **IPv6 Leak Protection**: IPv6 traffic handling
- **WebRTC Leak Protection**: Browser leak prevention
- **Kill Switch**: Network blocking on disconnection

### 3. Privacy Features
- **No Logging**: No user activity logging
- **Anonymous Usage**: No personal data collection
- **Secure Tunneling**: Encrypted traffic routing
- **IP Masking**: Hide real IP address

## Platform Integration

### 1. iOS Features
- **Siri Integration**: Voice commands for VPN control
- **Shortcuts**: iOS Shortcuts app integration
- **Widget Support**: Home screen widgets
- **Background App Refresh**: Automatic updates
- **Push Notifications**: Server notifications

### 2. Network Extensions
- **PacketTunnelProvider**: Custom packet tunnel
- **WireGuardTunnel**: WireGuard network extension
- **VPN Configuration**: System VPN integration
- **Network Monitoring**: Connection state monitoring

### 3. tvOS Support
- **Apple TV App**: Dedicated tvOS application
- **TV-Specific UI**: Remote-friendly interface
- **Simplified Flow**: Streamlined user experience

## Dependencies & Third-Party Libraries

### Swift Package Manager Dependencies (from Package.resolved)
- **CocoaLumberjack (3.8.5)**: Advanced logging framework
- **DNS (1.2.0)**: DNS resolution library
- **ExpyTableView (1.2.2)**: Expandable table views
- **IQKeyboardManager (6.5.0)**: Keyboard handling automation
- **OpenVPNAdapter (Windscribe fork)**: OpenVPN protocol implementation
- **Realm-Swift (10.54.5)**: Database management with Swift bindings
- **RxDataSources (5.0.2)**: Reactive table/collection view data sources
- **RxGesture (4.0.4)**: Reactive gesture recognizers
- **RxSwift (6.9.0)**: Reactive programming framework
- **SimpleKeychain (1.2.0)**: Keychain wrapper
- **SnapKit (5.7.1)**: Auto Layout DSL
- **Swift-Log (1.6.3)**: Apple's logging API
- **Swift-Resolver (0.3.0)**: DNS resolver
- **Swift-UniSocket (0.14.0)**: Universal socket library
- **Swinject (2.9.1)**: Dependency injection container
- **SwipeCellKit (2.7.1)**: Swipe gesture handling for table cells
- **WireGuard-Apple (Windscribe fork)**: WireGuard protocol implementation

### Custom Frameworks & Libraries
- **WSNet**: Custom networking framework (C++/Go bridge)
- **libwg-go.a**: WireGuard Go implementation
- **Proxy.xcframework**: Custom proxy framework
- **wstnet_tv.framework**: TV-specific networking framework

## Build Configuration

### 1. Schemes
- **Windscribe-Default**: Debug configuration with release optimizations
- **Windscribe-Release**: Production release
- **Windscribe-Staging**: Staging environment
- **Windscribe-tvOS**: Apple TV build

### 2. Targets
- **Windscribe**: Main iOS application
- **WindscribeTV**: Apple TV application
- **PacketTunnel**: VPN network extension
- **WireGuardTunnel**: WireGuard network extension
- **HomeWidget**: iOS widget extension
- **SiriIntents**: Siri shortcuts extension

### 3. Entitlements
- **VPN Configuration**: VPN profile management
- **Network Extensions**: Packet tunnel provider
- **Keychain Sharing**: Secure data sharing
- **Background Modes**: Background processing
- **Push Notifications**: Remote notifications

## Development Guidelines

### 1. Code Organization
- **Feature Modules**: Organized by functionality
- **Clean Architecture**: Separation of concerns
- **Protocol-Oriented**: Swift protocol usage
- **Reactive Programming**: RxSwift patterns

### 2. Testing Strategy
- **Unit Tests**: Core business logic testing
- **Mock Objects**: Dependency mocking
- **Integration Tests**: API and database testing
- **UI Tests**: User interface testing

### 3. Localization
- **Multi-Language Support**: 20+ languages
- **Localized Strings**: Resource bundles
- **RTL Support**: Right-to-left language support
- **Dynamic Localization**: Runtime language switching

## Performance Optimization

### 1. Memory Management
- **ARC**: Automatic Reference Counting
- **Weak References**: Avoid retain cycles
- **Dispose Bags**: RxSwift resource management
- **Background Processing**: Efficient background tasks

### 2. Network Optimization
- **Connection Pooling**: Reuse network connections
- **Caching**: API response caching
- **Compression**: Data compression
- **Background Sync**: Efficient data synchronization

### 3. Battery Optimization
- **Background Modes**: Minimal background activity
- **Location Services**: Efficient location usage
- **Network Monitoring**: Optimized connectivity checks
- **VPN Efficiency**: Low-power VPN protocols

## Error Handling

### 1. Error Types
- **VPNErrors**: VPN-specific error handling
- **ManagerErrors**: Business logic errors
- **RepositoryErrors**: Data access errors
- **APIErrors**: Network and API errors

### 2. Error Recovery
- **Automatic Retry**: Failed operation retry
- **Fallback Protocols**: Protocol switching on failure
- **User Feedback**: Clear error messages
- **Logging**: Comprehensive error logging

## Monitoring & Analytics

### 1. Logging
- **FileLogger**: Local file logging
- **CocoaLumberjack**: Advanced logging framework
- **Debug Information**: Development debugging
- **Crash Reports**: Production crash tracking

### 2. Performance Monitoring
- **Connection Metrics**: VPN performance tracking
- **App Performance**: UI responsiveness monitoring
- **Memory Usage**: Memory leak detection
- **Network Performance**: API response times

## Future Considerations

### 1. Scalability
- **Modular Architecture**: Easy feature addition
- **Protocol Extensibility**: New VPN protocol support
- **Server Scaling**: Handle increased server load
- **User Growth**: Support more concurrent users

### 2. Technology Updates
- **iOS Updates**: New iOS feature adoption
- **Swift Evolution**: Language feature updates
- **Security Updates**: Cryptographic improvements
- **Performance Enhancements**: Ongoing optimizations

## Key Files Reference

### Core Application
- `AppDelegate.swift` - Application lifecycle management
- `VPNManager.swift` - Core VPN functionality
- `APIManager.swift` - Network API interface
- `LocalDatabase.swift` - Local data storage
- `Preferences.swift` - User preferences management

### Configuration
- `AppModules.swift` - Dependency injection setup
- `AppConstants.swift` - Application constants
- `Config.xcconfig` - Build configuration
- `Info.plist` - Application metadata

### Extensions
- `PacketTunnelProvider.swift` - VPN network extension
- `WireGuardTunnel` - WireGuard implementation
- `HomeWidget.swift` - iOS widget functionality
- `SiriIntents` - Siri integration

This comprehensive memory file provides a complete overview of the Windscribe iOS application architecture, features, and implementation details for AI assistance and development reference.
