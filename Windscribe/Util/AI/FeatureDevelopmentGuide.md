# Windscribe iOS - SwiftUI Migration Guide

## Architecture Overview

### Current State
- **Legacy Framework**: UIKit + RxSwift
- **Target Framework**: SwiftUI + MVVM + Combine
- **Migration Strategy**: Gradual, UI-first approach with existing RxSwift bridge

### Migration Constraints
- **Existing Managers and Coordinators**: **MUST remain in RxSwift** (cannot be refactored at this stage)
- **New ViewModels**: **MUST use Combine exclusively** (no new RxSwift code allowed)
- **UI Migration**: SwiftUI Views with Combine-based ViewModels
- **Service Integration**: Use existing `RxSwift+Extension.swift` bridge for connecting new Combine ViewModels to legacy RxSwift services

### Architecture Layers
```
┌─────────────────────────────────────┐
│           SwiftUI Views             │
│         (New Implementation)        │
├─────────────────────────────────────┤
│      Combine ViewModels             │
│      (New Implementation)           │
├─────────────────────────────────────┤
│        RxSwift Bridge               │
│   (Existing RxSwift+Extension.swift)│
├─────────────────────────────────────┤
│    Legacy RxSwift Services          │
│  (Managers, Coordinators, etc.)     │
│      **CANNOT BE CHANGED**          │
└─────────────────────────────────────┘
```

## Existing Bridge Implementation

### Overview
The `RxSwift+Extension.swift` file (located at `Windscribe/Util/Extensions/RxSwift+Extension.swift`) provides comprehensive bridging between RxSwift and Combine. This bridge **already exists** and should be used for all new ViewModels that need to interact with legacy RxSwift services.

### Available Bridge Methods

#### 1. RxSwift Single → Combine Publisher
```swift
// Existing implementation in RxSwift+Extension.swift
extension PrimitiveSequence where Trait == SingleTrait {
    func asPublisher() -> AnyPublisher<Element, Error>
}

// Usage in new ViewModels:
class ConnectionViewModel: ObservableObject {
    func connect() {
        vpnManager.connect() // Returns RxSwift Single
            .asPublisher()    // Convert to Combine
            .sink(...)
            .store(in: &cancellables)
    }
}
```

#### 2. RxSwift BehaviorSubject → Combine Publisher
```swift
// Existing implementation in RxSwift+Extension.swift
extension BehaviorSubject {
    func asPublisher() -> AnyPublisher<Element, Error>
}

// Usage in new ViewModels:
class ServerListViewModel: ObservableObject {
    @Published var servers: [Server] = []
    
    private func setupBindings() {
        serverManager.serversSubject // RxSwift BehaviorSubject
            .asPublisher()           // Convert to Combine
            .receive(on: DispatchQueue.main)
            .assign(to: &$servers)
    }
}
```

#### 3. RxSwift Observable → Combine Publisher
```swift
// Existing implementation in RxSwift+Extension.swift
extension Observable {
    func toPublisher() -> AnyPublisher<Element, Error>
    func toInitialPublisher() -> AnyPublisher<Element, Error>
}

extension ObservableType {
    func toPublisher() -> AnyPublisher<Element, Error>
    func toPublisher(initialValue: Element) -> AnyPublisher<Element, Error>
}

// Usage in new ViewModels:
class NetworkStatusViewModel: ObservableObject {
    @Published var isConnected = false
    
    private func setupBindings() {
        networkManager.connectionState // RxSwift Observable
            .toPublisher()             // Convert to Combine
            .map { $0 == .connected }
            .assign(to: &$isConnected)
    }
}
```

#### 4. Synchronous Void Functions → Combine Publisher
```swift
// Existing implementation in RxSwift+Extension.swift
func asVoidPublisher(_ action: @escaping () -> Void) -> AnyPublisher<Void, Error>

// Usage in new ViewModels:
class SettingsViewModel: ObservableObject {
    func saveSettings() {
        asVoidPublisher {
            preferencesManager.saveSettings() // Synchronous void function
        }
        .sink(
            receiveCompletion: { completion in
                // Handle completion
            },
            receiveValue: { _ in
                // Settings saved
            }
        )
        .store(in: &cancellables)
    }
}
```

### Bridge Error Handling
The bridge includes proper error handling with `RxBridgeError`:
```swift
enum RxBridgeError: Error {
    case missingInitialValue
}
```

## Migration Patterns

### Pattern 1: ViewModel with Legacy Service Integration
```swift
class VPNConnectionViewModel: ObservableObject {
    @Published var connectionState: VPNState = .disconnected
    @Published var selectedServer: Server?
    @Published var isConnecting = false
    @Published var errorMessage: String?
    
    private let vpnManager: VPNManager          // Legacy RxSwift service
    private let serverManager: ServerManager    // Legacy RxSwift service
    private var cancellables = Set<AnyCancellable>()
    
    init(vpnManager: VPNManager, serverManager: ServerManager) {
        self.vpnManager = vpnManager
        self.serverManager = serverManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Bridge RxSwift BehaviorSubject to Combine
        vpnManager.connectionStateSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { [weak self] state in
                    self?.connectionState = state
                    self?.isConnecting = (state == .connecting)
                }
            )
            .store(in: &cancellables)
        
        // Bridge RxSwift Observable to Combine
        serverManager.selectedServerObservable
            .toPublisher()
            .receive(on: DispatchQueue.main)
            .assign(to: &$selectedServer)
    }
    
    func connect() {
        guard let server = selectedServer else { return }
        
        isConnecting = true
        errorMessage = nil
        
        // Bridge RxSwift Single to Combine
        vpnManager.connect(to: server)
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] completion in
                    self?.isConnecting = false
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { _ in
                    // Connection initiated successfully
                }
            )
            .store(in: &cancellables)
    }
    
    func disconnect() {
        // Bridge synchronous void function to Combine
        asVoidPublisher {
            self.vpnManager.disconnect()
        }
        .sink(
            receiveCompletion: { [weak self] completion in
                if case .failure(let error) = completion {
                    self?.errorMessage = error.localizedDescription
                }
            },
            receiveValue: { _ in
                // Disconnection completed
            }
        )
        .store(in: &cancellables)
    }
}
```

