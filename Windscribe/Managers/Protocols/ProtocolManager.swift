//
//  ProtocolManager.swift
//  Windscribe
//
//  Created by Thomas on 14/10/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import Swinject
import Combine

protocol ProtocolManagerType {
    var goodProtocol: ProtocolPort? { get set }
    var resetGoodProtocolTime: Date? { get set }

    var currentProtocolSubject: CurrentValueSubject<ProtocolPort?, Never> { get }
    var connectionProtocolSubject: CurrentValueSubject<(protocolPort: ProtocolPort, connectionType: ConnectionType)?, Never> { get }
    var showProtocolSwitchTrigger: PassthroughSubject<Void, Never> { get }
    var showAllProtocolsFailedTrigger: PassthroughSubject<Void, Never> { get }

    var displayProtocolsSubject: CurrentValueSubject<[DisplayProtocolPort], Never> { get }

    var failOverTimerCompletedSubject: PassthroughSubject<Void, Never> { get }

    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async
    func getRefreshedProtocols() async -> [DisplayProtocolPort]
    func getDisplayProtocols() async -> [DisplayProtocolPort]
    func getNextProtocol() async -> ProtocolPort
    func getProtocol() -> ProtocolPort
    func onProtocolFail() async
    func onUserSelectProtocol(proto: ProtocolPort, connectionType: ConnectionType)
    func resetGoodProtocol()
    func onConnectStateChange(state: NEVPNStatus)
    func scheduleTimer()
    func saveCurrentWifiNetworks()
    func cancelFailoverTimer()
}

class ProtocolManager: ProtocolManagerType {
    private let logger: FileLogger
    private var cancellables = Set<AnyCancellable>()
    private let connectivity: ConnectivityManager
    private let localDatabase: LocalDatabase
    private let securedNetwork: SecuredNetworkRepository
    private let preferences: Preferences
    private let locationManager: LocationsManager
    private let vpnStateRepository: VPNStateRepository

    private let defaultCountdownTime = 10
    private var countdownTimer: DispatchSourceTimer?
    private var countdownSeconds: Int = 10

    // MARK: - Properties

    /// Default protocol
    let defaultProtocol = ProtocolPort(wireGuard, DefaultValues.port)
    /// Provides concurrent access to protocol list.
    private let accessQueue = DispatchQueue(label: "protocolManagerAccessQueve", attributes: .concurrent)
    /// List of Protocols in ordered by priority
    private(set) var protocolsToConnectList: [DisplayProtocolPort] = [] {
        didSet {
            displayProtocolsSubject.send(protocolsToConnectList)
        }
    }
    /// App selected this protocol automatcally or user selected it
    private var userSelected: ProtocolPort?
    /// Timer to reset good protocol
    private var scheduledTimer: Timer!
    /// Last successful protocol
    var goodProtocol: ProtocolPort?
    var resetGoodProtocolTime: Date?
    var failoverNetworkName: NetworkType = .none
    var manualProtocol: String = DefaultValues.protocol
    var manualPort: String = DefaultValues.port
    var connectionMode = DefaultValues.connectionMode

    let currentProtocolSubject = CurrentValueSubject<ProtocolPort?, Never>(nil)
    let connectionProtocolSubject = CurrentValueSubject<(protocolPort: ProtocolPort, connectionType: ConnectionType)?, Never>(nil)
    let displayProtocolsSubject = CurrentValueSubject<[DisplayProtocolPort], Never>([])
    let showProtocolSwitchTrigger = PassthroughSubject<Void, Never>()
    let showAllProtocolsFailedTrigger = PassthroughSubject<Void, Never>()

    let failOverTimerCompletedSubject = PassthroughSubject<Void, Never>()

    init(logger: FileLogger,
         connectivity: ConnectivityManager,
         preferences: Preferences,
         securedNetwork: SecuredNetworkRepository,
         localDatabase: LocalDatabase,
         locationManager: LocationsManager,
         vpnStateRepository: VPNStateRepository) {
        self.logger = logger
        self.connectivity = connectivity
        self.preferences = preferences
        self.securedNetwork = securedNetwork
        self.localDatabase = localDatabase
        self.locationManager = locationManager
        self.vpnStateRepository = vpnStateRepository

        logger.logI("ProtocolManager", "Starting connection manager.")
        bindData()
        Task {
            await refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    func bindData() {
        preferences.getConnectionMode()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] mode in
                self?.connectionMode = mode ?? DefaultValues.connectionMode
            }
            .store(in: &cancellables)

        preferences.getSelectedProtocol()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preferredProtocol in
                self?.manualProtocol = preferredProtocol ?? DefaultValues.protocol
            }
            .store(in: &cancellables)

