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