### Pattern 2: SwiftUI View with Combine ViewModel
```swift
struct VPNConnectionView: View {
    @StateObject private var viewModel: VPNConnectionViewModel
    
    var body: some View {
        VStack(spacing: 20) {
            // Connection Status
            VStack {
                Text("Status: \(viewModel.connectionState.displayName)")
                    .font(.headline)
                
                if let server = viewModel.selectedServer {
                    Text("Server: \(server.name)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            // Connect/Disconnect Button
            Button(action: {
                if viewModel.connectionState == .disconnected {
                    viewModel.connect()
                } else {
                    viewModel.disconnect()
                }
            }) {
                if viewModel.isConnecting {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Connecting...")
                    }
                } else {
                    Text(viewModel.connectionState == .disconnected ? "Connect" : "Disconnect")
                }
            }
            .disabled(viewModel.isConnecting)
            
            // Error Message
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
}
```

## Conventions and Guidelines

### 1. ViewModels Must Use Combine Only
- **Rule**: No new RxSwift code in ViewModels
- **Implementation**: Use existing bridge methods to convert RxSwift services to Combine
- **Exception**: None - this is a strict requirement

```swift
// ✅ Correct: Using bridge to convert RxSwift to Combine
class NewFeatureViewModel: ObservableObject {
    @Published var data: [Item] = []
    
    private func loadData() {
        legacyService.fetchItems() // RxSwift Single
            .asPublisher()         // Convert to Combine
            .assign(to: &$data)
    }
}

// ❌ Incorrect: Using RxSwift directly in new ViewModels
class NewFeatureViewModel: ObservableObject {
    private let disposeBag = DisposeBag() // ❌ No RxSwift in new code
    
    private func loadData() {
        legacyService.fetchItems()
            .subscribe(onSuccess: { ... }) // ❌ No RxSwift subscriptions
            .disposed(by: disposeBag)
    }
}
```

### 2. Legacy Services Cannot Be Modified
- **Rule**: Existing RxSwift Managers and Coordinators remain unchanged
- **Rationale**: Minimize risk and maintain stability during migration
- **Implementation**: Use bridge methods to integrate with legacy services

```swift
// ✅ Correct: Using existing VPNManager as-is
class ConnectionViewModel: ObservableObject {
    private let vpnManager: VPNManager // Legacy RxSwift service - unchanged
    
    func connect() {
        vpnManager.connect()    // Legacy RxSwift method
            .asPublisher()      // Bridge to Combine
            .sink(...)
    }
}

// ❌ Incorrect: Modifying legacy services
class ConnectionViewModel: ObservableObject {
    private let vpnManager: VPNManager
    
    func connect() {
        // ❌ Don't modify VPNManager to return Combine publishers
        vpnManager.connectWithCombine() // This method doesn't exist
    }
}
```

### 3. Use @Published for All UI State
- **Rule**: Expose all UI-relevant state through @Published properties
- **Implementation**: Transform RxSwift streams to @Published properties via bridge

```swift
class ServerListViewModel: ObservableObject {
    @Published var servers: [Server] = []
    @Published var isLoading = false
    @Published var selectedServer: Server?
    
    private func setupBindings() {
        // Convert RxSwift to @Published properties
        serverManager.serversObservable
            .toPublisher()
            .receive(on: DispatchQueue.main)
            .assign(to: &$servers)
        
        serverManager.loadingStateSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoading)
    }
}
```

### 4. Dependency Injection for ViewModels
- **Rule**: Inject legacy services through initializers
- **Implementation**: Pass RxSwift services to ViewModels, use bridge internally

```swift
class AuthViewModel: ObservableObject {
    private let authManager: AuthManager // Legacy RxSwift service
    private let apiManager: APIManager   // Legacy RxSwift service
    
    init(authManager: AuthManager, apiManager: APIManager) {
        self.authManager = authManager
        self.apiManager = apiManager
        setupBindings()
    }
    
    private func setupBindings() {
        // Use bridge to convert RxSwift to Combine
        authManager.authStateSubject
            .asPublisher()
            .assign(to: &$isAuthenticated)
    }
}
```

## Migration Checklist

### For Each New SwiftUI Feature
- [ ] Create SwiftUI View (no UIKit)
- [ ] Implement Combine-based ViewModel (no RxSwift)
- [ ] Use existing `RxSwift+Extension.swift` bridge methods
- [ ] Inject legacy RxSwift services through initializer
- [ ] Convert all RxSwift streams to @Published properties
- [ ] Handle errors appropriately in Combine pipeline
- [ ] Test integration with legacy services

### Bridge Usage Verification
- [ ] Verify `RxSwift+Extension.swift` contains required bridge methods
- [ ] Use `asPublisher()` for Singles and BehaviorSubjects
- [ ] Use `toPublisher()` for Observables
- [ ] Use `asVoidPublisher()` for synchronous void functions
- [ ] Handle `RxBridgeError.missingInitialValue` when needed

## Common Migration Scenarios

### Scenario 1: Migrating Connection Screen
```swift
// Old UIKit + RxSwift (don't modify)
class ConnectionViewController: UIViewController {
    // Keep existing implementation
}

// New SwiftUI + Combine
class ConnectionViewModel: ObservableObject {
    @Published var state: VPNState = .disconnected
    
    private let vpnManager: VPNManager // Legacy service
    
    init(vpnManager: VPNManager) {
        self.vpnManager = vpnManager
        
        // Bridge legacy RxSwift to Combine
        vpnManager.connectionStateSubject
            .asPublisher()
            .assign(to: &$state)
    }
}

struct ConnectionView: View {
    @StateObject private var viewModel: ConnectionViewModel
    
    var body: some View {
        // SwiftUI implementation
    }
}
```

