//
//  ProtocolManager.swift
//  Windscribe
//
//  Created by Thomas on 14/10/2022.
//  Copyright © 2022 Windscribe. All rights reserved.
//

import Foundation
import NetworkExtension
import RxSwift
import Swinject

protocol ProtocolManagerType {
    var goodProtocol: ProtocolPort? { get set }
    var resetGoodProtocolTime: Date? { get set }

    var currentProtocolSubject: BehaviorSubject<ProtocolPort?> { get }
    var connectionProtocolSubject: BehaviorSubject<(protocolPort: ProtocolPort, connectionType: ConnectionType)?> { get }

    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async
    func getRefreshedProtocols() async -> [DisplayProtocolPort]
    func getNextProtocol() async -> ProtocolPort
    func getProtocol() -> ProtocolPort
    func onProtocolFail() async -> Bool
    func onUserSelectProtocol(proto: ProtocolPort, connectionType: ConnectionType)
    func resetGoodProtocol()
    func onConnectStateChange(state: NEVPNStatus)
    func scheduleTimer()
    func saveCurrentWifiNetworks()
}

class ProtocolManager: ProtocolManagerType {
    private let logger: FileLogger
    private let disposeBag = DisposeBag()
    private let connectivity: Connectivity
    private let localDatabase: LocalDatabase
    private let securedNetwork: SecuredNetworkRepository
    private let preferences: Preferences
    private let locationManager: LocationsManagerType
    static var shared = Assembler.resolve(ProtocolManagerType.self)
    private lazy var vpnManager: VPNManager = Assembler.resolve(VPNManager.self)

    // MARK: - Properties

    /// Default protocol
    let defaultProtocol = ProtocolPort(wireGuard, DefaultValues.port)
    /// Provides concurrent access to protocol list.
    private let accessQueue = DispatchQueue(label: "protocolManagerAccessQueve", attributes: .concurrent)
    /// List of Protocols in ordered by priority
    private(set) var protocolsToConnectList: [DisplayProtocolPort] = []
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

    var currentProtocolSubject = BehaviorSubject<ProtocolPort?>(value: nil)
    var connectionProtocolSubject = BehaviorSubject<(protocolPort: ProtocolPort, connectionType: ConnectionType)?>(value: nil)

    init(logger: FileLogger, connectivity: Connectivity, preferences: Preferences, securedNetwork: SecuredNetworkRepository, localDatabase: LocalDatabase, locationManager: LocationsManagerType) {
        self.logger = logger
        self.connectivity = connectivity
        self.preferences = preferences
        self.securedNetwork = securedNetwork
        self.localDatabase = localDatabase
        self.locationManager = locationManager
        logger.logI("ProtocolManager", "Starting connection manager.")
        bindData()
        Task {
            await refreshProtocols(shouldReset: true, shouldReconnect: false)
        }
    }

    func bindData() {
        preferences.getConnectionMode().subscribe(onNext: { [weak self] mode in
            self?.connectionMode = mode ?? DefaultValues.connectionMode
        }).disposed(by: disposeBag)

        preferences.getSelectedProtocol().subscribe(onNext: { [weak self] proto in
            self?.manualProtocol = proto ?? DefaultValues.protocol
        }).disposed(by: disposeBag)

        preferences.getSelectedPort().subscribe(onNext: { [weak self] port in
            self?.manualPort = port ?? DefaultValues.port
        }).disposed(by: disposeBag)

        connectivity.network.debounce(.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] network in
            Task { @MainActor in
                await self?.refreshProtocols(shouldReset: false, shouldReconnect: false)
            }
        }).disposed(by: disposeBag)

        securedNetwork.networks.subscribe(onNext: { [weak self] networks in
            guard let self = self else { return }
            guard !networks.isEmpty else {
                self.logger.logD("ProtocolManager", "Networks Empty")
                return
            }
            Task { @MainActor in
                self.logger.logD("ProtocolManager", "Secured Networks : \(networks)")
                await self.refreshProtocols(shouldReset: false, shouldReconnect: false)
            }
        }).disposed(by: disposeBag)
    }

    // MARK: - Actions

    /// reloads the protocols
    /// change their priority based on user settings.
    /// append port
    /// Priority order [Connected, User selected, Preferred, Manual, Good, Failed]
    @MainActor
    func refreshProtocols(shouldReset: Bool, shouldReconnect: Bool) async {
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

        if !shouldReconnect, let info = try? vpnManager.vpnInfo.value(), info.status == .connected {
            appendPort(proto: info.selectedProtocol, port: info.selectedPort)
            setPriority(proto: info.selectedProtocol, type: .connected)
        } else {
            protocolsToConnectList.first?.viewType = .nextUp
        }
        let log = "Protocols to connect List: " + protocolsToConnectList.map { "\($0.protocolPort.protocolName) \($0.protocolPort.portName) \($0.viewType)"}.joined(separator: ", ")
        logger.logI("ProtocolManager", log)

        currentProtocolSubject.onNext(getFirstProtocol())
        connectionProtocolSubject.onNext(shouldReconnect ? (protocolPort: getFirstProtocol(), connectionType: .user) : nil)
    }

    func getRefreshedProtocols() async -> [DisplayProtocolPort] {
        await refreshProtocols(shouldReset: false, shouldReconnect: false)
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
                protocolsToConnectList.first { $0.viewType == .nextUp
                }?.viewType = .connected
                protocolsToConnectList.filter { $0.viewType == .nextUp }.forEach { $0.viewType = .normal }
            }
            if state == .disconnected {
                protocolsToConnectList.filter { $0.viewType == .nextUp }.forEach { $0.viewType = .normal }
                protocolsToConnectList.first { $0.viewType == .connected
                }?.viewType = .normal
            }
        }
    }

    /// User/App selected this protocol to connect.
    func onUserSelectProtocol(proto: ProtocolPort, connectionType: ConnectionType) {
        logger.logI("ProtocolManager", "User selected \(proto) to connect.")
        userSelected = proto
        setPriority(proto: proto.protocolName)
        let firstProtocol = getFirstProtocol()
        currentProtocolSubject.onNext(firstProtocol)
        connectionProtocolSubject.onNext((protocolPort: firstProtocol, connectionType: connectionType))
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
    func onProtocolFail() async -> Bool {
        userSelected = nil
        let failedProtocol = await getNextProtocol()
        logger.logI("ProtocolManager", "\(failedProtocol.protocolName) failed to connect.")
        setPriority(proto: failedProtocol.protocolName, type: .fail)
        if protocolsToConnectList.filter({ $0.viewType != .fail}).count <= 0 {
            logger.logI("ProtocolManager", "No more protocol left to connect.")
            await reset()
            currentProtocolSubject.onNext(getFirstProtocol())
            return true
        } else {
            currentProtocolSubject.onNext(getFirstProtocol())
            return false
        }
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
                if type == .connected || type == .normal || type == .nextUp {
                    copy.insert(item, at: 0)
                } else {
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