        preferences.getSelectedPort()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] preferredPort in
                self?.manualPort = preferredPort ?? DefaultValues.port
            }
            .store(in: &cancellables)

        connectivity.network
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ProtocolManager", "Connectivity Network error: \(error)")
                }
            }, receiveValue: { [weak self] network in
                Task { @MainActor in
                    await self?.refreshProtocols(shouldReset: false, shouldReconnect: false)
                }
            })
            .store(in: &cancellables)

        securedNetwork.networks
            .asPublisher()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.logger.logE("ProtocolManager", "SecuredNetworks Network error: \(error)")
                }
            }, receiveValue: { [weak self] network in
                Task { @MainActor in
                    self?.logger.logD("ProtocolManager", "Secured Networks : \(network)")
                    await self?.refreshProtocols(shouldReset: false, shouldReconnect: false)
                }
            })
            .store(in: &cancellables)
    }

    // MARK: - Actions

    /// reloads the protocols
    /// change their priority based on user settings.
    /// append port
    /// Priority order [Connected, User selected, Preferred, Manual, Good, Failed]
    ///
    @MainActor
    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async {
        await refreshProtocols(shouldReset: shouldReset, shouldReconnect: shouldReconnect, isFromFailover: false)
    }

    @MainActor
    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool, isFromFailover: Bool) async {
        if failoverNetworkName != .none && failoverNetworkName != connectivity.getNetwork().networkType {
            goodProtocol = nil
            userSelected = nil
            protocolsToConnectList.removeAll()
            getProtocolList()
        }
        failoverNetworkName = connectivity.getNetwork().networkType
        if shouldReset {
            getProtocolList()
            userSelected = nil
        }
        // Save all failed protocols
        let failedProtocols = protocolsToConnectList.filter { list in list.viewType == .fail }
        // Reset all protocol type to normal
        protocolsToConnectList.first { displayPortAndProtocol in
            displayPortAndProtocol.viewType == .connected
        }?.viewType = .normal

        if let goodProtocol = goodProtocol {
            appendPort(proto: goodProtocol.protocolName, port: goodProtocol.portName)
            setPriority(proto: goodProtocol.protocolName, type: .normal)
        }

        if connectionMode == Fields.Values.manual {
            logger.logD("ProtocolManager", "Manual protocol : \(manualProtocol)")
            appendPort(proto: manualProtocol, port: manualPort)
            setPriority(proto: manualProtocol, type: .normal)
        }
        WifiManager.shared.saveCurrentWifiNetworks()
        if let currentNetwork = securedNetwork.getCurrentNetwork(), currentNetwork.preferredProtocolStatus == true {
            let preferredProto = currentNetwork.preferredProtocol
            let preferredPort = currentNetwork.preferredPort
            appendPort(proto: preferredProto, port: preferredPort)
            setPriority(proto: preferredProto, type: .normal)
        }

        if let userSelected = userSelected {
            appendPort(proto: userSelected.protocolName, port: userSelected.portName)
            setPriority(proto: userSelected.protocolName, type: .normal)
        }

        for displayProtocol in failedProtocols {
            logger.logD("ProtocolManager", "Failed: \(displayProtocol.protocolPort.protocolName)")
            setPriority(proto: displayProtocol.protocolPort.protocolName, type: .fail)
        }

        let locationID = locationManager.getId()
        if !locationID.isEmpty,
           let locationType = locationManager.getLocationType(),
           locationType == .custom,
           let config = localDatabase.getCustomConfigs().first(where: { $0.id == locationID })?.getModel(),
           let protocolName = config.protocolType, let portName = config.port {
            appendPort(proto: protocolName, port: portName)
            setPriority(proto: protocolName, type: .normal)
        }

        if !isFromFailover, !shouldReconnect,
           let info = vpnStateRepository.vpnInfo.value, info.status == .connected {
            appendPort(proto: info.selectedProtocol, port: info.selectedPort)
            setPriority(proto: info.selectedProtocol, type: .connected)
        } else {
            protocolsToConnectList.first?.viewType = .nextUp(countdown: -1)
        }
        let log = "Protocols to connect List: " + protocolsToConnectList.map { "\($0.protocolPort.protocolName) \($0.protocolPort.portName) \($0.viewType)"}.joined(separator: ", ")
        logger.logI("ProtocolManager", log)

        let firstProtocol = getFirstProtocol()
        displayProtocolsSubject.send(protocolsToConnectList)
        currentProtocolSubject.send(firstProtocol)
        connectionProtocolSubject.send(shouldReconnect ? (protocolPort: firstProtocol, connectionType: .user) : nil)
    }

    func getRefreshedProtocols() async -> [DisplayProtocolPort] {
        await refreshProtocols(shouldReset: false, shouldReconnect: false)
        return protocolsToConnectList
    }

    func getDisplayProtocols() async -> [DisplayProtocolPort] {
        return protocolsToConnectList
    }

    private var called = false

    func getNextProtocol() async -> ProtocolPort {
        await refreshProtocols(shouldReset: false, shouldReconnect: false)
        return self.getFirstProtocol()
    }

    func getProtocol() -> ProtocolPort {
        getFirstProtocol()
    }

    /// Next protocol to connect.
    private func getFirstProtocol() -> ProtocolPort {
        accessQueue.sync {
            protocolsToConnectList.first.map { displayPort in
                displayPort.protocolPort
            } ?? defaultProtocol
        }
    }

    /// VPN state changed.
    func onConnectStateChange(state: NEVPNStatus) {
        accessQueue.async { [self] in
            userSelected = nil
            logger.logI("ProtocolManager", "Connection state changed to \(state).")
            if state == .connected {
                protocolsToConnectList.first { $0.viewType.isNextup
                }?.viewType = .connected
                protocolsToConnectList.filter { $0.viewType.isNextup }.forEach { $0.viewType = .normal }
            }
            if state == .disconnected {
                protocolsToConnectList.filter { $0.viewType.isNextup }.forEach { $0.viewType = .normal }
                protocolsToConnectList.first { $0.viewType == .connected
                }?.viewType = .normal
            }
        }
    }

    /// User/App selected this protocol to connect.
    func onUserSelectProtocol(proto: ProtocolPort, connectionType: ConnectionType) {
        logger.logI("ProtocolManager", "User selected \(proto) to connect.")
        stopCountdownTimer()
        userSelected = proto
        setPriority(proto: proto.protocolName)
        let firstProtocol = getFirstProtocol()
        currentProtocolSubject.send(firstProtocol)
        connectionProtocolSubject.send((protocolPort: firstProtocol, connectionType: connectionType))
    }

    /// Resetting good Protocol after 12 hours(43200 seconds).
    @objc func resetGoodProtocol() {
        if goodProtocol != nil {
            let diff = Date().timeIntervalSince(resetGoodProtocolTime ?? Date())
            if diff >= 43200 {
                logger.logI("ProtocolManager", "Resetting good Protocol after 12 hours.")
                Task { @MainActor in
                    await reset()
                    scheduledTimer.invalidate()
                }
            }
        }
    }

    /// Current protocol failed to connect, lower its priority.
    func onProtocolFail() async {
        userSelected = nil
        let failedProtocol = await getNextProtocol()
        logger.logI("ProtocolManager", "\(failedProtocol.protocolName) failed to connect.")
        setPriority(proto: failedProtocol.protocolName, type: .fail)
        if protocolsToConnectList.filter({ $0.viewType != .fail}).count <= 0 {
            logger.logI("ProtocolManager", "No more protocol left to connect.")
            await reset()
            showAllProtocolsFailedTrigger.send(())
        } else {
            await refreshProtocols(shouldReset: false, shouldReconnect: false, isFromFailover: true)
            startCountdownTimer()
        }
        currentProtocolSubject.send(getFirstProtocol())
    }

    func scheduleTimer() {
        scheduledTimer = Timer.scheduledTimer(timeInterval: 3600, target: self, selector: #selector(resetGoodProtocol), userInfo: nil, repeats: true)
    }

    func saveCurrentWifiNetworks() {
        WifiManager.shared.saveCurrentWifiNetworks()
    }

    // MARK: - Helper

    private func getAppSupportedProtocol() -> [String] {
        return TextsAsset.General.protocols
    }

    private func reset() async {
        userSelected = nil
        goodProtocol = nil
        protocolsToConnectList.removeAll()
        await refreshProtocols(shouldReset: true, shouldReconnect: false)
        return
    }

    private func setPriority(proto: String, type: ProtocolViewType = .normal) {
        accessQueue.sync {
            var copy = protocolsToConnectList
            if let index = copy.firstIndex(where: { displayPortAndProtocol in
                displayPortAndProtocol.protocolPort.protocolName == proto
            }) {
                let item = copy[index]
                item.viewType = type
                copy.remove(at: index)
                switch type {
                case .connected, .normal, .nextUp:
                    copy.insert(item, at: 0)
                default:
                    copy.append(item)
                }
            }
            protocolsToConnectList = copy
        }
    }

    private func appendPort(proto: String, port: String) {
        protocolsToConnectList.first { $0.protocolPort.protocolName == proto }?.protocolPort.portName = port
    }

    /// Protocol list in app preferred order.
    private func getProtocolList() {
        if localDatabase.getPortMap()?.isEmpty  ?? true {
            protocolsToConnectList = [
                DisplayProtocolPort(protocolPort: ProtocolPort("WireGuard", "443"), viewType: .normal),
                DisplayProtocolPort(protocolPort: ProtocolPort("IKEv2", "500"), viewType: .normal),
                DisplayProtocolPort(protocolPort: ProtocolPort("UDP", "443"), viewType: .normal),
                DisplayProtocolPort(protocolPort: ProtocolPort("TCP", "443"), viewType: .normal),
                DisplayProtocolPort(protocolPort: ProtocolPort("Stealth", "443"), viewType: .normal),
                DisplayProtocolPort(protocolPort: ProtocolPort("WStunnel", "443"), viewType: .normal)
            ]
            return
        }
        let listProtocol = getAppSupportedProtocol()
        var lstConnection: [ProtocolPort] = []
        for protocolName in listProtocol {
            if let lstPort = localDatabase.getPorts(protocolType: protocolName),
               let firstPort = lstPort.first {
                lstConnection.append((protocolName, firstPort))
            }
        }
        protocolsToConnectList = lstConnection.map { DisplayProtocolPort(protocolPort: $0, viewType: .normal) }
    }
}