### Scenario 2: Migrating Settings Screen
```swift
class SettingsViewModel: ObservableObject {
    @Published var preferences: UserPreferences?
    @Published var isLoading = false
    
    private let preferencesManager: PreferencesManager // Legacy service
    
    init(preferencesManager: PreferencesManager) {
        self.preferencesManager = preferencesManager
        loadPreferences()
    }
    
    private func loadPreferences() {
        preferencesManager.getPreferences() // RxSwift Single
            .asPublisher()                   // Bridge to Combine
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { _ in },
                receiveValue: { [weak self] preferences in
                    self?.preferences = preferences
                }
            )
            .store(in: &cancellables)
    }
}
```

## Best Practices

### 1. Error Handling
```swift
class DataViewModel: ObservableObject {
    @Published var errorMessage: String?
    
    private func loadData() {
        dataService.fetchData()
            .asPublisher()
            .sink(
                receiveCompletion: { [weak self] completion in
                    if case .failure(let error) = completion {
                        self?.errorMessage = error.localizedDescription
                    }
                },
                receiveValue: { data in
                    // Handle success
                }
            )
            .store(in: &cancellables)
    }
}
```

### 2. Loading States
```swift
class LoadingViewModel: ObservableObject {
    @Published var isLoading = false
    @Published var data: [Item] = []
    
    func refresh() {
        isLoading = true
        
        service.fetchItems()
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(
                receiveCompletion: { [weak self] _ in
                    self?.isLoading = false
                },
                receiveValue: { [weak self] items in
                    self?.data = items
                }
            )
            .store(in: &cancellables)
    }
}
```

### 3. Combining Multiple RxSwift Streams
```swift
class CombinedViewModel: ObservableObject {
    @Published var combinedData: CombinedData?
    
    private func setupBindings() {
        let publisher1 = service1.dataObservable.toPublisher()
        let publisher2 = service2.dataObservable.toPublisher()
        
        Publishers.CombineLatest(publisher1, publisher2)
            .map { data1, data2 in
                CombinedData(first: data1, second: data2)
            }
            .assign(to: &$combinedData)
    }
}
```

## Testing Strategy

### ViewModel Testing
```swift
class ConnectionViewModelTests: XCTestCase {
    private var sut: ConnectionViewModel!
    private var mockVPNManager: MockVPNManager!
    
    override func setUp() {
        super.setUp()
        mockVPNManager = MockVPNManager()
        sut = ConnectionViewModel(vpnManager: mockVPNManager)
    }
    
    func testConnectionStateUpdates() {
        // Test that bridge correctly converts RxSwift to Combine
        let expectation = expectation(description: "State updated")
        
        sut.$connectionState
            .sink { state in
                if state == .connected {
                    expectation.fulfill()
                }
            }
            .store(in: &cancellables)
        
        mockVPNManager.connectionStateSubject.onNext(.connected)
        
        wait(for: [expectation], timeout: 1.0)
    }
}
```

## Future Considerations

### Bridge Evolution
- Monitor bridge performance and memory usage
- Consider optimizations as more features migrate
- Document any new bridge methods added to `RxSwift+Extension.swift`

### Complete Migration
- Eventually, when all UI is migrated to SwiftUI, consider gradual migration of legacy services
- Bridge will remain necessary until legacy services are converted
- Plan for gradual service layer migration in future phases

## Real-World Migration Example: Location Permission Feature

### PR Analysis: Converting UIKit to SwiftUI + Combine ViewModel

Based on an actual PR in the codebase, here's a real-world example of how the migration strategy works in practice. This serves as a template for other refactoring feature parts.

#### What Actually Happened

