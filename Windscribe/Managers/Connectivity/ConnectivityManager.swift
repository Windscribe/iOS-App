import Combine
import Swinject
import Foundation
import Network

protocol ConnectivityManager {
    var network: CurrentValueSubject<AppNetwork, Never> { get }
    func getNetwork() -> AppNetwork
    func refreshNetwork()
    func internetConnectionAvailable() -> Bool
    func getWifiSSID() -> String?
    func awaitNetwork(maxTime: Double) async throws
}

/// Manages network connectivity state using reachability and network path monitor.
class ConnectivityManagerImpl: ConnectivityManager {
    func getWifiSSID() -> String? {
        return network.value.name
    }

    private let logger: FileLogger
    private let bridgeAPI: WSNetBridgeAPIType

    /// Observe this subject to get network change events.
    let network = CurrentValueSubject<AppNetwork, Never>(AppNetwork(.disconnected))
    private let monitor = NWPathMonitor()
    private var lastEvent: AppNetwork?
    private var lastValidNetworkName: String?

    /// Debounces the connected → not-connected edge to absorb the brief
    /// `.unsatisfied` gap that iOS reports during a Wi-Fi SSID handoff.
    /// A real disconnect still propagates once the timer fires; a transient
    /// blip is superseded by the next emit and never reaches downstream.
    private static let connectedToNotConnectedDebounce: TimeInterval = 1.5

    /// Debounces the brief Wi-Fi → Cellular → Wi-Fi sequence iOS can emit while
    /// switching SSIDs. Without this, downstream reconnect logic can pick the
    /// Cellular/global protocol before the destination Wi-Fi SSID is available.
    private static let wifiToCellularHandoffDebounce: TimeInterval = 1.5
    private var pendingEmit: DispatchWorkItem?
    private var pendingEmitToken: UUID?

    init(logger: FileLogger,
         bridgeAPI: WSNetBridgeAPIType) {
        self.logger = logger
        self.bridgeAPI = bridgeAPI
        registerNetworkPathMonitor()
    }

    /// Gets current network Infomation
    func getNetwork() -> AppNetwork {
        return network.value
    }

    func refreshNetwork() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.refreshNetworkPathMonitor(path: self.monitor.currentPath)
        }
    }

    /// Adds listener to network path monitor and builds network change events.
    private func registerNetworkPathMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.refreshNetworkPathMonitor(path: path)
            }
        }
        let queue = DispatchQueue(label: "monitor queue", qos: .userInitiated)
        monitor.start(queue: queue)
    }

    private func refreshNetworkPathMonitor(path: NWPath) {
        let networkType = getNetworkType(path: path)
        Task {
            var networkName = await getNetworkName(networkType: networkType)
            if networkName == nil && networkType == .wifi {
                networkName = self.lastValidNetworkName
            }

            if networkName != nil && networkType == .wifi {
                self.lastValidNetworkName = networkName
            }

            let appNetwork = AppNetwork(
                self.getNetworkStatus(path: path),
                networkType: networkType,
                name: networkName,
                isVPN: self.isVPN(path: path)
            )
            await MainActor.run {
                self.scheduleEmit(appNetwork)
            }
        }
    }

    @MainActor
    private func scheduleEmit(_ appNetwork: AppNetwork) {
        pendingEmit?.cancel()
        pendingEmit = nil
        pendingEmitToken = nil
        guard lastEvent != appNetwork else { return }

        if Self.shouldDebounceWifiToCellularHandoff(previous: lastEvent, next: appNetwork) {
            logger.logD("Connectivity", "Debouncing possible Wi-Fi to Cellular handoff: \(appNetwork.description)")
            schedulePendingEmit(appNetwork, delay: Self.wifiToCellularHandoffDebounce)
            return
        }

        let wasConnected = lastEvent?.status == .connected
        if appNetwork.status == .connected || !wasConnected {
            emit(appNetwork)
            return
        }

        schedulePendingEmit(appNetwork, delay: Self.connectedToNotConnectedDebounce)
    }

    static func shouldDebounceWifiToCellularHandoff(previous: AppNetwork?, next: AppNetwork) -> Bool {
        guard previous?.status == .connected, next.status == .connected else { return false }
        return previous?.networkType == .wifi && next.networkType == .cellular
    }

    @MainActor
    private func schedulePendingEmit(_ appNetwork: AppNetwork, delay: TimeInterval) {
        let token = UUID()
        pendingEmitToken = token

        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.pendingEmitToken == token else { return }
            self.pendingEmit = nil
            self.pendingEmitToken = nil
            self.emit(appNetwork)
        }
        pendingEmit = work

        DispatchQueue.main.asyncAfter(
            deadline: .now() + delay,
            execute: work
        )
    }

    @MainActor
    private func emit(_ appNetwork: AppNetwork) {
        guard lastEvent != appNetwork else { return }
        lastEvent = appNetwork
        logger.logD("Connectivity", appNetwork.description)
        network.send(appNetwork)
        WSNet.instance().setConnectivityState(appNetwork.status == .connected)
        NotificationCenter.default.post(Notification(name: Notifications.reachabilityChanged))
    }

    func awaitNetwork(maxTime: Double) async throws {
        let timeout: TimeInterval = maxTime
        let startTime = Date()
        while getNetwork().status != .connected {
            if Date().timeIntervalSince(startTime) > timeout {
                return
            }
            try? await Task.sleep(nanoseconds: 500_000_000)
        }
    }

    /// Returns network status from NWPath
    private func getNetworkStatus(path: NWPath) -> NetworkStatus {
        switch path.status {
        case .satisfied:
            return .connected
        case .unsatisfied:
            return .disconnected
        // Changes to .satisfied once VPN connection is restored or kill switch is turned off.
        case .requiresConnection:
            return .requiresVPN
        @unknown default:
            return .connected
        }
    }

    /// Returns network type from NWPath
    private func getNetworkType(path: NWPath) -> NetworkType {
        for interface in path.availableInterfaces {
            if interface.name.hasPrefix("pdp") {
                return .cellular
            }
            if interface.name.hasPrefix("en") {
                return .wifi
            }
        }
        if path.status == .satisfied {
            if path.usesInterfaceType(.cellular) {
                return .cellular
            }
            if path.usesInterfaceType(.wifi) {
                return .wifi
            }
        }
        return .none
    }

    /// Returns  if VPN is active.
    /// - Note: This function solely relies on network interface names so may be not as reliable as checking with vpn manager.
    private func isVPN(path: NWPath) -> Bool {
        return path.availableInterfaces.first { i in
            i.name.starts(with: "ipsec") || i.name.starts(with: "utun")
        }.map { _ in
            true
        } ?? false
    }

    /// Returns  optional network carier name or SSID for network type
    private func getNetworkName(networkType: NetworkType) async -> String? {
        switch networkType {
        case .cellular:
            return getCellularNetworkName()
        case .wifi:
            return await getSsidFromNeHotspotHelper()
        case .none:
            return nil
        }
    }

    /// Returns carrier name for cellular network
    ///  - Note: This api was depcreated in iOS 16.0 and returns "Cellular"
    private func getCellularNetworkName() -> String {
        return "Cellular"
    }

    func internetConnectionAvailable() -> Bool {
        return network.value.status == .connected
    }
}