// MARK: Countdown Timer Management
extension ProtocolManager {
    /// Starts the automatic failover countdown timer (10 seconds default)
    /// This is used in failure mode to automatically try the next protocol
    private func startCountdownTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            guard let proto = self.protocolsToConnectList.first(where: \.viewType.isNextup) else { return }

            self.countdownSeconds = self.defaultCountdownTime
            self.setPriority(proto: proto.protocolPort.protocolName,
                             type: .nextUp(countdown: self.countdownSeconds))

            // Cancel existing timer
            self.countdownTimer?.cancel()
            self.countdownTimer = nil

            // Start the new timer
            self.countdownTimer = DispatchSource.makeTimerSource(queue: DispatchQueue.main)
            self.countdownTimer?.schedule(deadline: .now() + 1.0, repeating: 1.0)
            self.countdownTimer?.setEventHandler { [weak self] in
                self?.updateCountdown()
            }
            self.countdownTimer?.resume()

            // Trigger subjects
            self.showProtocolSwitchTrigger.send(())
        }
    }

    private func updateCountdown() {
        guard let proto = self.protocolsToConnectList.first(where: \.viewType.isNextup) else {
            stopCountdownTimer()
            return
        }
        guard self.protocolsToConnectList.filter({ $0.viewType == .connected }).isEmpty else {
            self.setPriority(proto: proto.protocolPort.protocolName,type: .normal)
            stopCountdownTimer()
            return
        }

        countdownSeconds -= 1

        self.setPriority(proto: proto.protocolPort.protocolName,
                         type: .nextUp(countdown: self.countdownSeconds))

        if countdownSeconds <= 0 {
            logger.logI("ProtocolManager", "Countdown completed - triggering protocol switch")
            stopCountdownTimer()
            countdownCompleted()
        }
    }

    private func stopCountdownTimer() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            self.countdownTimer?.cancel()
            self.countdownTimer = nil
            failOverTimerCompletedSubject.send()
        }
    }

    private func countdownCompleted() {
        Task {
            guard let nextUpProtocol = await getRefreshedProtocols().first(where: { $0.viewType.isNextup }) else {
                logger.logI("ProtocolManager", "Countdown completed but no nextUp protocol found")
                return
            }

            if !vpnStateRepository.isConnected() {
                logger.logI("ProtocolManager",
                            "Countdown completed - auto selecting: \(nextUpProtocol.protocolPort)")
                onUserSelectProtocol(proto: nextUpProtocol.protocolPort, connectionType: .failover)
            }
        }
    }

    /// Cancels the failover countdown timer when user dismisses the protocol switch screen
    /// This prevents automatic protocol switching after user has dismissed the dialog
    func cancelFailoverTimer() {
        logger.logI("ProtocolManager", "Failover timer cancelled by user - stopping countdown")

        // Reset any nextUp protocols back to normal state
        if let nextUpProtocol = protocolsToConnectList.first(where: { $0.viewType.isNextup }) {
            setPriority(proto: nextUpProtocol.protocolPort.protocolName, type: .normal)
        }

        // Stop the timer
        stopCountdownTimer()
    }
}