1. **ADDED**: SwiftUI `LocationPermissionInfoView` and `LocationPermissionInfoViewModel` (using Combine with RxSwift bridge)
2. **REMOVED**: UIKit `LocationPermissionDisclosureViewController` (old UIKit approach)
3. **CONVERTED**: `LocationMainViewModel` → `LocationPermissionManager` (still RxSwift but more reactive, as managers/repositories aren't converted yet)
4. **ELIMINATED**: Callback patterns and delegate passing through routers
5. **REACTIVE**: Everything now works through reactive observables - SwiftUI Views observe ViewModel state through Combine

#### The Migration Pattern Applied

##### 1. UIKit Controller → SwiftUI View + Combine ViewModel
```swift
// BEFORE: UIKit Controller (old approach)
class LocationPermissionDisclosureViewController: WSUIViewController {
    weak var delegate: DisclosureAlertDelegate?
    var denied: Bool = false
    
    @objc func actionButtonTapped() {
        if denied {
            delegate?.openLocationSettingsClicked()
        } else {
            delegate?.grantPermissionClicked()
        }
        dismiss(animated: true, completion: nil)
    }
}

// AFTER: SwiftUI View + Combine ViewModel (new approach)
struct LocationPermissionInfoView: View {
    @StateObject private var viewModel: LocationPermissionInfoViewModelImpl
    
    var body: some View {
        // SwiftUI declarative UI
        Button(action: viewModel.handlePrimaryAction) {
            Text(viewModel.accessDenied ? "Open Settings" : "Grant Permission")
        }
    }
}

class LocationPermissionInfoViewModelImpl: LocationPermissionInfoViewModel {
    @Published var isDarkMode: Bool = false
    @Published var accessDenied: Bool = false
    
    private func bind() {
        // Use RxSwift bridge to connect to legacy services
        manager.locationStatusSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                self?.accessDenied = (status == .denied)
            })
            .store(in: &cancellables)
    }
}
```

##### 2. ViewModel Inside Controller → Dedicated Reactive Manager
```swift
// BEFORE: ViewModel logic scattered inside MainViewController
class MainViewController: WSUIViewController {
    private func handleLocationPermission() {
        // Logic mixed with UI controller
    }
}

// AFTER: Dedicated reactive manager
class LocationPermissionManager: NSObject, LocationPermissionManaging {
    let locationStatusSubject = BehaviorSubject<CLAuthorizationStatus>(value: .notDetermined)
    let shouldShowPermissionUI = PublishSubject<Void>()
    
    func requestLocationPermission() {
        // Centralized, reactive logic
        let status = getStatus()
        shouldShowPermissionUI.onNext(())
        locationStatusSubject.onNext(status)
    }
}
```

##### 3. Callback/Delegate Passing → Pure Reactive Observation
```swift
// BEFORE: Callback patterns
vpnConnectionViewModel.requestLocationTrigger
    .flatMap { [weak self] _ -> Single<Void> in
        return self?.locationPermissionManager.requestLocationPermissionFlow()
    }
    .subscribe(onNext: { [weak self] in
        self?.router?.routeTo(to: .protocolSetPreferred, from: self)
    })

// AFTER: Pure reactive observation
vpnConnectionViewModel.requestLocationTrigger
    .observe(on: MainScheduler.asyncInstance)
    .subscribe(onNext: {
        self.locationPermissionManager.requestLocationPermission()
    })

// SwiftUI View observes manager state reactively
manager.locationStatusSubject
    .asPublisher()
    .receive(on: DispatchQueue.main)
    .sink(receiveValue: { [weak self] status in
        if status == .authorizedWhenInUse {
            // React to state change
        }
    })
```

##### 4. Router Passes Values → Router Triggers, Views Observe Reactively
```swift
// BEFORE: Router passes values and delegates
case let RouteID.locationPermission(delegate, denied):
    let vc = LocationPermissionInfoViewController()
    vc.delegate = delegate
    vc.denied = denied
    from.present(vc, animated: true)

// AFTER: Router only triggers, Views observe state
case RouteID.locationPermission:
    let locationPermissionView = LocationPermissionInfoView(
        viewModel: LocationPermissionInfoViewModelImpl(
            manager: resolver.resolve(LocationPermissionManaging.self)!
        )
    )
    presentViewModally(from: from, view: locationPermissionView)

// ViewModel observes manager state reactively
manager.locationStatusSubject
    .asPublisher()
    .sink(receiveValue: { [weak self] status in
        self?.accessDenied = (status == .denied)
        if status == .authorizedWhenInUse {
            self?.shouldDismiss = true
        }
    })
```

#### Key Implementation Details

##### 1. Bridge Usage in Practice
```swift
class LocationPermissionInfoViewModelImpl: LocationPermissionInfoViewModel {
    private func bind() {
        // Bridge RxSwift BehaviorSubject to Combine
        manager.locationStatusSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] status in
                self?.accessDenied = (status == .denied)
            })
            .store(in: &cancellables)
        
        // Bridge look and feel repository
        lookAndFeelRepository.isDarkModeSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .assign(to: &$isDarkMode)
    }
}
```

##### 2. Dependency Injection Updates
```swift
// Updated DI registration for new ViewModel
container.register((any LocationPermissionInfoViewModel).self) { r in
    LocationPermissionInfoViewModelImpl(
        manager: r.resolve(LocationPermissionManaging.self)!,
        logger: r.resolve(FileLogger.self)!,
        lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!
    )
}.inObjectScope(.transient)

// SwiftUI View registration
container.register(LocationPermissionInfoView.self) { r in
    LocationPermissionInfoView(
        viewModel: r.resolve((any LocationPermissionInfoViewModel).self)!
    )
}.inObjectScope(.transient)
```

##### 3. Reactive State Management
```swift
class LocationPermissionInfoViewModelImpl: LocationPermissionInfoViewModel {
    @Published var isDarkMode: Bool = false
    @Published var accessDenied: Bool = false
    @Published var shouldDismiss: Bool = false
    
    func handlePrimaryAction() {
        if accessDenied {
            manager.openSettings()
        } else {
            manager.grantPermission()
        }
    }
}
```

#### Benefits of This Migration Pattern

1. **Declarative UI**: SwiftUI provides cleaner, more maintainable UI code
2. **Reactive State**: @Published properties automatically update UI
3. **Separation of Concerns**: ViewModel handles logic, View handles presentation
4. **Testability**: ViewModels can be easily unit tested
5. **Consistency**: All new features follow the same reactive pattern

#### Migration Checklist for Other Features

Use this pattern as a template for migrating other UIKit features:

- [ ] **Identify UIKit Controller**: Find the UIKit view controller to migrate
- [ ] **Create SwiftUI View**: Build equivalent SwiftUI view with declarative UI
- [ ] **Create Combine ViewModel**: Implement ViewModel with @Published properties
- [ ] **Use RxSwift Bridge**: Connect to legacy services using existing bridge methods
- [ ] **Update DI Registration**: Register new ViewModel and View in dependency injection
- [ ] **Update Router**: Simplify routing to only trigger, not pass values
- [ ] **Remove Callbacks**: Replace callback patterns with reactive observation
- [ ] **Test Integration**: Ensure bridge works correctly with legacy services

#### Future Refactoring Template

This Location Permission example serves as the blueprint for converting other features:

1. **Authentication flows**
2. **Settings screens**
3. **Network selection**
4. **Protocol switching**
5. **Plan upgrade flows**

Each should follow the same pattern: UIKit → SwiftUI + Combine ViewModel with RxSwift bridge integration.

---

**Key Takeaways:**
1. **Use existing bridge** - Connect Combine ViewModels to RxSwift services
2. **No RxSwift in ViewModels** - Strict Combine-only policy for new SwiftUI ViewModels
3. **Don't modify legacy services** - Use bridge to integrate with existing RxSwift managers
4. **Follow established patterns** - Use this Location Permission example as template
5. **Pure reactive approach** - Eliminate callbacks, use reactive observation
6. **Router simplification** - Routers trigger, Views observe state reactively

*This guide reflects the current migration strategy with a proven real-world example. Use the Location Permission pattern as a template for other feature migrations.*

## Real-World Migration Example 2: Push Notifications Popup

### Simplified Popup Migration Pattern

This second example demonstrates a **simpler migration pattern** for basic popup views without complex state management or parameter passing.

#### Key Migration Insights

**Code Reduction & Modernization:**
- **Before**: 188 lines across 3 files (UIKit controller + UI extension + RxSwift ViewModel)  
- **After**: 170 lines in 2 files (SwiftUI view + Combine ViewModel)
- **9% code reduction** with significantly improved maintainability

#### Critical Pattern Differences from Location Permission

##### 1. Dismissal Pattern Evolution
```swift
// ❌ Old: NotificationCenter-based dismissal
class PushNotificationViewModel: PushNotificationViewModelType {
    func cancel() {
        NotificationCenter.default.post(
            Notification(name: Notifications.dismissPushNotificationPermissionPopup)
        )
    }
}

// ✅ New: Reactive dismissal with SwiftUI Environment
struct PushNotificationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: PushNotificationViewModelImpl
    
    var body: some View {
        // UI code...
        .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
            if shouldDismiss {
                dismiss()
            }
        }
    }
}

final class PushNotificationViewModelImpl: PushNotificationViewModel {
    @Published var shouldDismiss: Bool = false
    
    func enableNotifications() {
        pushNotificationsManager.askForPushNotificationPermission()
        shouldDismiss = true  // Reactive dismissal trigger
    }
}
```

##### 2. Dependency Injection Simplification
```swift
// ✅ New: Direct SwiftUI View registration (simpler than Location Permission)
container.register(PushNotificationView.self) { r in
    PushNotificationView(viewModel: PushNotificationViewModelImpl(
        logger: r.resolve(FileLogger.self)!,
        lookAndFeelRepository: r.resolve(LookAndFeelRepositoryType.self)!,
        pushNotificationsManager: r.resolve(PushNotificationManager.self)!)
    )
}.inObjectScope(.transient)
```

##### 3. Router Conversion
```swift
// ✅ Clean router conversion (no parameters needed)
case .pushNotifications:
    let pushNotificationView = Assembler.resolve(PushNotificationView.self)
    presentViewModally(from: from, view: pushNotificationView)
    return
```

#### When to Use This Simpler Pattern

**Use Push Notifications pattern for:**
- Simple popup views with basic user actions
- Views that don't require complex state management
- Straightforward permission requests or confirmations
- Views with minimal external dependencies

**Use Location Permission pattern for:**
- Complex state transitions and parameter passing
- Views requiring dedicated state managers
- Multi-step workflows with external coordination

#### Migration Decision Matrix

| Feature Type | Use Pattern | Key Indicators |
|--------------|-------------|----------------|
| **Simple Popups** | Push Notifications | Basic actions, no state sharing, direct dismissal |
| **Permission Flows** | Location Permission | Complex state, parameter passing, external coordination |
| **Settings Screens** | Location Permission + State Manager | Multiple parameters, persistent state |
| **Authentication** | Location Permission + State Manager | Multi-step flows, shared state |

## Advanced Migration Patterns: State Management Architecture

### State Manager Pattern for Complex Parameter Passing

**Problem**: Parameter passing through RouteID creates tight coupling and complex state management.

**Solution**: Use dedicated state managers with reactive patterns to eliminate parameter passing.

#### Implementation Pattern

```swift
// ❌ Poor: Passing parameters through router
enum RouteID {
    case enterCredentials(config: CustomConfigModel, isUpdating: Bool)
}

// Router passes parameters directly
case let .enterCredentials(config, isUpdating):
    let vc = EnterCredentialsViewController()
    vc.config = config
    vc.isUpdating = isUpdating

// ✅ Better: Clean router + state manager
enum RouteID {
    case enterCredentials // Clean, no parameters
}

// State manager holds reactive state
protocol CustomConfigStateManaging {
    var currentConfigSubject: BehaviorSubject<CustomConfigModel?> { get }
    var isUpdatingSubject: BehaviorSubject<Bool> { get }
    
    func setCurrentConfig(_ config: CustomConfigModel, isUpdating: Bool)
    func clearCurrentConfig()
}

class CustomConfigStateManager: CustomConfigStateManaging {
    let currentConfigSubject = BehaviorSubject<CustomConfigModel?>(value: nil)
    let isUpdatingSubject = BehaviorSubject<Bool>(value: false)
    
    func setCurrentConfig(_ config: CustomConfigModel, isUpdating: Bool) {
        currentConfigSubject.onNext(config)
        isUpdatingSubject.onNext(isUpdating)
    }
    
    func clearCurrentConfig() {
        currentConfigSubject.onNext(nil)
        isUpdatingSubject.onNext(false)
    }
}
```

#### ViewModel Integration

```swift
// ViewModel subscribes to state manager reactively
class EnterCredentialsViewModelImpl: EnterCredentialsViewModel {
    private let customConfigStateManager: CustomConfigStateManaging
    private var displayingCustomConfig: CustomConfigModel?
    
    private func bind() {
        // Subscribe to current config changes
        customConfigStateManager.currentConfigSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] config in
                self?.displayingCustomConfig = config
                self?.title = config?.name ?? ""
                self?.username = config?.username?.base64Decoded() ?? ""
                self?.password = config?.password?.base64Decoded() ?? ""
            })
            .store(in: &cancellables)
        
        // Subscribe to updating state changes
        customConfigStateManager.isUpdatingSubject
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: { [weak self] isUpdating in
                self?.isUpdating = isUpdating
            })
            .store(in: &cancellables)
    }
}
```

#### Usage in Legacy Code

```swift
// Legacy controllers set state before routing
customConfigStateManager.setCurrentConfig(config, isUpdating: true)
popupRouter?.routeTo(to: .enterCredentials, from: self)

// Legacy bindings integration
customConfigPickerViewModel.showEditCustomConfigTrigger.subscribe(onNext: {
    self.customConfigStateManager.setCurrentConfig($0, isUpdating: true)
    self.popupRouter?.routeTo(to: .enterCredentials, from: self)
}).disposed(by: disposeBag)
```

#### Benefits of State Manager Pattern

1. **Eliminates Parameter Passing**: Router IDs become clean enums without parameters
2. **Reactive State Management**: ViewModels observe state changes reactively
3. **Separation of Concerns**: State management separate from routing logic
4. **Testability**: State managers can be easily mocked and tested
5. **Consistency**: All state changes flow through reactive streams

#### DI Configuration

```swift
// Register state manager as singleton
container.register(CustomConfigStateManaging.self) { r in
    CustomConfigStateManager(logger: r.resolve(FileLogger.self)!)
}.inObjectScope(.container)

// Inject into ViewModels
container.register((any EnterCredentialsViewModel).self) { r in
    EnterCredentialsViewModelImpl(
        customConfigStateManager: r.resolve(CustomConfigStateManaging.self)!
    )
}.inObjectScope(.transient)

// Inject into MainViewController for legacy integration
container.register(MainViewController.self) { _ in
    MainViewController()
}.initCompleted { r, vc in
    vc.customConfigStateManager = r.resolve(CustomConfigStateManaging.self)!
}
```

#### When to Use State Manager Pattern

Use this pattern when:
- Multiple parameters need to be passed through routing
- State needs to be shared between different ViewModels
- Complex state transitions require coordination
- Legacy code needs to trigger SwiftUI views with data

#### Migration Checklist for State Management

- [ ] **Identify Parameter Passing**: Find RouteID cases with parameters
- [ ] **Create State Manager**: Implement reactive state management protocol
- [ ] **Update RouteID**: Remove parameters from router enum
- [ ] **Update ViewModel**: Subscribe to state manager using RxSwift bridge
- [ ] **Update Legacy Integration**: Set state before routing
- [ ] **Register in DI**: Configure state manager as singleton
- [ ] **Test Integration**: Verify state flows correctly between components

This pattern eliminates architectural complexity while maintaining clean separation between routing and state management.

---

## Real-World Migration Example 3: Repository Conversion (RxSwift → Combine)

### Repository Migration Pattern

This example demonstrates how to convert repositories from RxSwift to pure Combine, based on the **ShakeDataRepository** conversion completed on 2025-10-07.

#### Migration Overview

**Goal**: Convert repositories from RxSwift to Combine while maintaining compatibility with existing ViewModels and removing RxSwift bridge dependencies.

**Pattern**: Repository Layer Conversion
- **Before**: Repository uses RxSwift (`Single<T>`, `Observable<T>`, `DisposeBag`)
- **After**: Repository uses Combine (`AnyPublisher<T, Error>`, `Future`, no DisposeBag)
- **Impact**: ViewModels remove `.asPublisher()` bridge calls and use publishers directly

---

### Step-by-Step Repository Migration

#### Phase 1: Protocol Conversion

**Before (RxSwift):**
```swift
import Foundation
import RxSwift

protocol ShakeDataRepository {
    var currentScore: Int { get }

    func getLeaderboardScores() -> Single<[ShakeForDataScore]>
    func recordShakeForDataScore(score: Int) -> Single<String>
    func updateCurrentScore(_ score: Int)
}
```

**After (Combine):**
```swift
import Foundation
import Combine

protocol ShakeDataRepository {
    var currentScore: Int { get }

    func getLeaderboardScores() -> AnyPublisher<[ShakeForDataScore], Error>
    func recordShakeForDataScore(score: Int) -> AnyPublisher<String, Error>
    func updateCurrentScore(_ score: Int)
}
```

**Key Changes:**
- Replace `import RxSwift` with `import Combine`
- Convert `Single<T>` → `AnyPublisher<T, Error>`
- Keep synchronous methods unchanged

---

#### Phase 2: Implementation Conversion

**Before (RxSwift):**
```swift
import Foundation
import RxSwift

class ShakeDataRepositoryImpl: ShakeDataRepository {
    var currentScore: Int = 0

    private let apiManager: APIManager
    private let sessionManager: SessionManager
    private let disposeBag = DisposeBag()

    init(apiManager: APIManager, sessionManager: SessionManager) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
    }

    func getLeaderboardScores() -> Single<[ShakeForDataScore]> {
        return Single.create { single in
            let task = Task {
                do {
                    let scoreList = try await self.apiManager.getShakeForDataLeaderboard()
                    single(.success(scoreList.scores))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func recordShakeForDataScore(score: Int) -> Single<String> {
        guard let userID = sessionManager.session?.userId else {
            return Single.error(Errors.sessionIsInvalid)
        }

        return Single.create { single in
            let task = Task {
                do {
                    let apiMessage = try await self.apiManager.recordShakeForDataScore(score: score, userID: userID)
                    single(.success(apiMessage.message))
                } catch {
                    single(.failure(error))
                }
            }

            return Disposables.create {
                task.cancel()
            }
        }
    }

    func updateCurrentScore(_ score: Int) {
        currentScore = score
    }
}
```

**After (Combine):**
```swift
import Foundation
import Combine

class ShakeDataRepositoryImpl: ShakeDataRepository {
    var currentScore: Int = 0

    private let apiManager: APIManager
    private let sessionManager: SessionManager

    init(apiManager: APIManager, sessionManager: SessionManager) {
        self.apiManager = apiManager
        self.sessionManager = sessionManager
    }

    func getLeaderboardScores() -> AnyPublisher<[ShakeForDataScore], Error> {
        return Future { promise in
            Task {
                do {
                    let scoreList = try await self.apiManager.getShakeForDataLeaderboard()
                    promise(.success(scoreList.scores))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func recordShakeForDataScore(score: Int) -> AnyPublisher<String, Error> {
        guard let userID = sessionManager.session?.userId else {
            return Fail(error: Errors.sessionIsInvalid)
                .eraseToAnyPublisher()
        }

        return Future { promise in
            Task {
                do {
                    let apiMessage = try await self.apiManager.recordShakeForDataScore(score: score, userID: userID)
                    promise(.success(apiMessage.message))
                } catch {
                    promise(.failure(error))
                }
            }
        }
        .eraseToAnyPublisher()
    }

    func updateCurrentScore(_ score: Int) {
        currentScore = score
    }
}
```

**Key Changes:**
- Replace `import RxSwift` with `import Combine`
- Remove `disposeBag` property (not needed)
- Replace `Single.create` with `Future`
- Replace `Single.error()` with `Fail(error:)`
- Remove `Disposables.create` (task management is automatic)
- Add `.eraseToAnyPublisher()` to match protocol

---

#### Phase 3: Update ViewModel Call Sites

**Before (Using RxSwift Bridge):**
```swift
// In ViewModel
repository.recordShakeForDataScore(score: finalScore)
    .asPublisher()  // ⚠️ Bridge call needed
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { _ in },
          receiveValue: { [weak self] message in
        self?.apiMessage = message
    })
    .store(in: &cancellables)
```

**After (Direct Combine):**
```swift
// In ViewModel
repository.recordShakeForDataScore(score: finalScore)
    // ✅ No .asPublisher() needed!
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { _ in },
          receiveValue: { [weak self] message in
        self?.apiMessage = message
    })
    .store(in: &cancellables)
```

**Key Changes:**
- Remove `.asPublisher()` bridge call
- Direct Combine subscription

---

### Testing Strategy for Repository Conversion

#### Test Infrastructure Setup

**1. Create Sample Data File**

Create `WindscribeTests/SampleData/SampleData[RepositoryName].swift`:

```swift
//  SampleDataShakeData.swift
import Foundation

class SampleDataShakeData {
    static let leaderboardJSON = """
    {
        "data": {
            "leaderboard": [
                {
                    "score": 100,
                    "user": "player1",
                    "you": 0
                }
            ]
        }
    }
    """

    static let apiMessageSuccessJSON = """
    {
        "data": {
            "message": "Score recorded successfully",
            "success": 1
        }
    }
    """
}
```

**2. Create Mock Dependencies**

Create `WindscribeTests/Mocks/Mock[DependencyName].swift`:

```swift
//  MockAPIManager.swift
import Foundation
@testable import Windscribe

class MockAPIManager: APIManager {
    var shouldThrowError = false
    var customError: Error = Errors.sessionIsInvalid

    // Mock storage
    var mockLeaderboard: Leaderboard?

    // Track calls
    var getLeaderboardCalled = false

    func reset() {
        shouldThrowError = false
        mockLeaderboard = nil
        getLeaderboardCalled = false
    }

    // Implement only needed methods
    func getShakeForDataLeaderboard() async throws -> Leaderboard {
        getLeaderboardCalled = true

        if shouldThrowError {
            throw customError
        }

        guard let leaderboard = mockLeaderboard else {
            let jsonData = SampleDataShakeData.leaderboardJSON.data(using: .utf8)!
            return try! JSONDecoder().decode(Leaderboard.self, from: jsonData)
        }

        return leaderboard
    }

    // All other protocol methods: fatalError("Not implemented for tests")
    func getSession(_ appleID: String?) async throws -> Session {
        fatalError("Not implemented for this test")
    }
    // ... etc for all other methods
}
```

**Important**: Mock ALL protocol methods, but only implement those needed for the repository tests.

**3. Create Comprehensive Tests**

Create `WindscribeTests/Repository/[RepositoryName]Tests.swift`:

```swift
//  ShakeDataRepositoryTests.swift
import Foundation
import Combine
import Swinject
@testable import Windscribe
import XCTest

class ShakeDataRepositoryTests: XCTestCase {

    var mockContainer: Container!
    var repository: ShakeDataRepository!
    var mockAPIManager: MockAPIManager!
    var mockSessionManager: MockSessionManager!
    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        mockContainer = Container()
        mockAPIManager = MockAPIManager()
        mockSessionManager = MockSessionManager()

        // Register mocks
        mockContainer.register(APIManager.self) { _ in
            return self.mockAPIManager
        }.inObjectScope(.container)

        mockContainer.register(SessionManager.self) { _ in
            return self.mockSessionManager
        }.inObjectScope(.container)

        // Register repository
        mockContainer.register(ShakeDataRepository.self) { r in
            return ShakeDataRepositoryImpl(
                apiManager: r.resolve(APIManager.self)!,
                sessionManager: r.resolve(SessionManager.self)!
            )
        }.inObjectScope(.container)

        repository = mockContainer.resolve(ShakeDataRepository.self)!
    }

    override func tearDown() {
        cancellables.removeAll()
        mockAPIManager.reset()
        mockSessionManager.reset()
        mockContainer = nil
        repository = nil
        super.tearDown()
    }

    // MARK: - Success Tests

    func test_getLeaderboardScores_success_shouldReturnScores() {
        let expectation = self.expectation(description: "Get leaderboard scores")

        repository.getLeaderboardScores()
            .sink(receiveCompletion: { completion in
                if case .failure(let error) = completion {
                    XCTFail("Expected success, but got error: \(error)")
                }
            }, receiveValue: { scores in
                XCTAssertTrue(self.mockAPIManager.getLeaderboardCalled)
                XCTAssertEqual(scores.count, 1)
                XCTAssertEqual(scores[0].score, 100)
                expectation.fulfill()
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - Failure Tests

    func test_getLeaderboardScores_apiFailure_shouldReturnError() {
        mockAPIManager.shouldThrowError = true
        mockAPIManager.customError = Errors.noDataReceived

        let expectation = self.expectation(description: "API failure")

        repository.getLeaderboardScores()
            .sink(receiveCompletion: { completion in
                if case .failure = completion {
                    XCTAssertTrue(self.mockAPIManager.getLeaderboardCalled)
                    expectation.fulfill()
                }
            }, receiveValue: { _ in
                XCTFail("Expected error, but got success")
            })
            .store(in: &cancellables)

        waitForExpectations(timeout: 1.0, handler: nil)
    }

    // MARK: - Edge Cases

    func test_updateCurrentScore_shouldUpdateValue() {
        XCTAssertEqual(repository.currentScore, 0)

        repository.updateCurrentScore(150)

        XCTAssertEqual(repository.currentScore, 150)
    }
}
```

---

### Repository Conversion Checklist

Use this checklist for each repository conversion:

#### Phase 1: Repository Code Changes
- [ ] **Update Protocol**: Replace `import RxSwift` with `import Combine`
- [ ] **Convert Return Types**: `Single<T>` → `AnyPublisher<T, Error>`
- [ ] **Update Implementation**: Replace `import RxSwift` with `import Combine`
- [ ] **Remove DisposeBag**: Delete `private let disposeBag = DisposeBag()`
- [ ] **Convert Methods**: `Single.create` → `Future`
- [ ] **Convert Errors**: `Single.error()` → `Fail(error:)`
- [ ] **Add Type Erasure**: Add `.eraseToAnyPublisher()` to all methods

#### Phase 2: ViewModel Updates
- [ ] **Find All Usages**: Search for all places using the repository
- [ ] **Remove Bridge Calls**: Delete `.asPublisher()` from repository method calls
- [ ] **Verify Compilation**: Ensure all ViewModels compile correctly

#### Phase 3: Testing
- [ ] **Create Sample Data**: Add JSON test data to `SampleData` folder
- [ ] **Create Mocks**: Implement mocks for all dependencies
- [ ] **Write Tests**: Cover success cases, failures, edge cases
- [ ] **Add to Xcode**: Add test files to `WindscribeTests` target
- [ ] **Run Tests**: Verify all tests pass

#### Phase 4: Verification
- [ ] **Check Targets**: Verify changes in both iOS and tvOS targets
- [ ] **Remove Unused Imports**: Clean up any remaining RxSwift imports
- [ ] **Document Changes**: Update any relevant documentation

---

### Common Conversion Patterns

#### Pattern 1: Async/Await Wrapped in Publishers

```swift
// RxSwift
func getData() -> Single<Data> {
    return Single.create { single in
        let task = Task {
            do {
                let data = try await self.api.fetchData()
                single(.success(data))
            } catch {
                single(.failure(error))
            }
        }
        return Disposables.create { task.cancel() }
    }
}

// Combine
func getData() -> AnyPublisher<Data, Error> {
    return Future { promise in
        Task {
            do {
                let data = try await self.api.fetchData()
                promise(.success(data))
            } catch {
                promise(.failure(error))
            }
        }
    }
    .eraseToAnyPublisher()
}
```

#### Pattern 2: Guard Error Handling

```swift
// RxSwift
func process() -> Single<Result> {
    guard let value = someValue else {
        return Single.error(Errors.missingValue)
    }
    // ... rest of implementation
}

// Combine
func process() -> AnyPublisher<Result, Error> {
    guard let value = someValue else {
        return Fail(error: Errors.missingValue)
            .eraseToAnyPublisher()
    }
    // ... rest of implementation
}
```

#### Pattern 3: Synchronous Methods

```swift
// Both RxSwift and Combine - No changes needed
func updateValue(_ value: Int) {
    currentValue = value
}

var currentValue: Int { get }
```

---

### Test Coverage Guidelines

**Minimum test coverage for each repository:**

1. **Success Cases (per method)**
   - Happy path with valid data
   - Verify return values match expected data
   - Verify dependencies were called correctly

2. **Failure Cases (per method)**
   - API/network failures
   - Invalid session/authentication errors
   - Missing required data

3. **Edge Cases**
   - Empty results
   - Null/optional handling
   - Boundary values (zero, negative, very large numbers)

4. **Integration Tests**
   - Multiple method calls in sequence
   - Concurrent operations
   - State persistence across calls

**Target**: 15-25 tests per repository (depending on complexity)

---

### Migration Benefits

**Before Repository Conversion:**
- ViewModels use `.asPublisher()` bridge
- Repository depends on RxSwift
- DisposeBag memory management required
- Mixed reactive paradigms

**After Repository Conversion:**
- ViewModels use direct Combine publishers
- Repository is pure Combine
- Automatic Combine cancellation
- Consistent reactive architecture

**Result**: Cleaner code, better performance, easier maintenance

---

### Real-World Example: ShakeDataRepository

**Files Changed:**
1. `ShakeDataRepository.swift` (protocol)
2. `ShakeDataRepositoryImpl.swift` (implementation)
3. `ShakeForDataResultsViewModel.swift` (removed bridge)
4. `ShakeForDataLeaderboardModel.swift` (removed bridge)

**Files Created:**
1. `MockAPIManager.swift` (39 protocol methods)
2. `MockSessionManager.swift` (7 protocol methods)
3. `SampleDataLeaderboard.swift` (test JSON data)
4. `ShakeDataRepositoryTests.swift` (24 test cases)

**Results:**
- ✅ 24/24 tests passing
- ✅ No RxSwift dependencies in repository layer
- ✅ ViewModels simplified (no bridge calls)
- ✅ Full Combine integration

---

**Key Takeaway**: Repository conversion is straightforward when following this pattern. The most time-consuming part is creating comprehensive mocks and tests, but this ensures reliability and prevents regressions.
